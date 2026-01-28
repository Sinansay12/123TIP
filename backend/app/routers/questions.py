"""
Quiz and Questions Router.
Handles question retrieval, hint generation, and answer submission.
"""
import random
from typing import Annotated, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models import User, Question, DocumentChunk
from app.schemas import (
    QuestionResponse, QuestionDetailResponse, 
    HintRequest, HintResponse, 
    AnswerSubmit, AnswerResponse
)
from app.routers.auth import get_current_user
from app.services.ai_service import AIService

router = APIRouter(prefix="/questions", tags=["Questions"])


def prepare_question_response(question: Question) -> QuestionResponse:
    """Prepare question for frontend with shuffled choices."""
    choices = [question.correct_answer] + question.distractors
    random.shuffle(choices)
    
    return QuestionResponse(
        id=question.id,
        question_text=question.question_text,
        choices=choices,
        difficulty=question.difficulty,
        source_document_id=question.source_document_id,
        page_number=question.page_number
    )


@router.get("/", response_model=List[QuestionResponse])
async def list_questions(
    limit: int = 20,
    difficulty: str | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Get a list of questions.
    Optionally filter by difficulty.
    """
    query = select(Question)
    
    if difficulty:
        query = query.where(Question.difficulty == difficulty)
    
    query = query.limit(limit)
    result = await db.execute(query)
    questions = result.scalars().all()
    
    return [prepare_question_response(q) for q in questions]


@router.get("/{question_id}", response_model=QuestionResponse)
async def get_question(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific question by ID."""
    result = await db.execute(select(Question).where(Question.id == question_id))
    question = result.scalar_one_or_none()
    
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    
    return prepare_question_response(question)


@router.post("/{question_id}/hint", response_model=HintResponse)
async def get_hint(
    question_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Generate a smart semantic hint for a question.
    
    CRITICAL: The hint will NEVER reveal:
    - Starting letters of the answer
    - Word length or similar direct clues
    
    Instead, it focuses on:
    - Physiological function
    - Clinical relevance
    - Related concepts
    """
    # Get question
    result = await db.execute(select(Question).where(Question.id == question_id))
    question = result.scalar_one_or_none()
    
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    
    # Get source content for better context
    context = None
    if question.source_document_id and question.page_number:
        chunk_result = await db.execute(
            select(DocumentChunk)
            .where(DocumentChunk.document_id == question.source_document_id)
            .where(DocumentChunk.page_number == question.page_number)
        )
        chunk = chunk_result.scalar_one_or_none()
        if chunk:
            context = chunk.content_text[:500]  # Limit context length
    
    # Generate hint using AI
    ai_service = AIService()
    hint = await ai_service.generate_smart_hint(
        question=question.question_text,
        correct_answer=question.correct_answer,
        content_context=context
    )
    
    return HintResponse(
        hint=hint,
        source_document_id=question.source_document_id,
        page_number=question.page_number
    )


@router.post("/{question_id}/answer", response_model=AnswerResponse)
async def submit_answer(
    question_id: int,
    answer: AnswerSubmit,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Submit an answer to a question.
    
    Returns:
    - Whether the answer is correct
    - The correct answer
    - Explanation
    - Source document reference for "Go to Slide" feature
    """
    result = await db.execute(select(Question).where(Question.id == question_id))
    question = result.scalar_one_or_none()
    
    if not question:
        raise HTTPException(status_code=404, detail="Question not found")
    
    is_correct = answer.user_answer.strip().lower() == question.correct_answer.strip().lower()
    
    return AnswerResponse(
        is_correct=is_correct,
        correct_answer=question.correct_answer,
        explanation=question.explanation,
        source_document_id=question.source_document_id,
        page_number=question.page_number
    )
