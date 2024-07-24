### Supporting Types
@enum Judgement E N C

## For reporting
@kwdef struct SentenceNLI
    sentence::AbstractString
    explanation::Union{AbstractString, Nothing} = nothing
    nli::Judgement
    references::Vector{AbstractString} = AbstractString[]
    source_idx::Union{Int, Nothing} = nothing
end
function show(io::IO, sent::SentenceNLI)
    dump(io, sent; maxdepth = 1)
end

"""
    PassageNLI

A struct to store the results of NLI analysis for a given `passage` against a set of grounding facts (`sources`).

# Fields
- `sources::Vector{AbstractString}`: The sources used for the analysis of a `passage`
- `passage::AbstractString`: The passage to be analyzed (eg, an "answer" to some question)
- `sentences::Vector{SentenceNLI}`: The results of the NLI analysis for each sentence in the passage.
"""
@kwdef struct PassageNLI
    sources::Vector{AbstractString}
    passage::AbstractString
    sentences::Vector{SentenceNLI}
end
function show(io::IO, passage::PassageNLI)
    dump(io, passage; maxdepth = 1)
end

## For extraction task
@kwdef struct JudgementNLI
    explanation::String
    judgement::Judgement
end
function show(io::IO, judg::JudgementNLI)
    dump(io, judg; maxdepth = 1)
end

### Actions
"""
    analyze(::Type{PassageNLI}, answer::AbstractString,
        sources::AbstractVector{<:AbstractString}; model::AbstractString = "gpt4om", verbose::Integer = 1)
        sources::AbstractVector{<:AbstractString}; model::AbstractString = "gpt4om")

Runs NLI analysis for a given `answer` against a set of `sources`.

Returns a `PassageNLI` object.
"""
function analyze(::Type{PassageNLI}, answer::AbstractString,
        sources::AbstractVector{<:AbstractString}; model::AbstractString = "gpt4om", verbose::Integer = 1)
    premise = join(sources, "\n---\n")
    hypotheses = split_sentence(answer) |> x -> filter(!isempty, x)
    cost_tracker = Threads.Atomic{Float64}(0.0)
    judgements = asyncmap(hypotheses) do hypothesis
        msg = aiextract(:NLIHypothesisExtractLabel4Shot; premise, hypothesis,
            model, return_type = JudgementNLI, verbose = (verbose - 1) > 0)
        Threads.atomic_add!(cost_tracker, msg.cost)
        PT.last_output(msg)
    end
    sentences = SentenceNLI[]
    for i in eachindex(hypotheses, judgements)
        ## Prepare safer parsing
        (; explanation, judgement) = judgements[i]
        references = extract_quotes(explanation)
        val, source_idx = detect_quote_source(references, sources)
        push!(sentences,
            SentenceNLI(hypotheses[i], explanation, judgement, references, source_idx))
    end

    passage_nli = PassageNLI(sources, answer, sentences)
    (verbose >= 1) &&
        @info "NLI analysis complete (cost: \$$(round(cost_tracker[]; digits = 2)))"

    return passage_nli
end

###
function faithfulness_report(io::IO, passage::PassageNLI; detailed::Bool = false)
    (; sources, sentences) = passage
    labels = Dict(E => Int[], N => Int[], C => Int[])
    for (i, sent) in enumerate(sentences)
        (; sentence, explanation, nli, references, source_idx) = sent
        push!(labels[nli], i)
        detailed && print(io, "Hypothesis $i: $(sentence)", "\n", "- Judgement: ",
            nli, "\n", "- Explanation: ", explanation, "\n\n")
    end
    len = length(sentences)
    nli_score = (length(labels[E]) - length(labels[C])) / len
    entailment = length(labels[E]) / len
    print(io, "NLI Score: $(round(nli_score*100, digits = 0)) pts with ",
        "$(round(entailment*100, digits = 0))% entailment", "\n",
        "- Contradicted hypotheses: $(join(labels[C], ", "))", "\n",
        "- Neutral hypotheses: $(join(labels[N], ", "))", "\n")
    return nothing
end
function faithfulness_report(passage::PassageNLI; kwargs...)
    return faithfulness_report(stdout, passage; kwargs...)
end