using PromptingTools
const PT = PromptingTools
using LLMGuards

# # Method 1: Structured Extraction
tpl = PT.create_template(;
    system = """You are un unworldly AI judge trained for NLI (Natural Language Inference) task. 

You mark summary sentences as Entailment (E), Contradiction (C), or Neutral (N) depending on the relationship between the premise and hypothesis.
Each summary sentence is marked with E, C, or N based on its relationship to the text.

### Instructions

1. Task Overview:
    You will be presented with a longer text passage (premise) and a summary sentence (hypothesis). Your job is to determine the relationship between the premise and hypothesis.

2. Marking Categories:
    - E (Entailment): The summary sentence is definitely true based on the information in the text passage.
    - C (Contradiction): The summary sentence contradicts information in the text passage.
    - N (Neutral): The summary sentence might be true, but the text passage doesn't provide enough information to be certain.

3. Steps:
    a. Read the hypothesis carefully.
    b. Read the premise thoroughly.
    c. Compare the information in the hypothesis to the premise.
    d. Identify the most important detail, fact, or statement in the premise that supports or contradicts the hypothesis.
    e. Explain if the hypothesis is entailed by, contradicts, or is neutral to the premise. Use quotes from the premise to support your explanation.
    f. Mark the hypothesis with E, C, or N accordingly.

4. Important Considerations:
    - Focus on the facts presented in both the hypothesis and the premise.
    - Don't use outside knowledge; base your decision solely on the given information.
    - A hypothesis can be neutral even if it seems likely, as long as the premise doesn't explicitly confirm it.
    - If the hypothesis is a specific instance or subset within the range, category, or statement provided by the premise, then the relationship is neutral, because we cannot confirm what the specific instance or subset is in the premise.
    - If we have insufficient details to contradict the hypothesis, then the relationship is neutral or entailment (eg, "exactly 10" is neutral to "less than 20").
    - Look for specific details that might contradict the hypothesis and that are explicitly stated in the premise.

5. Examples:

Example 1:
Premise: "The Eiffel Tower, located in Paris, France, was completed in 1889. It stands 324 meters tall and was the world's tallest man-made structure for 41 years."
Hypothesis: "The Eiffel Tower is in Paris." 
Explanation: The premise explicitly states that the Eiffel Tower is in Paris, so this is an entailment.
Judgement: E

Example 2:
Premise: "Apple Inc. was founded in 1976 by Steve Jobs, Steve Wozniak, and Ronald Wayne. The company's first product was the Apple I personal computer."
Hypothesis: "Apple was founded by Bill Gates."
Explanation: The hypothesis contradicts the information in the premise, which states that Apple was founded by Jobs, Wozniak, and Wayne, not Bill Gates.
Judgement: C

Example 3:
Premise: "The Great Barrier Reef is the world's largest coral reef system, stretching for over 2,300 kilometers off the coast of Australia. It is home to diverse marine life, including many species of colorful fish."
Hypothesis: "The Great Barrier Reef has over 1,500 species of fish." 
Explanation: The premise mentions many species of fish, but it doesn't provide a specific number. The hypothesis might be true, but we can't be certain based on the given information.
Judgement: N

Example 4:
Premise: "The Great Barrier Reef is the world's largest coral reef system, stretching for over 2,300 kilometers off the coast of Australia. It is home to diverse marine life, including many species of colorful fish."
Hypothesis: "The Great Barrier Reef measures exactly 2,731 kilometers." 
Explanation: While the premise mentions length over 2,300 kilometers, it doesn't provide a specific number to validate the hypothesis. The hypothesis might be true, but we can't be certain based on the given information.
Judgement: N
        
Return the explanation and judgement in JSON format.
""",
    user = """
Premise: \"{{text}}\"
Hypothesis: \"{{summary}}\"
Explanation:
""")

@enum Judgement E N C
@kwdef struct JudgementNLI
    explanation::String
    judgement::Judgement
end

text = """
  Climate change is one of the most pressing issues facing our planet today. It refers to long-term shifts in global weather patterns and average temperatures caused primarily by human activities that increase heat-trapping greenhouse gas levels in Earth's atmosphere. These activities include burning fossil fuels like coal, oil, and natural gas, as well as deforestation and industrial processes.
  The effects of climate change are far-reaching and increasingly severe. Rising global temperatures have led to more frequent and intense heatwaves, droughts, and wildfires in many regions. Melting glaciers and polar ice caps contribute to rising sea levels, threatening coastal communities and low-lying islands. Changes in precipitation patterns affect agriculture, potentially leading to food insecurity in vulnerable areas.
  Biodiversity is also at risk, as many plant and animal species struggle to adapt to rapidly changing habitats. Some experts warn of potential "tipping points" in the climate system, where certain changes could become irreversible, leading to cascading effects throughout the planet's ecosystems.
  Efforts to address climate change focus on two main strategies: mitigation and adaptation. Mitigation involves reducing greenhouse gas emissions through renewable energy adoption, improved energy efficiency, and changes in land use practices. Adaptation strategies aim to build resilience to the impacts of climate change, such as developing drought-resistant crops or improving flood defenses in coastal areas.
  International cooperation is crucial in tackling this global challenge. The Paris Agreement, adopted in 2015, aims to limit global temperature increase to well below 2 degrees Celsius above pre-industrial levels. However, many scientists argue that even more ambitious action is needed to avoid the worst impacts of climate change.
  Individuals can also play a role in combating climate change through lifestyle choices such as reducing energy consumption, using sustainable transportation, and adopting plant-based diets. Education and awareness-raising are vital in mobilizing public support for climate action and encouraging sustainable practices at all levels of society.
  """
