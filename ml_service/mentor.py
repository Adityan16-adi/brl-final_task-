"""AI mentor: text chatbot with per-session memory and optional RAG.

Your original RAG code lives on here: if a course has uploaded materials
(add_materials), the mentor retrieves relevant chunks for each question.
Without materials it just acts as a general study mentor.

Sessions are kept in memory; swap `self.sessions` for a DB/Redis in production.
"""
from collections import defaultdict

from langchain_community.vectorstores import FAISS
from langchain_core.messages import AIMessage, HumanMessage
from langchain_core.output_parsers import StrOutputParser
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_text_splitters import RecursiveCharacterTextSplitter

from llm import get_embeddings, get_llm

SYSTEM = (
    "You are the AI mentor inside a classroom + video meeting app. You help students "
    "understand topics, plan their study, and clear doubts. Be friendly, clear and concise. "
    "Explain step by step and give a short example when useful. "
    "If course material is provided below, prefer it and say when the answer is not in it. "
    "Do not make up facts; if unsure, say so.\n\n"
    "Course material (may be empty):\n{context}"
)

MAX_TURNS = 8  # remembered exchanges per session


class Mentor:
    def __init__(self):
        self._chain = None
        self.sessions: dict[str, list] = defaultdict(list)
        self.stores: dict[str, FAISS] = {}
        self.splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        self.prompt = ChatPromptTemplate.from_messages(
            [("system", SYSTEM), MessagesPlaceholder("history"), ("human", "{question}")]
        )

    @property
    def chain(self):
        # built on first use so the server can start even if the API key is missing
        if self._chain is None:
            self._chain = self.prompt | get_llm(temperature=0.4) | StrOutputParser()
        return self._chain

    def add_materials(self, course_id: str, text: str) -> int:
        chunks = self.splitter.split_text(text)
        if not chunks:
            return 0
        if course_id in self.stores:
            self.stores[course_id].add_texts(chunks)
        else:
            self.stores[course_id] = FAISS.from_texts(chunks, get_embeddings())
        return len(chunks)

    def _context(self, course_id: str | None, question: str) -> str:
        store = self.stores.get(course_id) if course_id else None
        if not store:
            return "(none)"
        docs = store.similarity_search(question, k=4)
        return "\n\n".join(d.page_content for d in docs)

    def chat(self, session_id: str, message: str, course_id: str | None = None) -> str:
        history = self.sessions[session_id][-MAX_TURNS * 2:]
        answer = self.chain.invoke(
            {"history": history, "question": message, "context": self._context(course_id, message)}
        )
        self.sessions[session_id] += [HumanMessage(content=message), AIMessage(content=answer)]
        return answer

    def reset(self, session_id: str) -> None:
        self.sessions.pop(session_id, None)
