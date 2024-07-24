module LLMGuards

using PromptingTools
const PT = PromptingTools
using PromptingTools.Experimental.RAGTools
const RT = RAGTools
using Sentencize
using Statistics: mean

# re-export
export split_sentence

export split_into_code_and_sentences
include("utils.jl")

include("types.jl")

export PassageNLI, SentenceNLI, JudgementNLI, Judgement
export analyze, faithfulness_report
include("nli.jl")

export report
include("defaults.jl")

function __init__()
    ## Auto template loading
    PT.load_templates!(joinpath(@__DIR__, "..", "templates"))
end

end # end of module
