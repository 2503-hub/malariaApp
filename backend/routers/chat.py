from __future__ import annotations

from collections import defaultdict, deque

from fastapi import APIRouter, Depends, HTTPException, status

from config.settings import settings
from schemas.chat import ChatMessage, ChatRequest, ChatResponse
from services.gemini_service import (
    GeminiAuthenticationError,
    GeminiConfigurationError,
    GeminiRateLimitError,
    GeminiService,
    GeminiServiceError,
)
from utils.security import get_current_user

router = APIRouter(tags=["chat"])

SUGGESTIONS = ["Symptoms", "Prevention", "Treatment", "Explain My Result"]
_service = GeminiService()
_memory: dict[str, deque[ChatMessage]] = defaultdict(
    lambda: deque(maxlen=settings.max_history)
)


@router.post("/chat", response_model=ChatResponse)
def chat_endpoint(request: ChatRequest, current_user=Depends(get_current_user)) -> ChatResponse:
    if not request.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message cannot be empty.",
        )

    session_id = request.session_id or f"user-{current_user.id}"
    history = _merged_history(session_id, request.history)

    try:
        reply = _service.generate_reply(request.message, history=history)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(exc),
        ) from exc
    except GeminiConfigurationError as exc:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=str(exc),
        ) from exc
    except GeminiAuthenticationError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
        ) from exc
    except GeminiRateLimitError as exc:
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=str(exc),
        ) from exc
    except GeminiServiceError as exc:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=str(exc),
        ) from exc

    _remember(
        session_id,
        [
            ChatMessage(role="user", content=request.message),
            ChatMessage(role="model", content=reply),
        ],
    )

    return ChatResponse(reply=reply, topic="malaria", suggestions=SUGGESTIONS)


def _merged_history(session_id: str, client_history: list[ChatMessage]) -> list[ChatMessage]:
    if client_history:
        return client_history[-settings.max_history :]
    return list(_memory[session_id])[-settings.max_history :]


def _remember(session_id: str, messages: list[ChatMessage]) -> None:
    for message in messages:
        _memory[session_id].append(message)
