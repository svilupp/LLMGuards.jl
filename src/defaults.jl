# Defines default behavior and overloads for foreign types
function analyze(rag_result::RT.RAGResult; kwargs...)
    analyze(PassageNLI, rag_result.final_answer, rag_result.context; kwargs...)
end
function report(io::IO, nli::PassageNLI)
    return faithfulness_report(nli; io = io)
end