import os
import requests
from flask import current_app
import time

class LLMService:
    """
    Provider adapters:
      - openai: OpenAI REST compatible (also works for OpenRouter if base_url set)
      - anthropic
      - deepseek (OpenAI-compatible)
      - grok (if OpenAI-compatible endpoint)
    """

    @staticmethod
    def _openai_base():
        return os.getenv("OPENAI_BASE_URL", "https://api.openai.com/v1")

    @staticmethod
    def embed(text_or_texts):
        """
        Industry standard:
        - Accepts str or list[str]
        - Uses provider batch input when available (OpenAI-compatible)
        - Returns embedding or list of embeddings accordingly
        """
        provider = current_app.config["EMBEDDING_PROVIDER"]
        model = current_app.config["EMBEDDING_MODEL"]

        is_batch = isinstance(text_or_texts, list)
        inputs = text_or_texts if is_batch else [text_or_texts]
        t0 = time.perf_counter()
        current_app.logger.info(
            "Embedding request started provider=%s model=%s batch=%s items=%s",
            provider,
            model,
            is_batch,
            len(inputs),
        )
        if provider in {"openai", "openrouter", "deepseek", "grok"}:
            key = (
                os.getenv("OPENAI_API_KEY")
                or os.getenv("OPENROUTER_API_KEY")
                or os.getenv("DEEPSEEK_API_KEY")
                or os.getenv("GROK_API_KEY")
            )
            if not key:
                raise RuntimeError("Missing embedding API key")

            url = f"{LLMService._openai_base()}/embeddings"
            r = requests.post(
                url,
                headers={
                    "Authorization": f"Bearer {key}",
                    "Content-Type": "application/json",
                },
                json={"model": model, "input": inputs},
                timeout=60 if is_batch else 40,
            )
            r.raise_for_status()
            data = r.json()["data"]

            embs = [d["embedding"] for d in data]
            return embs if is_batch else embs[0]
            current_app.logger.info(
                "Embedding request completed provider=%s model=%s ms=%d",
                provider,
                model,
                int((time.perf_counter() - t0) * 1000),
            )
        raise RuntimeError(f"Unsupported embedding provider: {provider}")

    @staticmethod
    def chat_rag(question: str, contexts: list[str], language="en", history=None):
        provider = current_app.config["CHAT_PROVIDER"]
        model = current_app.config["CHAT_MODEL"]
        t0 = time.perf_counter()
        current_app.logger.info(
            "ChatRAG started provider=%s model=%s lang=%s contexts=%s history=%s",
            provider,
            model,
            language,
            0 if not contexts else len(contexts),
            0 if not history else len(history),
        )
        system_prompt = (
            "You are an AI legal lawyer assistant for Pakistan. "
            "You MUST answer ONLY from the provided legal context. "
            "If the context does not contain the answer, DO NOT use outside knowledge. "
            "Instead reply exactly with:\n"
            "\"I am an AI legal lawyer assistant. I can only help you with legal awareness. "
            "I'm not able to process this query.\"\n"
            "Do not add anything else except the legal answer when context is sufficient. "
            "You MUST respond strictly in the selected language: {lang_name}. "
            "Even if the user writes in a different language, still respond in {lang_name}. "
            "Avoid giving procedural guarantees."
        )
        lang_name = "English" if language != "ur" else "Urdu"
        system_prompt = system_prompt.format(lang_name=lang_name)
        if language == "ur":
            system_prompt += " جواب اردو میں دیں۔"

        context_block = "\n\n".join([f"- {c}" for c in contexts]) if contexts else "No relevant context."

        history_messages = []
        if history:
            for item in history:
                if not isinstance(item, dict):
                    continue
                role = item.get("role")
                content = item.get("content")
                if role in {"user", "assistant"} and content:
                    history_messages.append({"role": role, "content": str(content)})

        user_payload = f"Context:\n{context_block}\n\nQuestion: {question}"

        messages = [
            {"role": "system", "content": system_prompt},
            *history_messages,
            {"role": "user", "content": user_payload},
        ]

        if provider in {"openai", "openrouter", "deepseek", "grok"}:
            key = os.getenv("OPENAI_API_KEY") or os.getenv("OPENROUTER_API_KEY") or os.getenv("DEEPSEEK_API_KEY") or os.getenv("GROK_API_KEY")
            if not key:
                raise RuntimeError("Missing chat API key")
            url = f"{LLMService._openai_base()}/chat/completions"
            r = requests.post(url, headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json"
            }, json={"model": model, "messages": messages, "temperature": 0.2}, timeout=60)
            r.raise_for_status()
            current_app.logger.info(
                "ChatRAG completed provider=%s model=%s ms=%d",
                provider,
                model,
                int((time.perf_counter() - t0) * 1000),
            )
            return r.json()["choices"][0]["message"]["content"].strip()
        
        if provider == "anthropic":
            key = os.getenv("ANTHROPIC_API_KEY")
            if not key:
                raise RuntimeError("Missing anthropic key")
            url = "https://api.anthropic.com/v1/messages"
            r = requests.post(url, headers={
                "x-api-key": key,
                "anthropic-version": "2023-06-01",
                "Content-Type": "application/json"
            }, json={
                "model": model,
                "max_tokens": 800,
                "temperature": 0.2,
                "system": system_prompt,
                "messages": history_messages + [{"role": "user", "content": user_payload}]
            }, timeout=60)
            r.raise_for_status()
            current_app.logger.info(
                "ChatRAG completed provider=%s model=%s ms=%d",
                provider,
                model,
                int((time.perf_counter() - t0) * 1000),
            )
            return r.json()["content"][0]["text"].strip()

        raise RuntimeError(f"Unsupported chat provider: {provider}")
