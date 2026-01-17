"""
RAG Evaluation and Monitoring Service.

Production-grade analytics for:
- Answer quality tracking
- Performance monitoring
- Source attribution
- Token usage analysis
- Error diagnostics
"""
from flask import current_app
from ..extensions import db
from ..models.rag_evaluation import RAGEvaluationLog
from ..models.rag import KnowledgeChunk, KnowledgeSource
from ..utils.token_counter import TokenCounter
from typing import Optional, List, Dict, Any
import time


class RAGEvaluationService:
    """
    Service for logging and analyzing RAG system performance.
    
    Thread-safe, designed for async execution via Celery.
    """
    
    @staticmethod
    def log_evaluation(
        user_id: int,
        conversation_id: Optional[int],
        language: str,
        safe_mode: bool,
        is_new_conversation: bool,
        
        question: str,
        answer: str,
        
        threshold: float,
        best_distance: Optional[float],
        contexts_found: int,
        contexts_used: int,
        in_domain: bool,
        decision: str,
        chunk_ids: List[int],
        
        embedding_time_ms: int,
        llm_time_ms: Optional[int],
        total_time_ms: int,
        
        embedding_model: str,
        embedding_dimension: Optional[int],
        chat_model: Optional[str],
        
        prompt_messages: Optional[List[Dict]] = None,
        completion_text: Optional[str] = None,
        
        error_occurred: bool = False,
        error_type: Optional[str] = None,
        error_message: Optional[str] = None,
    ) -> Optional[int]:
        """
        Log RAG evaluation metrics (async-safe).
        
        Returns:
            Optional[int]: Evaluation log ID if successful, None if failed
        """
        try:
            question_sanitized = question[:5000] if question else ""
            answer_sanitized = answer[:10000] if answer else ""
            
            fallback_indicators = [
                "can only help with legal awareness",
                "could not find relevant information",
                "please ask a legal question",
                "i can only help",
                "not able to process"
            ]
            used_fallback = any(
                indicator in answer_sanitized.lower() 
                for indicator in fallback_indicators
            )
            
            disclaimer_indicators = [
                "this information is provided only",
                "please contact a lawyer",
                "for urgent help, use the helpline"
            ]
            disclaimer_added = any(
                indicator in answer_sanitized.lower()
                for indicator in disclaimer_indicators
            )
            
            source_titles = []
            if chunk_ids:
                try:
                    chunks = (
                        KnowledgeChunk.query
                        .filter(KnowledgeChunk.id.in_(chunk_ids))
                        .join(KnowledgeSource, KnowledgeChunk.source_id == KnowledgeSource.id)
                        .with_entities(KnowledgeSource.title)
                        .distinct()
                        .all()
                    )
                    source_titles = [c.title for c in chunks if c.title]
                except Exception as e:
                    current_app.logger.warning(
                        "Failed to fetch source titles for evaluation: %s", 
                        str(e)
                    )
            
            prompt_tokens = None
            completion_tokens = None
            total_tokens = None
            
            if chat_model:
                try:
                    if prompt_messages:
                        prompt_tokens = TokenCounter.count_messages_tokens(
                            prompt_messages, 
                            chat_model
                        )
                    
                    if completion_text:
                        completion_tokens = TokenCounter.count_tokens(
                            completion_text, 
                            chat_model
                        )
                    
                    if prompt_tokens and completion_tokens:
                        total_tokens = prompt_tokens + completion_tokens
                        
                except Exception as e:
                    current_app.logger.warning(
                        "Token counting failed in evaluation: %s", 
                        str(e)
                    )
            
            eval_log = RAGEvaluationLog(
                user_id=user_id,
                conversation_id=conversation_id,
                language=language,
                safe_mode=safe_mode,
                is_new_conversation=is_new_conversation,
                
                question_text=question_sanitized,
                question_length=len(question),
                answer_text=answer_sanitized,
                answer_length=len(answer),
                
                threshold_used=threshold,
                best_distance=best_distance,
                contexts_found=contexts_found,
                contexts_used=contexts_used,
                in_domain=in_domain,
                decision=decision,
                source_chunk_ids=chunk_ids if chunk_ids else [],
                source_titles=source_titles if source_titles else [],
                
                embedding_time_ms=embedding_time_ms,
                llm_time_ms=llm_time_ms,
                total_time_ms=total_time_ms,
                
                prompt_tokens=prompt_tokens,
                completion_tokens=completion_tokens,
                total_tokens=total_tokens,
                
                embedding_model=embedding_model,
                embedding_dimension=embedding_dimension,
                chat_model=chat_model,
                
                used_fallback=used_fallback,
                disclaimer_added=disclaimer_added,
                
                error_occurred=error_occurred,
                error_type=error_type,
                error_message=error_message[:500] if error_message else None,
            )
            
            db.session.add(eval_log)
            db.session.commit()
            
            current_app.logger.info(
                "RAG evaluation logged: id=%s user=%s decision=%s in_domain=%s "
                "contexts=%s/%s distance=%.4f threshold=%.4f fallback=%s "
                "time=%sms tokens=%s",
                eval_log.id,
                user_id,
                decision,
                in_domain,
                contexts_used,
                contexts_found,
                best_distance if best_distance else 0,
                threshold,
                used_fallback,
                total_time_ms,
                total_tokens if total_tokens else "N/A",
            )
            
            return eval_log.id
            
        except Exception as e:
            current_app.logger.exception(
                "Failed to log RAG evaluation: %s", 
                str(e)
            )
            db.session.rollback()
            return None