
# # Follows the SelfCheckGPT paper
# https://github.com/potsawee/selfcheckgpt
# https://arxiv.org/abs/2303.08896

using PromptingTools
const PT = PromptingTools
using PromptingTools: pprint, create_template
using LLMGuards

# # Simple sentence-by-sentence verification and roll-up
# Generate multiple samples
question = "What is the third largest city in the UK?"
msgs = aigenerate(
    question; model = "gpt-4o-mini", api_kwargs = (; n = 10, temperature = 0.71))

passage = msgs[1].content
samples = [m.content for m in msgs[2:end]]
hypotheses = split_sentence(string.(passage))

tpl = PT.create_template(;
    system = """You are an unworldly AI judge trained for truthfulness verification. 
""",
    user = """Context: {{context}}\n\nStatement: The context above supports the following claim: {{claim}}

Answer true, false, or unknown if there is no claim or you cannot determine it.
You cannot use any external knowledge, only the provided context.

Answer:""")

msg = aigenerate(
    tpl; context = passage, claim = hypotheses[1], model = "gpt4om",
    return_all = true, api_kwargs = (;
        max_tokens = 1))
pprint(msg)

## Check all hypotheses
results = let results = [], verbose = false
    cost_tracker = Threads.Atomic{Float64}(0.0)
    token_tracker = Threads.Atomic{Int}(0)
    for i in eachindex(hypotheses)
        hypo_results = asyncmap(samples) do sample
            msg = aigenerate(tpl; context = sample, claim = hypotheses[i],
                model = "gpt4om", api_kwargs = (; max_tokens = 1), verbose = false)
            Threads.atomic_add!(cost_tracker, msg.cost)
            Threads.atomic_add!(token_tracker, sum(msg.tokens))
            output = PT.last_output(msg) |> lowercase |> strip
        end
        push!(results, hypo_results)
    end
    verbose &&
        @info "Verification finished (tokens: $(token_tracker[]), cost: \$$(cost_tracker[]))"
    results
end

# # Unigram validation

function remove_trailing_punctuation(word)
    ## remove trailing punctuation
    word = replace(word, r"[\.,!?]+\s*$" => "")
    return word
end
function preprocess_word(word)
    remove_trailing_punctuation(word) |> strip
end
# Function to create a unigram model
function create_unigram_model(texts)
    word_counts = Dict{String, Int}()
    total_words = 0

    for text in texts
        words = split(lowercase(text))
        for word_raw in words
            word = preprocess_word(word_raw)
            isempty(word) && continue
            word_counts[word] = get(word_counts, word, 0) + 1
            total_words += 1
        end
    end

    # Convert counts to probabilities
    unigram_model = Dict(word => count / total_words for (word, count) in word_counts)

    return unigram_model
end

# Create unigram model from samples
unigram_model = create_unigram_model(samples)

# Function to calculate probability of a sentence using the unigram model
function sentence_logprob(sentence, model)
    words = split(lowercase(sentence))
    log_prob = 0.0
    count = 0
    for word_raw in words
        word = preprocess_word(word_raw)
        isempty(word) && continue
        count += 1
        log_prob += get(model, word, 1e-10)  # Use a small probability for unknown words
    end
    return iszero(count) ? log_prob : log_prob / count
end

# Calculate probabilities for each hypothesis
hypothesis_logprobs = [sentence_logprob(hyp, unigram_model) for hyp in hypotheses]

# Normalize probabilities
total_logprob = sum(hypothesis_logprobs)
normalized_logprobs = hypothesis_logprobs ./ total_logprob # not necessary

# Print results
for (i, (hyp, logprob)) in enumerate(zip(hypotheses, hypothesis_logprobs))
    println("Hypothesis $i: $hyp")
    println("Log probs: $logprob")
    println()
end

## TODO: add Max negative log prob check