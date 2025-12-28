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
    def _groq_base():
        return os.getenv("GROQ_BASE_URL", "https://api.groq.com/openai/v1")

    @staticmethod
    def embed(text_or_texts):
        """
        Industry standard embedding with dimension validation:
        - Accepts str or list[str]
        - Validates configured dimension matches model
        - Returns embedding or list of embeddings accordingly
        - Logs performance metrics correctly
        """
        provider = current_app.config["EMBEDDING_PROVIDER"]
        model = current_app.config["EMBEDDING_MODEL"]
        expected_dim = current_app.config["EMBEDDING_DIMENSION"]

        is_batch = isinstance(text_or_texts, list)
        inputs = text_or_texts if is_batch else [text_or_texts]
        
        t0 = time.perf_counter()
        current_app.logger.info(
            "Embedding request started provider=%s model=%s batch=%s items=%s expected_dim=%s",
            provider,
            model,
            is_batch,
            len(inputs),
            expected_dim,
        )
        
        try:
            if provider in {"openai", "openrouter", "deepseek", "grok", "groq"}:
                # Select appropriate key based on provider
                if provider == "groq":
                    key = os.getenv("GROQ_API_KEY")
                elif provider == "openrouter":
                    key = os.getenv("OPENROUTER_API_KEY")
                elif provider == "deepseek":
                    key = os.getenv("DEEPSEEK_API_KEY")
                elif provider == "grok":
                    key = os.getenv("GROK_API_KEY")
                else:
                    key = os.getenv("OPENAI_API_KEY")
                    
                if not key:
                    raise RuntimeError(f"Missing embedding API key for provider: {provider}")

                # Use correct base URL for embeddings
                if provider == "groq":
                    base_url = LLMService._groq_base()
                else:
                    base_url = LLMService._openai_base()
                
                url = f"{base_url}/embeddings"
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
                
                # Validate dimension
                actual_dim = len(embs[0]) if embs else 0
                if actual_dim != expected_dim:
                    current_app.logger.error(
                        "Embedding dimension mismatch: expected=%s actual=%s model=%s",
                        expected_dim,
                        actual_dim,
                        model,
                    )
                    raise RuntimeError(
                        f"Embedding dimension mismatch: model returned {actual_dim}D "
                        f"but config expects {expected_dim}D. Update EMBEDDING_DIMENSION "
                        f"in environment to match {model}."
                    )
                
                elapsed_ms = int((time.perf_counter() - t0) * 1000)
                current_app.logger.info(
                    "Embedding request completed provider=%s model=%s items=%s dim=%s ms=%d",
                    provider,
                    model,
                    len(embs),
                    actual_dim,
                    elapsed_ms,
                )
                
                return embs if is_batch else embs[0]
                
            raise RuntimeError(f"Unsupported embedding provider: {provider}")
            
        except Exception as e:
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            current_app.logger.exception(
                "Embedding request failed provider=%s model=%s ms=%d error=%s",
                provider,
                model,
                elapsed_ms,
                str(e),
            )
            raise

    @staticmethod
    def chat_rag(question: str, contexts: list[str], language="en", history=None):
        """
        RAG-powered chat with token tracking and timing breakdown.
        
        Returns:
            tuple: (answer_text, prompt_messages, timing_ms)
        """
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

        if provider in {"openai", "openrouter", "deepseek", "grok", "groq"}:
            if provider == "groq":
                key = os.getenv("GROQ_API_KEY")
            elif provider == "openrouter":
                key = os.getenv("OPENROUTER_API_KEY")
            elif provider == "deepseek":
                key = os.getenv("DEEPSEEK_API_KEY")
            elif provider == "grok":
                key = os.getenv("GROK_API_KEY")
            else:
                key = os.getenv("OPENAI_API_KEY")
                
            if not key:
                raise RuntimeError(f"Missing chat API key for provider: {provider}")
            
            if provider == "groq":
                base_url = LLMService._groq_base()
            else:
                base_url = LLMService._openai_base()
            
            url = f"{base_url}/chat/completions"
            r = requests.post(url, headers={
                "Authorization": f"Bearer {key}",
                "Content-Type": "application/json"
            }, json={"model": model, "messages": messages, "temperature": 0.2}, timeout=60)
            r.raise_for_status()
            
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            answer = r.json()["choices"][0]["message"]["content"].strip()
            
            current_app.logger.info(
                "ChatRAG completed provider=%s model=%s ms=%d",
                provider,
                model,
                elapsed_ms,
            )
            
            return answer, messages, elapsed_ms
        
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
            
            elapsed_ms = int((time.perf_counter() - t0) * 1000)
            answer = r.json()["content"][0]["text"].strip()
            
            current_app.logger.info(
                "ChatRAG completed provider=%s model=%s ms=%d",
                provider,
                model,
                elapsed_ms,
            )
            
            return answer, messages, elapsed_ms

        raise RuntimeError(f"Unsupported chat provider: {provider}")
