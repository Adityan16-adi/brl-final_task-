"""Quiz generator: returns validated JSON the frontend can render directly.

Fix vs. the old version: the old prompt returned free text, which a frontend
can't reliably parse. Here the model must return JSON matching the Quiz
schema, and we validate it (4 options, valid answer index) with a retry.
"""
from langchain_core.output_parsers import JsonOutputParser
from langchain_core.prompts import ChatPromptTemplate
from langchain_text_splitters import RecursiveCharacterTextSplitter
from pydantic import BaseModel, Field, field_validator

from llm import get_llm


class Question(BaseModel):
    question: str
    options: list[str] = Field(description="exactly 4 answer options")
    answer_index: int = Field(description="0-based index of the correct option")
    explanation: str = Field(description="one sentence on why the answer is correct")

    @field_validator("options")
    @classmethod
    def four_options(cls, v):
        if len(v) != 4:
            raise ValueError("each question needs exactly 4 options")
        return v

    @field_validator("answer_index")
    @classmethod
    def valid_index(cls, v):
        if not 0 <= v <= 3:
            raise ValueError("answer_index must be 0-3")
        return v


class Quiz(BaseModel):
    questions: list[Question]


_parser = JsonOutputParser(pydantic_object=Quiz)

_prompt = ChatPromptTemplate.from_template(
    "You are a teacher writing a multiple-choice quiz from the notes below.\n"
    "Create exactly {n} questions at {difficulty} difficulty. Base every question ONLY on the notes.\n"
    "Each question has exactly 4 options, one correct. Vary the position of the correct answer.\n"
    "Return ONLY valid JSON, no markdown fences.\n\n{format_instructions}\n\nNotes:\n{text}"
).partial(format_instructions=_parser.get_format_instructions())

_splitter = RecursiveCharacterTextSplitter(chunk_size=6000, chunk_overlap=0)
MAX_CHUNKS = 3  # keeps free-tier token usage in check


def _sample(text: str) -> str:
    """For long notes, take evenly spaced chunks so the quiz covers the whole note."""
    chunks = _splitter.split_text(text)
    if len(chunks) <= MAX_CHUNKS:
        return "\n\n".join(chunks)
    step = len(chunks) / MAX_CHUNKS
    return "\n\n".join(chunks[int(i * step)] for i in range(MAX_CHUNKS))


def generate_quiz(text: str, num_questions: int = 5, difficulty: str = "medium", retries: int = 2) -> dict:
    text = text.strip()
    if not text:
        raise ValueError("Note is empty.")
    chain = _prompt | get_llm(temperature=0.4) | _parser
    payload = {"n": num_questions, "difficulty": difficulty, "text": _sample(text)}

    last_err = None
    for _ in range(retries + 1):
        try:
            data = chain.invoke(payload)
            return Quiz.model_validate(data).model_dump()
        except Exception as e:  # bad JSON / failed validation -> retry
            last_err = e
    raise RuntimeError(f"Could not generate a valid quiz: {last_err}")
