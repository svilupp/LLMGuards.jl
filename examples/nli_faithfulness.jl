using PromptingTools
const PT = PromptingTools

tpl = PT.create_template(;
    system = """You are un unworldly AI assistant.
""",
    user = """
      """)

conv = aigenerate(tpl; model = "gpt4om")