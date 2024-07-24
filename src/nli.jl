### Supporting Types
@enum Judgement E N C

## For reporting
@kwdef struct SentenceNLI
    sentence::AbstractString
    explanation::Union{AbstractString, Nothing} = nothing
    nli::Judgement
    reference::Union{AbstractString, Nothing} = nothing
    source_idx::Union{Int, Nothing} = nothing
end
function show(io::IO, sent::SentenceNLI)
    dump(io, sent; maxdepth = 1)
end
@kwdef struct PassageNLI
    sources::Vector{AbstractString}
    passage::AbstractString
    sentences::Vector{SentenceNLI}
end

## For extraction task
@kwdef struct JudgementNLI
    explanation::String
    judgement::Judgement
end
function show(io::IO, judg::JudgementNLI)
    dump(io, judg; maxdepth = 1)
end

### Conversions

###
function faithfulness_report(io::IO, passage::PassageNLI; detailed::Bool = false)
    (; sources, sentences) = passage
    labels = Dict(E => Int[], N => Int[], C => Int[])
    for (i, sent) in enumerate(sentences)
        (; sentence, explanation, nli, reference, source_idx) = sent
        push!(labels[nli], i)
        detailed && print(io, "Hypothesis $i: $(sentence)", "\n", "- Judgement: ",
            nli, "\n", "- Explanation: ", explanation, "\n\n")
    end
    len = length(sentences)
    nli_score = (length(labels[E]) - length(labels[C])) / len
    entailment = length(labels[E]) / len
    print(io, "NLI Score: $(round(nli_score*100, digits = 0))pts with ",
        "$(round(entailment*100, digits = 0))% entailment", "\n",
        "- Contradicted hypotheses: $(join(labels[C], ", "))", "\n",
        "- Neutral hypotheses: $(join(labels[N], ", "))", "\n")
    return nothing
end
function faithfulness_report(passage::PassageNLI)
    faithfulness_report(stdout, passage)
end