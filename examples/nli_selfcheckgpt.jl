
# # Follows the SelfCheckGPT paper
# https://github.com/potsawee/selfcheckgpt
# https://arxiv.org/abs/2303.08896

using PromptingTools
const PT = PromptingTools
using PromptingTools: pprint, create_template
using LLMGuards
using Statistics: mean

# # Simple sentence-by-sentence verification and roll-up
# Generate multiple samples
question = "What are good packages for tabular data in Julia language?"
question = "What’s the diameter of planet earth in feet?"
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

scores = let scores = []
    for line in results
        scorer = Dict()
        for sample in line
            key = sample .== "true" ? Judgement(0) :
                  sample .== "false" ? Judgement(2) : Judgement(1)
            scorer[key] = get(scorer, key, 0) + 1
        end
        push!(scores, scorer)
    end
    scores
end

# # Unigram validation

@kwdef struct UnigramConsistency2
    samples::Vector{<:AbstractString}
    passage::AbstractString
    hypotheses::Vector{<:AbstractString}
    unigram_model::Dict{<:AbstractString, Float64}
    average_proba::Float64
end
function Base.show(io::IO, sent::UnigramConsistency2)
    dump(io, sent; maxdepth = 1)
end

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
    # Reference values
    average_proba = iszero(total_words) ? 0.0 : 1 / total_words

    return unigram_model, average_proba
end

# Create unigram model from samples
## Can include the original text and consider it as "smoothing"
unigram_model, avg_proba = create_unigram_model(samples)
avg_proba
unique_proba = 1 / length(unigram_model)

# Function to calculate probability of a sentence using the unigram model
function sentence_logprob(sentence, model)
    words = split(lowercase(sentence))
    log_prob_sum = 0.0
    log_prob_max = -Inf
    count = 0
    for word_raw in words
        word = preprocess_word(word_raw)
        isempty(word) && continue
        count += 1
        neglogp = -log(get(model, word, 1e-10))
        log_prob_sum += neglogp
        log_prob_max = if neglogp > log_prob_max
            neglogp
        else
            log_prob_max
        end
    end
    if count > 0
        log_prob_sum = log_prob_sum / count
    end
    return log_prob_sum, log_prob_max
end

# Calculate probabilities for each hypothesis
hypothesis_logprobs = [sentence_logprob(hyp, unigram_model) for hyp in hypotheses]

# Print results
let
    for (i, (hyp, logprob)) in enumerate(zip(hypotheses, hypothesis_logprobs))
        println("Hypothesis $i: $hyp")
        println("Log probs: AVG $(logprob[1]), MAX $(logprob[2])")
        println()
    end
    println("Passage level: AVG $(mean([logprob[1] for logprob in hypothesis_logprobs])), MAX $(mean([logprob[2] for logprob in hypothesis_logprobs]))")
end

## Unigram for words
unigram_model
unig = UnigramConsistency2(samples, passage, hypotheses, unigram_model, avg_proba)

function LLMGuards.highlight(io::IO, unig::UnigramConsistency2; unit = :sentence,
        proba_red = nothing, kwargs...)
    @assert unit in [:sentence, :word] "Unit must be :sentence or :word"
    (; passage, hypotheses, unigram_model, average_proba) = unig
    unique_token_nlproba = -log(1 / length(unigram_model))
    hypothesis_logprobs = [sentence_logprob(hyp, unigram_model) for hyp in hypotheses]
    ## convert to NLL
    if isnothing(proba_red)
        proba_red = unique_token_nlproba
    else
        proba_red = -log(proba_red)
    end
    ## yellow is 2x more likely than red
    proba_yellow = proba_red - log(2)
    current_idx = 1
    for (i, (sent, logprob)) in enumerate(zip(hypotheses, hypothesis_logprobs))

        # Find the start of the current sentence in the passage
        start_idx = findnext(sent, passage, current_idx)

        if !isnothing(start_idx)
            # Print any text between the last sentence and this one
            if start_idx.start > current_idx
                end_idx = prevind(passage, start_idx.start, 1)
                print(io, passage[current_idx:end_idx])
            end

            # Print the sentence
            if unit == :sentence
                color = if logprob[1] < proba_yellow
                    :normal
                elseif logprob[1] < proba_red
                    :yellow
                else
                    :red
                end
                printstyled(io, sent, color = color)
            elseif unit == :word
                words = split(sent)
                for word_raw in words
                    word = preprocess_word(lowercase(word_raw))
                    logprob_word = -log(get(unigram_model, word, 1e-10))
                    if logprob_word < proba_yellow
                        printstyled(io, word_raw, color = :normal)
                    elseif logprob_word < proba_red
                        printstyled(io, word_raw, color = :yellow)
                    else
                        printstyled(io, word_raw, color = :red)
                    end
                    print(io, " ")
                end
            end

            # Update the passage index
            current_idx = nextind(passage, start_idx.stop, 1)
        else
            # If the sentence is not found, just print it
            print(io, sent)
        end
    end

    # Print any remaining text in the passage
    if current_idx <= length(passage)
        print(io, passage[current_idx:end])
    end
    println(io)
    return nothing
end

highlight(stdout, unig; unit = :sentence, proba_red = 0.03)
highlight(stdout, unig; unit = :word, proba_red = 0.02)

# add embeddings distances
# Embedding consistency check - sentence levels at one shot