"""
Course Management Router.
Admin endpoints for managing courses.
"""
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.models import User, Course
from app.schemas import CourseCreate, CourseResponse
from app.routers.auth import get_current_user

router = APIRouter(prefix="/courses", tags=["Courses"])


@router.post("/", response_model=CourseResponse, status_code=201)
async def create_course(
    course_data: CourseCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new course. (Admin endpoint)"""
    course = Course(
        name=course_data.name,
        term=course_data.term,
        description=course_data.description
    )
    
    db.add(course)
    await db.commit()
    await db.refresh(course)
    
    return course


@router.get("/", response_model=List[CourseResponse])
async def list_courses(
    term: int | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    List all courses.
    Optionally filter by term to match user's current dönem.
    """
    query = select(Course)
    
    if term:
        query = query.where(Course.term == term)
    
    result = await db.execute(query.order_by(Course.term, Course.name))
    return result.scalars().all()


@router.get("/{course_id}", response_model=CourseResponse)
async def get_course(
    course_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific course by ID."""
    result = await db.execute(select(Course).where(Course.id == course_id))
    course = result.scalar_one_or_none()
    
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    
    return course
