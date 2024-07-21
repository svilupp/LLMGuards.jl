using PromptingTools
const PT = PromptingTools

tpl = PT.create_template(;
    system = """You are un unworldly AI judge trained for NLI (Natural Language Inference) task. 

You mark summary sentences as Entailment (E), Contradiction (C), or Neutral (N) depending on the relationship between the summary sentence and the text passage.
Each summary sentence is marked with E, C, or N based on its relationship to the text.

### Instructions:

1. Task Overview:
    You will be presented with a summary sentence and a longer text passage. Your job is to determine the relationship between the summary sentence and the text passage.

2. Marking Categories:
    - E (Entailment): The summary sentence is definitely true based on the information in the text passage.
    - C (Contradiction): The summary sentence contradicts information in the text passage.
    - N (Neutral): The summary sentence might be true, but the text passage doesn't provide enough information to be certain.

3. Steps:
    a. Read the summary sentence carefully.
    b. Read the text passage thoroughly.
    c. Compare the information in the summary sentence to the text passage.
    d. Determine if the summary is entailed by, contradicts, or is neutral to the text.
    e. Mark the summary with E, C, or N accordingly.

4. Important Considerations:
    - Focus on the facts presented in both the summary and the text.
    - Don't use outside knowledge; base your decision solely on the given information.
    - A summary can be neutral even if it seems likely, as long as the text doesn't explicitly confirm it.
    - Look for specific details that might contradict the summary.

5. Examples:

Example 1:
Text: "The Eiffel Tower, located in Paris, France, was completed in 1889. It stands 324 meters tall and was the world's tallest man-made structure for 41 years."
Summary: "The Eiffel Tower is in Paris." 
Explanation: The text explicitly states that the Eiffel Tower is in Paris, so this is an entailment.
Judgement: E

Example 2:
Text: "Apple Inc. was founded in 1976 by Steve Jobs, Steve Wozniak, and Ronald Wayne. The company's first product was the Apple I personal computer."
Summary: "Apple was founded by Bill Gates."
Explanation: This contradicts the information in the text, which states that Apple was founded by Jobs, Wozniak, and Wayne, not Bill Gates.
Judgement: C

Example 3:
Text: "The Great Barrier Reef is the world's largest coral reef system, stretching for over 2,300 kilometers off the coast of Australia. It is home to diverse marine life, including many species of colorful fish."
Summary: "The Great Barrier Reef has over 1,500 species of fish." 
Explanation: While the text mentions "many species of colorful fish," it doesn't provide a specific number. The summary might be true, but we can't be certain based on the given information.
Judgement: N
        
""",
    user = """
Text: {{text}}
Summary: {{summary}}
Judgement: 
""")

text = """
  Climate change is one of the most pressing issues facing our planet today. It refers to long-term shifts in global weather patterns and average temperatures caused primarily by human activities that increase heat-trapping greenhouse gas levels in Earth's atmosphere. These activities include burning fossil fuels like coal, oil, and natural gas, as well as deforestation and industrial processes.
  The effects of climate change are far-reaching and increasingly severe. Rising global temperatures have led to more frequent and intense heatwaves, droughts, and wildfires in many regions. Melting glaciers and polar ice caps contribute to rising sea levels, threatening coastal communities and low-lying islands. Changes in precipitation patterns affect agriculture, potentially leading to food insecurity in vulnerable areas.
  Biodiversity is also at risk, as many plant and animal species struggle to adapt to rapidly changing habitats. Some experts warn of potential "tipping points" in the climate system, where certain changes could become irreversible, leading to cascading effects throughout the planet's ecosystems.
  Efforts to address climate change focus on two main strategies: mitigation and adaptation. Mitigation involves reducing greenhouse gas emissions through renewable energy adoption, improved energy efficiency, and changes in land use practices. Adaptation strategies aim to build resilience to the impacts of climate change, such as developing drought-resistant crops or improving flood defenses in coastal areas.
  International cooperation is crucial in tackling this global challenge. The Paris Agreement, adopted in 2015, aims to limit global temperature increase to well below 2 degrees Celsius above pre-industrial levels. However, many scientists argue that even more ambitious action is needed to avoid the worst impacts of climate change.
  Individuals can also play a role in combating climate change through lifestyle choices such as reducing energy consumption, using sustainable transportation, and adopting plant-based diets. Education and awareness-raising are vital in mobilizing public support for climate action and encouraging sustainable practices at all levels of society.
  """
summary = """
  Climate change is caused solely by natural variations in the Earth's orbit.
  Rising global temperatures have led to more frequent and intense extreme weather events in many regions.
  The Paris Agreement aims to limit global temperature increase to exactly 1.5 degrees Celsius above pre-industrial levels.
  Adaptation strategies for climate change include developing drought-resistant crops.
  Climate change has no impact on biodiversity or ecosystems.
  """
output = ["C", "E", "N", "E", "C"]
conv = aigenerate(tpl; model = "gpt4om")