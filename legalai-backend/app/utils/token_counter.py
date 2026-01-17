"""
Token counting utility using tiktoken (OpenAI standard).

Industry best practice for accurate token estimation.
"""
import tiktoken
from flask import current_app
from typing import Optional


class TokenCounter:
    """
    Production-grade token counter with caching and error handling.
    """
    
    _encoders = {}  
    
    @staticmethod
    def count_tokens(text: str, model: str = "gpt-4") -> int:
        """
        Count tokens in text using model-specific encoding.
        
        Args:
            text: Input text to count
            model: Model name (e.g., "gpt-4", "gpt-3.5-turbo")
            
        Returns:
            int: Number of tokens
        """
        if not text:
            return 0
            
        try:
            if model not in TokenCounter._encoders:
                try:
                    TokenCounter._encoders[model] = tiktoken.encoding_for_model(model)
                except KeyError:
                    current_app.logger.warning(
                        "Model %s not found in tiktoken, using cl100k_base encoding", 
                        model
                    )
                    TokenCounter._encoders[model] = tiktoken.get_encoding("cl100k_base")
            
            encoder = TokenCounter._encoders[model]
            return len(encoder.encode(text))
            
        except Exception as e:
            current_app.logger.warning(
                "Token counting failed for model %s: %s. Using fallback estimation.",
                model,
                str(e),
            )
            return len(text) // 4
    
    @staticmethod
    def count_messages_tokens(messages: list[dict], model: str = "gpt-4") -> int:
        """
        Count tokens in chat messages array (OpenAI format).
        
        Args:
            messages: List of {"role": "...", "content": "..."}
            model: Model name
            
        Returns:
            int: Total tokens including message formatting overhead
        """
        if not messages:
            return 0
            
        try:
            tokens_per_message = 3  
            tokens_per_name = 1
            
            total = 0
            for msg in messages:
                total += tokens_per_message
                for key, value in msg.items():
                    if value:
                        total += TokenCounter.count_tokens(str(value), model)
                    if key == "name":
                        total += tokens_per_name
            
            total += 3 
            return total
            
        except Exception as e:
            current_app.logger.warning(
                "Message token counting failed: %s. Using fallback.",
                str(e),
            )
            total_text = " ".join(
                str(msg.get("content", "")) for msg in messages if msg.get("content")
            )
            return TokenCounter.count_tokens(total_text, model)