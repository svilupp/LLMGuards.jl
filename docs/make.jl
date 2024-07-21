using LLMGuards
using Documenter

DocMeta.setdocmeta!(LLMGuards, :DocTestSetup, :(using LLMGuards); recursive=true)

makedocs(;
    modules=[LLMGuards],
    authors="J S <49557684+svilupp@users.noreply.github.com> and contributors",
    sitename="LLMGuards.jl",
    format=Documenter.HTML(;
        canonical="https://svilupp.github.io/LLMGuards.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/svilupp/LLMGuards.jl",
    devbranch="main",
)
