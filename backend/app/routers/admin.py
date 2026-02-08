"""
Admin Router - API endpoints for administrative tasks like daily question generation.
"""
import asyncio
import os
import sys
import json
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, BackgroundTasks, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from typing import List
from app.database import get_db
from app.models import Question, DifficultyLevel, QuestionType

# Add scripts directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), "scripts"))

router = APIRouter(prefix="/admin", tags=["Admin"])


class GenerationResponse(BaseModel):
    message: str
    questions_generated: Optional[int] = None
    slides_processed: Optional[int] = None
    last_slide_id: Optional[int] = None
    status: str


class GenerationStats(BaseModel):
    last_run: Optional[str]
    total_questions_generated: int
    last_processed_slide_id: int
    departments_completed: list


# Background task status storage
generation_status = {
    "running": False,
    "last_result": None,
    "last_error": None
}


async def run_generation_task(max_questions: int):
    """Run question generation in background."""
    global generation_status
    generation_status["running"] = True
    generation_status["last_error"] = None
    
    try:
        # Import here to avoid circular imports
        from generate_questions_from_slides import run_progressive_generation
        result = await run_progressive_generation(max_questions=max_questions)
        generation_status["last_result"] = result
    except Exception as e:
        generation_status["last_error"] = str(e)
    finally:
        generation_status["running"] = False


@router.post("/generate-questions", response_model=GenerationResponse)
async def trigger_question_generation(
    background_tasks: BackgroundTasks,
    max_questions: int = Query(default=15, ge=1, le=100, description="Number of questions to generate")
):
    """
    Trigger daily question generation from slides.
    
    This endpoint starts a background task that:
    1. Reads slides from the database
    2. Uses Gemini AI to generate questions
    3. Saves questions back to database
    4. Tracks progress for next run
    
    The generation continues from where it left off (progressive mode).
    """
    global generation_status
    
    if generation_status["running"]:
        raise HTTPException(
            status_code=409,
            detail="Question generation is already running. Please wait for it to complete."
        )
    
    # Run in background
    background_tasks.add_task(run_generation_task, max_questions)
    
    return GenerationResponse(
        message=f"Question generation started for {max_questions} questions",
        status="started"
    )


@router.get("/generate-questions/status", response_model=GenerationResponse)
async def get_generation_status():
    """Get the current status of question generation."""
    global generation_status
    
    if generation_status["running"]:
        return GenerationResponse(
            message="Question generation is currently running",
            status="running"
        )
    
    if generation_status["last_error"]:
        return GenerationResponse(
            message=f"Last generation failed: {generation_status['last_error']}",
            status="error"
        )
    
    if generation_status["last_result"]:
        result = generation_status["last_result"]
        return GenerationResponse(
            message="Last generation completed successfully",
            questions_generated=result.get("questions_generated", 0),
            slides_processed=result.get("slides_processed", 0),
            last_slide_id=result.get("last_slide_id", 0),
            status="completed"
        )
    
    return GenerationResponse(
        message="No generation has been run yet",
        status="idle"
    )


@router.get("/generation-stats", response_model=GenerationStats)
async def get_generation_stats():
    """Get generation progress and statistics."""
    progress_file = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "scripts",
        "generation_progress.json"
    )
    
    if not os.path.exists(progress_file):
        return GenerationStats(
            last_run=None,
            total_questions_generated=0,
            last_processed_slide_id=0,
            departments_completed=[]
        )
    
    with open(progress_file, 'r', encoding='utf-8') as f:
        progress = json.load(f)
    
    return GenerationStats(
        last_run=progress.get("last_run"),
        total_questions_generated=progress.get("total_questions_generated", 0),
        last_processed_slide_id=progress.get("last_processed_slide_id", 0),
        departments_completed=progress.get("departments_completed", [])
    )


@router.post("/reset-generation-progress")
async def reset_generation_progress():
    """Reset the generation progress to start from the beginning."""
    progress_file = os.path.join(
        os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
        "scripts",
        "generation_progress.json"
    )
    
    if os.path.exists(progress_file):
        os.remove(progress_file)
        return {"message": "Generation progress reset successfully", "status": "reset"}
    
    return {"message": "No progress file found", "status": "not_found"}


# --- Question Import/Export ---

class QuestionImport(BaseModel):
    """Schema for importing a question."""
    department: str
    topic: Optional[str] = None
    question_text: str
    correct_answer: str
    distractors: List[str]
    explanation: Optional[str] = None
    difficulty: str = "medium"
    is_past_paper: bool = False


class ImportResponse(BaseModel):
    """Response for import operation."""
    message: str
    imported_count: int
    skipped_count: int
    status: str


@router.post("/import-questions", response_model=ImportResponse)
async def import_questions(
    questions: List[QuestionImport],
    db: AsyncSession = Depends(get_db)
):
    """
    Bulk import questions into the database.
    
    This endpoint accepts a list of questions and inserts them into the database.
    Used for syncing questions from local development to production.
    """
    imported = 0
    skipped = 0
    
    for q in questions:
        try:
            # Map difficulty string to enum
            difficulty_map = {
                "easy": DifficultyLevel.EASY,
                "medium": DifficultyLevel.MEDIUM,
                "hard": DifficultyLevel.HARD
            }
            
            question = Question(
                department=q.department,
                topic=q.topic,
                question_text=q.question_text,
                correct_answer=q.correct_answer,
                distractors=q.distractors,
                explanation=q.explanation,
                difficulty=difficulty_map.get(q.difficulty, DifficultyLevel.MEDIUM),
                question_type=QuestionType.GENERATED,
                is_past_paper=q.is_past_paper
            )
            
            db.add(question)
            imported += 1
        except Exception as e:
            print(f"Error importing question: {e}")
            skipped += 1
    
    await db.commit()
    
    return ImportResponse(
        message=f"Successfully imported {imported} questions",
        imported_count=imported,
        skipped_count=skipped,
        status="completed"
    )


@router.get("/question-count")
async def get_question_count(db: AsyncSession = Depends(get_db)):
    """Get the total number of questions in the database."""
    from sqlalchemy import select, func
    result = await db.execute(select(func.count(Question.id)))
    count = result.scalar()
    return {"count": count, "status": "ok"}

