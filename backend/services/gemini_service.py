from __future__ import annotations

from typing import Iterable

from config.settings import settings
from schemas.chat import ChatMessage

try:
    from google import genai
    from google.genai import errors, types
except Exception:  # pragma: no cover - lets the API return a clear setup error
    genai = None
    types = None
    errors = None


class GeminiConfigurationError(RuntimeError):
    pass


class GeminiAuthenticationError(RuntimeError):
    pass


class GeminiRateLimitError(RuntimeError):
    pass


class GeminiServiceError(RuntimeError):
    pass


SYSTEM_PROMPT = """
You are a specialized Malaria Health Assistant inside a malaria cell detection
application. Keep answers focused on malaria, healthcare, blood smear analysis,
and interpretation of this app's AI prediction results.

You can explain:
- Parasitized: the image contains red blood cell patterns consistent with
  malaria parasites. This is a screening result, not a final diagnosis.
- Uninfected: the model did not detect malaria-like parasite patterns in the
  submitted cell image. Symptoms still require clinical testing.
- Not Cell Image: the image does not look like a valid microscope blood smear
  cell image, or the image quality/content is unsuitable.
- Confidence scores: model confidence reflects how strongly the model favored a
  class for that image; it is not the same as clinical certainty.
- Malaria symptoms, prevention, treatment guidance, diagnostic testing,
  microscopy, rapid diagnostic tests, and blood smear quality.

Medical safety rules:
- Use clear, calm, non-alarming language.
- Encourage users to consult qualified healthcare professionals for diagnosis,
  treatment, pregnancy, children, severe symptoms, or persistent fever.
- Tell users to seek urgent care for confusion, seizures, difficulty breathing,
  severe weakness, jaundice, dark urine, repeated vomiting, abnormal bleeding, or
  fever after travel to a malaria area.
- Do not prescribe exact drug regimens or dosages.
- If asked unrelated questions, politely redirect to malaria and health topics.
""".strip()


class GeminiService:
    def __init__(self) -> None:
        self.model = settings.gemini_model
        self.max_tokens = settings.gemini_max_tokens
        self.temperature = settings.gemini_temperature

        if genai is None:
            self.client = None
            return

        api_key = settings.gemini_api_key
        self.client = genai.Client(api_key=api_key) if api_key else None

    def is_configured(self) -> bool:
        return self.client is not None

    def generate_reply(
        self,
        message: str,
        history: Iterable[ChatMessage] | None = None,
    ) -> str:
        clean_message = message.strip()
        if not clean_message:
            raise ValueError("Message cannot be empty")

        if genai is None or types is None:
            raise GeminiConfigurationError(
                "The google-genai package is not installed. Install requirements.txt."
            )

        if self.client is None:
            raise GeminiConfigurationError("GEMINI_API_KEY is not configured.")

        contents = self._build_contents(clean_message, history or [])

        try:
            response = self.client.models.generate_content(
                model=self.model,
                contents=contents,
                config=types.GenerateContentConfig(
                    system_instruction=SYSTEM_PROMPT,
                    max_output_tokens=self.max_tokens,
                    temperature=self.temperature,
                ),
            )
        except Exception as exc:
            self._raise_service_error(exc)

        text = (getattr(response, "text", None) or "").strip()
        if not text:
            raise GeminiServiceError("Gemini returned an empty response.")
        return text

    def _build_contents(
        self,
        message: str,
        history: Iterable[ChatMessage],
    ) -> list:
        recent_history = list(history)[-settings.max_history :]
        contents = []

        for item in recent_history:
            content = item.content.strip()
            if not content:
                continue

            contents.append(
                types.Content(
                    role=item.gemini_role,
                    parts=[types.Part.from_text(text=content)],
                )
            )

        contents.append(
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=message)],
            )
        )
        return contents

    def _raise_service_error(self, exc: Exception) -> None:
        status_code = getattr(exc, "status_code", None) or getattr(exc, "code", None)
        message = str(exc)

        if status_code in {401, 403}:
            raise GeminiAuthenticationError(
                "Gemini rejected the API key or the key lacks permission."
            ) from exc

        if status_code == 429 or "rate limit" in message.lower():
            raise GeminiRateLimitError(
                "Gemini rate limit reached. Please try again shortly."
            ) from exc

        if "api key" in message.lower() and "invalid" in message.lower():
            raise GeminiAuthenticationError("Invalid Gemini API key.") from exc

        raise GeminiServiceError(f"Gemini API request failed: {message}") from exc
