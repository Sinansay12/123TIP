"""
Pydantic Schemas for API request/response validation.
"""
from pydantic import BaseModel, EmailStr, Field
from datetime import datetime
from typing import Optional, List
from app.models import DifficultyLevel, QuestionType, ExamStatus


# --- Auth Schemas ---
class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6)
    full_name: str
    term: int = Field(ge=1, le=6)  # Dönem 1-6
    study_group: Optional[str] = None


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: str
    full_name: str
    term: int
    study_group: Optional[str]
    created_at: datetime
    
    class Config:
        from_attributes = True


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class TokenData(BaseModel):
    user_id: Optional[int] = None


# --- Course Schemas ---
class CourseCreate(BaseModel):
    name: str
    term: int
    description: Optional[str] = None


class CourseResponse(BaseModel):
    id: int
    name: str
    term: int
    description: Optional[str]
    
    class Config:
        from_attributes = True


# --- Document Schemas ---
class DocumentResponse(BaseModel):
    id: int
    course_id: int
    filename: str
    file_type: str
    total_pages: Optional[int]
    is_processed: bool
    uploaded_at: datetime
    
    class Config:
        from_attributes = True


# --- Question Schemas ---
class QuestionResponse(BaseModel):
    id: int
    question_text: str
    choices: List[str]  # Shuffled: correct + distractors
    difficulty: DifficultyLevel
    source_document_id: Optional[int]
    page_number: Optional[int]
    
    class Config:
        from_attributes = True


class QuestionDetailResponse(QuestionResponse):
    correct_answer: str
    explanation: Optional[str]


class AnswerSubmit(BaseModel):
    question_id: int
    user_answer: str


class AnswerResponse(BaseModel):
    is_correct: bool
    correct_answer: str
    explanation: Optional[str]
    source_document_id: Optional[int]
    page_number: Optional[int]


class HintRequest(BaseModel):
    question_id: int


class HintResponse(BaseModel):
    hint: str
    source_document_id: Optional[int]
    page_number: Optional[int]


# --- Exam Schemas ---
class ExamCreate(BaseModel):
    exam_name: str
    exam_date: datetime
    course_id: Optional[int] = None


class ExamResponse(BaseModel):
    id: int
    exam_name: str
    exam_date: datetime
    status: ExamStatus
    days_remaining: int
    
    class Config:
        from_attributes = True


class DailyMixResponse(BaseModel):
    mode: str  # "general_review" or "cramming"
    days_remaining: int
    questions: List[QuestionResponse]
    past_papers_unlocked: bool
