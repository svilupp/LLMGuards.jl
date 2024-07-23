"""
    split_into_code_and_sentences(input::Union{String, SubString{String}})

Splits text block into code or text and sub-splits into units.

If code block, it splits by newline but keep the `group_id` the same (to have the same source)
If text block, splits into sentences, bullets, etc., provides different `group_id` (to have different source)
"""
function split_into_code_and_sentences(input::Union{String, SubString{String}})
    # Combining the patterns for code blocks, inline code, and sentences in one regex
    # This pattern aims to match code blocks first, then inline code, and finally any text outside of code blocks as sentences or parts thereof.
    pattern = r"(```[\s\S]+?```)|(`[^`]*?`)|([^`]+)"

    ## Patterns for sentences: newline, tab, bullet, enumerate list, sentence, any left out characters
    sentence_pattern = r"(\n|\t|^\s*[*+-]\s*|^\s*\d+\.\s+|[^\n\t\.!?]+[\.!?]*|[*+\-\.!?])"ms

    # Initialize an empty array to store the split sentences
    sentences = SubString{String}[]
    # group_ids = Int[]

    # Loop over the input string, searching for matches to the pattern
    i = 1
    for m in eachmatch(pattern, input)
        ## number of sub-parts
        j = 1
        # Extract the full match, including any delimiters
        match_block = m.match
        # Check if the match is a code block with triple backticks
        if startswith(match_block, "```")
            # Split code block by newline, retaining the backticks
            push!(sentences, match_block)
            # block_lines = split(match_block, "\n", keepempty = false)
            # for (cnt, block) in enumerate(block_lines)
            #     push!(sentences, block)
            #     # all the lines of the code block are the same group to have one source annotation
            #     push!(group_ids, i)
            #     if cnt < length(block_lines)
            #         ## return newlines
            #         push!(sentences, "\n")
            #         push!(group_ids, i)
            #     end
            # end
        elseif startswith(match_block, "`")
            push!(sentences, match_block)
            # push!(group_ids, i)
        else
            ## Split text further
            j = 0
            for m_sent in eachmatch(sentence_pattern, match_block)
                push!(sentences, m_sent.match)
                # push!(group_ids, i + j) # all sentences to have separate group
                j += 1
            end
        end
        ## increment counter
        i += j
    end

    return sentences
end
#negatives, do not split on digits (1.5)