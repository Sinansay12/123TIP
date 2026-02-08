"""
Exam and Daily Mix Router.
Handles exam scheduling and the 7-Day Logic algorithm.
"""
from typing import Annotated, List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import datetime
from app.database import get_db
from app.models import User, UserExam, ExamQuestion
from app.schemas import ExamCreate, ExamResponse, DailyMixResponse, QuestionResponse
from app.routers.auth import get_current_user
from app.routers.questions import prepare_question_response
from app.services.exam_logic import ExamLogicService

router = APIRouter(prefix="/exams", tags=["Exams"])


@router.post("/", response_model=ExamResponse, status_code=201)
async def create_exam(
    exam_data: ExamCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Schedule a new exam date.
    
    This triggers the 7-Day Logic:
    - If exam > 7 days away: General review mode
    - If exam <= 7 days away: Cramming mode with past papers
    """
    exam = UserExam(
        user_id=current_user.id,
        exam_name=exam_data.exam_name,
        exam_date=exam_data.exam_date,
        course_id=exam_data.course_id
    )
    
    db.add(exam)
    await db.commit()
    await db.refresh(exam)
    
    # Calculate days remaining
    days_remaining = (exam.exam_date.date() - datetime.now().date()).days
    days_remaining = max(0, days_remaining)
    
    return ExamResponse(
        id=exam.id,
        exam_name=exam.exam_name,
        exam_date=exam.exam_date,
        status=exam.status,
        days_remaining=days_remaining
    )


@router.get("/", response_model=List[ExamResponse])
async def list_exams(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all exams for the current user."""
    result = await db.execute(
        select(UserExam)
        .where(UserExam.user_id == current_user.id)
        .order_by(UserExam.exam_date)
    )
    exams = result.scalars().all()
    
    response = []
    for exam in exams:
        days_remaining = (exam.exam_date.date() - datetime.now().date()).days
        days_remaining = max(0, days_remaining)
        
        response.append(ExamResponse(
            id=exam.id,
            exam_name=exam.exam_name,
            exam_date=exam.exam_date,
            status=exam.status,
            days_remaining=days_remaining
        ))
    
    return response


@router.get("/daily", response_model=DailyMixResponse)
async def get_daily_mix(
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get the daily question mix based on the 7-Day Logic.
    
    Algorithm:
    - If no exam scheduled: Free study mode
    - If exam > 7 days: General review (7 q/course, easy-medium)
    - If exam <= 7 days: Cramming (focus course, medium-hard, past papers unlocked)
    """
    exam_service = ExamLogicService(db)
    
    # Use user_id if authenticated, otherwise get general mix
    user_id = current_user.id if current_user else None
    result = await exam_service.get_daily_questions(user_id)
    
    questions = [prepare_question_response(q) for q in result.get("questions", [])]
    
    return DailyMixResponse(
        mode=result.get("mode", "free_study"),
        days_remaining=result.get("days_remaining", -1),
        questions=questions,
        past_papers_unlocked=result.get("past_papers_unlocked", False),
        exam_name=result.get("exam_name")
    )


@router.get("/{exam_id}", response_model=ExamResponse)
async def get_exam(
    exam_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific exam by ID."""
    result = await db.execute(
        select(UserExam)
        .where(UserExam.id == exam_id)
        .where(UserExam.user_id == current_user.id)
    )
    exam = result.scalar_one_or_none()
    
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")
    
    days_remaining = (exam.exam_date.date() - datetime.now().date()).days
    days_remaining = max(0, days_remaining)
    
    return ExamResponse(
        id=exam.id,
        exam_name=exam.exam_name,
        exam_date=exam.exam_date,
        status=exam.status,
        days_remaining=days_remaining
    )
