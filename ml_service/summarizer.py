"""Notes summariser.

Fix vs. the old RAG version: summarising needs the WHOLE note, not the top-4
chunks a retriever returns for a fixed query. Short notes go to the LLM in one
call; long notes use map-reduce (summarise each chunk, then merge).
"""
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_text_splitters import RecursiveCharacterTextSplitter

from llm import get_llm

STYLES = {
    "short": "Write a concise summary of at most 5 sentences.",
    "bullets": "Write a bullet-point summary of the key ideas, main points and important details.",
    "detailed": "Write a detailed, well-structured summary with short headings and bullet points.",
}

MAP_PROMPT = ChatPromptTemplate.from_template(
    "Summarize this part of a student's notes. Keep every key fact, term and definition.\n\n"
    "Notes:\n{text}\n\nSummary:"
)

FINAL_PROMPT = ChatPromptTemplate.from_template(
    "You are a precise notes summarizer for students. Use ONLY the notes below; do not add outside facts.\n"
    "{style}\n\nNotes:\n{text}\n\nSummary:"
)

_splitter = RecursiveCharacterTextSplitter(chunk_size=6000, chunk_overlap=300)


def summarize_notes(text: str, style: str = "bullets") -> str:
    text = text.strip()
    if not text:
        raise ValueError("Note is empty.")
    style_instruction = STYLES.get(style, STYLES["bullets"])
    llm = get_llm(temperature=0.2)
    parser = StrOutputParser()

    chunks = _splitter.split_text(text)
    if len(chunks) > 1:
        map_chain = MAP_PROMPT | llm | parser
        partials = map_chain.batch([{"text": c} for c in chunks])
        text = "\n\n".join(partials)

    final_chain = FINAL_PROMPT | llm | parser
    return final_chain.invoke({"text": text, "style": style_instruction})
