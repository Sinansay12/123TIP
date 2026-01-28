"""
Slides Router - API endpoints for slide content (Handwritten Async Version)
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, distinct
from typing import List, Optional
from pydantic import BaseModel
from ..database import get_db
from ..models import Slide, Question

router = APIRouter(prefix="/slides", tags=["slides"])

# --- Schemas ---
class SlideBase(BaseModel):
    department: str
    topic: str
    page_number: int
    title: Optional[str] = None
    content: str
    bullet_points: Optional[List[str]] = None
    image_url: Optional[str] = None
    professor: Optional[str] = None

    class Config:
        from_attributes = True

class SlideResponse(SlideBase):
    id: int

    class Config:
        from_attributes = True

class TopicResponse(BaseModel):
    topic: str
    slide_count: int
    professor: Optional[str] = None

# --- Endpoints ---
@router.get("/departments")
async def get_slide_departments(db: AsyncSession = Depends(get_db)):
    """Get all departments that have slides"""
    result = await db.execute(select(distinct(Slide.department)))
    departments = result.scalars().all()
    return {
        "departments": sorted(list(departments))
    }

@router.get("/department/{department}/topics")
async def get_department_topics(department: str, db: AsyncSession = Depends(get_db)):
    """Get all topics for a department"""
    result = await db.execute(
        select(Slide).filter(Slide.department == department)
    )
    slides = result.scalars().all()
    
    # Group by topic
    topics = {}
    for slide in slides:
        if slide.topic not in topics:
            topics[slide.topic] = {
                "topic": slide.topic,
                "slide_count": 0,
                "professor": slide.professor
            }
        topics[slide.topic]["slide_count"] += 1
    
    return {
        "department": department,
        "topics": sorted(list(topics.values()), key=lambda x: x["topic"])
    }

@router.get("/department/{department}/topic/{topic}")
async def get_topic_slides(department: str, topic: str, db: AsyncSession = Depends(get_db)):
    """Get all slides for a topic"""
    result = await db.execute(
        select(Slide).filter(
            Slide.department == department,
            Slide.topic == topic
        ).order_by(Slide.page_number)
    )
    slides = result.scalars().all()
    
    return {
        "department": department,
        "topic": topic,
        "slides": [SlideResponse.model_validate(s) for s in slides],
        "total_pages": len(slides)
    }

@router.get("/{slide_id}")
async def get_slide(slide_id: int, db: AsyncSession = Depends(get_db)):
    """Get a single slide by ID"""
    result = await db.execute(select(Slide).where(Slide.id == slide_id))
    slide = result.scalar_one_or_none()
    if not slide:
        raise HTTPException(status_code=404, detail="Slide not found")
    
    return SlideResponse.model_validate(slide)

@router.get("/department/{department}/questions")
async def get_department_questions(department: str, db: AsyncSession = Depends(get_db)):
    """Get all questions for a department - for past exams tab"""
    result = await db.execute(
        select(Question).filter(Question.department == department)
    )
    questions = result.scalars().all()
    
    return {
        "department": department,
        "questions": [
            {
                "id": q.id,
                "question_text": q.question_text,
                "correct_answer": q.correct_answer,
                "distractors": q.distractors,
                "topic": q.topic,
                "slide_id": q.slide_id,
                "is_past_paper": q.is_past_paper,
                "explanation": q.explanation,
            } for q in questions
        ],
        "total": len(questions)
    }

@router.get("/{slide_id}/questions")
async def get_slide_questions(slide_id: int, db: AsyncSession = Depends(get_db)):
    """Get questions related to a specific slide"""
    result = await db.execute(select(Question).where(Question.slide_id == slide_id))
    questions = result.scalars().all()
    
    return {
        "slide_id": slide_id,
        "questions": [
            {
                "id": q.id,
                "question_text": q.question_text,
                "is_past_paper": q.is_past_paper
            } for q in questions
        ]
    }

@router.post("/bulk-create")
async def create_slides_bulk(slides: List[SlideBase], db: AsyncSession = Depends(get_db)):
    """Bulk create slides (for importing from files)"""
    created_slides = []
    for slide_data in slides:
        slide = Slide(**slide_data.model_dump())
        db.add(slide)
        created_slides.append(slide)
    
    await db.commit()
    return {
        "created": len(created_slides)
    }
