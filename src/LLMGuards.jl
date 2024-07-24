module LLMGuards

using Sentencize

# re-export
export split_sentence

export split_into_code_and_sentences
include("utils.jl")

include("types.jl")

include("nli.jl")

function __init__()
    ## Auto template loading
    PT.load_templates!(joinpath(@__DIR__, "..", "templates"))
end

end # end of module
