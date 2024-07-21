using LLMGuards
using Test
using Aqua

@testset "LLMGuards.jl" begin
    @testset "Code quality (Aqua.jl)" begin
        Aqua.test_all(LLMGuards)
    end
    # Write your tests here.
end
