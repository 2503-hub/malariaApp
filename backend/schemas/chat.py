from typing import List, Optional

from pydantic import BaseModel, Field, field_validator


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=2000)
    session_id: Optional[str] = Field(default=None, max_length=100)
    history: List["ChatMessage"] = Field(default_factory=list, max_length=20)

    @field_validator("message")
    @classmethod
    def message_must_not_be_blank(cls, value: str) -> str:
        if not value or not value.strip():
            raise ValueError("Message cannot be empty")
        return value.strip()


class ChatMessage(BaseModel):
    role: str = Field(..., pattern="^(user|model|assistant|bot)$")
    content: str = Field(..., min_length=1, max_length=4000)
    timestamp: Optional[str] = None

    @property
    def gemini_role(self) -> str:
        return "model" if self.role in {"assistant", "bot", "model"} else "user"


class ChatResponse(BaseModel):
    reply: str
    topic: Optional[str] = "general"
    suggestions: List[str] = Field(default_factory=list)


class ChatHistory(BaseModel):
    messages: List[ChatMessage] = Field(default_factory=list)
