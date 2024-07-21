# LLMGuards.jl

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/LLMGuards.jl/dev/) [![Build Status](https://github.com/svilupp/LLMGuards.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/LLMGuards.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/svilupp/LLMGuards.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/LLMGuards.jl) [![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

> [!WARNING]
> This package is in an experimental stage and under development.
>

LLMGuards.jl is a Julia package designed to make it easy to integrate Large Language Models (LLMs) into bigger systems by detecting, evaluating, and guarding against bad data and behaviors.

## Features

- **Data Validation**: Robust checks to ensure input data meets expected formats and quality standards.
- **Behavior Monitoring**: Tools to detect and prevent unexpected or malicious LLM behaviors.
- **Integration Helpers**: Utilities to seamlessly incorporate LLM Guards into existing systems.
- **Customizable Guards**: Flexible framework to define and implement custom guards tailored to specific use cases.

## Installation

To install LLMGuards.jl, use the Julia package manager:

```julia
using Pkg
Pkg.add(url="https://github.com/svilupp/LLMGuards.jl")
```

## Quick Start

Here's a basic example of how to use LLMGuards.jl:

MOCK! Does not work yet

```julia
using LLMGuards

# Example usage (placeholder - update with actual API when available)
input_data = "Your input data here"
guard = DataGuard()
if is_valid(guard, input_data)
    # Process with your LLM
else
    println("Input data failed validation")
end
```

For more detailed examples and usage instructions, please refer to our [documentation](https://svilupp.github.io/LLMGuards.jl/dev/).

## Contributing

Contributions to LLMGuards.jl are welcome! Please refer to the [contribution guidelines](CONTRIBUTING.md) for more information on how to get started.

## License

LLMGuards.jl is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

## Contact

If you have any questions, suggestions, or just want to discuss LLMGuards.jl, please [open an issue](https://github.com/svilupp/LLMGuards.jl/issues/new) on our GitHub repository.