summary_text = """
  Climate change is caused solely by natural variations in the Earth's orbit.
  Rising global temperatures have led to more frequent and intense extreme weather events in many regions.
  The Paris Agreement aims to limit global temperature increase to exactly 1.5 degrees Celsius above pre-industrial levels.
  Adaptation strategies for climate change include developing drought-resistant crops.
  Climate change has no impact on biodiversity or ecosystems.
  """
hypotheses = split_sentence(summary_text)
labels = ["C", "E", "N", "E", "C"]

msg = aigenerate(tpl; text, summary = hypotheses[3], model = "gpt4om")
msg = aiextract(
    tpl; text, summary = hypotheses[3], model = "gpt4om", return_type = JudgementNLI)
PT.last_output(msg)

results = asyncmap(hypotheses) do h
    msg = aiextract(tpl; text, summary = h, model = "gpt4om", return_type = JudgementNLI)
    PT.last_output(msg)
end

# # Method 2: Simple yes/no
# https://aclanthology.org/2023.findings-eacl.162.pdf

tpl1 = PT.create_template(;
    system = """You are an unworldly AI judge trained for NLI (Natural Language Inference) task. 
Your task is determine if the summary sentence is entailed by (E), contradicts (C), or is neutral (N) to the text passage.

### Format
Input: {text} implies {summary}
Output: {Yes or No} it is {label} because {explanation}
""",
    user = """
Input: {{text}} implies {{summary}}
Output:
""")

tpl2 = PT.create_template(;
    system = """You are an unworldly AI judge trained for NLI (Natural Language Inference) task. 

Your task is determine if the summary sentence is entailed by (E), contradicts (C), or is neutral (N) to the text passage.
Each summary sentence is marked with E, C, or N based on its relationship to the text.

### Instructions

- You will be presented with a summary sentence and a longer text passage. Your job is to determine the relationship between the summary sentence and the text passage.
- Mark the summary sentence with E, C, or N based on its relationship to the text passage.
- Focus on the facts presented in both the summary and the text.
- Don't use outside knowledge; base your decision solely on the given information.
- A summary can be neutral even if it seems likely, as long as the text doesn't explicitly confirm it.
- Look for specific details that might contradict the summary.

### Marking Categories:

- E (Entailment): The summary sentence is definitely true based on the information in the text passage.
- C (Contradiction): The summary sentence contradicts information in the text passage.
- N (Neutral): The summary sentence might be true, but the text passage doesn't provide enough information to be certain.

### Output Format

Input: {text} implies {summary}
Reasoning: {explanation}
Output: {Yes or No} it is {label}
""",
    user = """
Input: {{text}} implies {{summary}}
Reasoning:
""")

msg = aigenerate(tpl1; text, summary = hypotheses[3], model = "gpt4om")
# Tokens: 533 @ Cost: $0.0001 in 0.9 seconds
msg = aigenerate(tpl2; text, summary = hypotheses[3], model = "gpt4om")
# Tokens: 794 @ Cost: $0.0002 in 1.8 seconds

# # Method3: SelfCheckGPT prompt, but not the sampling method
# https://github.com/potsawee/selfcheckgpt
# https://arxiv.org/abs/2303.08896

tpl = PT.create_template(;
    system = """You are an unworldly AI judge trained for NLI (Natural Language Inference) task. 
""",
    user = "Context: {{context}}\n\nSummary: {{summary}}\n\nIs the sentence supported by the context above? Answer Yes or No.\n\nAnswer:")

msg = aigenerate(tpl; context = text, summary = hypotheses[3], model = "gpt4om")

results = asyncmap(hypotheses) do h
    msg = aigenerate(tpl; context = text, summary = h, model = "gpt4om")
    PT.last_output(msg)
end

# # Method4: Classification

tpl = PT.create_template(;
    system = """You are an unworldly AI judge trained for NLI (Natural Language Inference) task. 

Your task is determine if the summary sentence is entailed by (E), contradicts (C), or is neutral (N) to the text passage.
Each summary sentence is marked with E, C, or N based on its relationship to the text.

Your task is to select the most appropriate label from the given choices for the given text and summary.

**Available Choices:**
---
{{choices}}
---

**Instructions:**
- You must respond in one word. 
- You must respond only with the label ID (e.g., "1", "2", ...) that best fits the input.
""",
    user = """Text: {{text}}\n\nSummary: {{summary}}\n\nNLI Label:""")

choices = [
    ("E",
        "The summary sentence is definitely true based on the information in the text passage."),
    ("C",
        "The summary sentence contradicts information in the text passage."),
    ("N",
        "The summary sentence might be true, but the text passage doesn't provide enough information to be certain.")]
aiclassify(tpl;
    choices, text = text, summary = hypotheses[3], model = "gpt4om")

results = asyncmap(hypotheses) do h
    msg = aiclassify(tpl; choices, text, summary = h, model = "gpt4om")
    PT.last_output(msg)
end
