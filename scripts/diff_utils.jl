# Define an enum for marking lines
@enum LineChangeType ADD REMOVE UNCHANGED

"""
    files_to_prompt(files::AbstractVector{<:AbstractString};
        start_tag = "<user_files>", end_tag = "</user_files>")

Packs the files into a prompt inside the `<user_files>` tags. Returns a String.
"""
function files_to_prompt(files::AbstractVector{<:AbstractString};
        start_tag = "<user_files>", end_tag = "</user_files>")
    @assert all(isfile, files) "All files must exist. Files not found: $(join([f for f in files if !isfile(f)], ", "))"
    ##
    io = IOBuffer()
    println(io, start_tag)
    for fn in files
        content = read(fn, String)
        println(io, """
        <file name=$fn>
        $content
        </file>""")
    end
    println(io, end_tag)
    return String(take!(io))
end
function files_to_prompt(::Nothing; kwargs...)
    return ""
end

"""
    extract_files_info(s::AbstractString)

Extracts the file names and content from the provided string in the `<file name=...></file>` tags.

Returns: A vector of tuples (`(file_name, content_lines)`), where `file_name` is the name of the file and `content_lines` is a vector of strings, each representing a line in the file.
"""
function extract_files_info(s::AbstractString)
    files_extracted = []

    # Regex to match all file blocks
    file_blocks = eachmatch(r"<file name=([^>]+)>(.*?)</file>"ms, s)
    for file_block in file_blocks
        file_name = file_block.captures[1]
        content = file_block.captures[2]
        content_lines = filter(!isempty, split(content, '\n'))
        push!(files_extracted, (file_name, content_lines))
    end

    return files_extracted
end

# Example usage
s = """
<file name=README.md>
- # LLMGuards [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/LLMGuards.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/LLMGuards.jl/dev/) [![Build Status](https://github.com/svilupp/LLMGuards.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/LLMGuards.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/svilupp/LLMGuards.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/LLMGuards.jl) [![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
+ # LLMGuards.jl
</file>
<file name=Project.toml>
name = "LLMGuards"
uuid = "a3ab6dde-8459-47fb-86fc-4adc6e671050"
authors = ["J S <49557684+svilupp@users.noreply.github.com> and contributors"]
- version = "0.0.1-DEV"
+ version = "0.1.0"
</file>
"""
file_infos = extract_files_info(s)
# for (file_name, content_lines) in file_infos
#     println("File Name: ", file_name)
#     println("Content Lines: ", content_lines)
# end

"""
    detect_line_changes(lines::AbstractVector{<:AbstractString})

Detects the changes in the provided lines. 

Returns a vector of tuples, where each tuple contains a line and its change type.
"""
function detect_line_changes(lines::AbstractVector{<:AbstractString})
    marked_lines = []

    for line in lines
        if startswith(line, "+ ")
            line = replace(line, r"^\+ " => "")
            push!(marked_lines, (line, ADD))
        elseif strip(line) == "+"
            push!(marked_lines, ("", ADD))
        elseif strip(line) == "-"
            push!(marked_lines, ("", REMOVE))
        elseif startswith(line, "- ")
            line = replace(line, r"^\- " => "")
            push!(marked_lines, (line, REMOVE))
        else
            push!(marked_lines, (line, UNCHANGED))
        end
    end

    return marked_lines
end

# Example usage
lines = [
    "+ Added line",
    "+",
    "- Removed line",
    " Unchanged line"
]

marked_lines = detect_line_changes(lines)
# for (line, change_type) in marked_lines
#     println("Line: ", line, " Change Type: ", change_type)
# end

"""
    apply_line_changes(changes::AbstractVector)

Applies the changes to the provided lines as marked by the change type.

Returns a new vector of lines with the changes applied.
"""
function apply_line_changes(changes::AbstractVector)
    new_lines = []

    for (line, change_type) in changes
        if change_type == ADD || change_type == UNCHANGED
            push!(new_lines, line)
        elseif change_type == REMOVE
            continue  # Skip the line
        end
    end

    return new_lines
end

# Example usage
lines = [
    "+ Added line",
    "- Removed line",
    " Unchanged line"
]

marked_lines = detect_line_changes(lines)
new_lines = apply_line_changes(marked_lines)
# println("New Lines: ", new_lines)

;
