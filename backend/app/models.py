"""
SQLAlchemy Database Models for the Medical Study App.
Includes pgvector support for semantic search.
"""
from datetime import datetime
from sqlalchemy import (
    Column, Integer, String, Text, DateTime, ForeignKey, 
    Boolean, JSON, Enum as SQLEnum, Float
)
from sqlalchemy.orm import relationship
from sqlalchemy.ext.mutable import MutableList
# Note: pgvector disabled - using JSON text for embeddings
# from pgvector.sqlalchemy import Vector
from app.database import Base
import enum


# --- Enums ---
class DifficultyLevel(str, enum.Enum):
    EASY = "easy"
    MEDIUM = "medium"
    HARD = "hard"


class QuestionType(str, enum.Enum):
    GENERATED = "generated"
    PAST_PAPER = "past_paper"


class ExamStatus(str, enum.Enum):
    SCHEDULED = "scheduled"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


# --- Models ---
class User(Base):
    """User model for student profiles."""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(255), nullable=False)
    term = Column(Integer, nullable=False)  # Dönem (e.g., 3)
    study_group = Column(String(100), nullable=True)  # Staj Grubu (e.g., "Dahiliye A")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Relationships
    exams = relationship("UserExam", back_populates="user")


class Course(Base):
    """Course/Subject model."""
    __tablename__ = "courses"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    term = Column(Integer, nullable=False)  # Which term this course belongs to
    description = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    documents = relationship("Document", back_populates="course")


class Document(Base):
    """Uploaded document (PDF/PPTX) model."""
    __tablename__ = "documents"
    
    id = Column(Integer, primary_key=True, index=True)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=False)
    filename = Column(String(500), nullable=False)
    file_path = Column(String(1000), nullable=False)
    file_type = Column(String(50), nullable=False)  # pdf, pptx
    total_pages = Column(Integer, nullable=True)
    is_processed = Column(Boolean, default=False)
    uploaded_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    course = relationship("Course", back_populates="documents")
    chunks = relationship("DocumentChunk", back_populates="document")
    questions = relationship("Question", back_populates="source_document")


class DocumentChunk(Base):
    """
    Chunked document content with vector embeddings for semantic search.
    Each row represents a page or section of a document.
    """
    __tablename__ = "document_chunks"
    
    id = Column(Integer, primary_key=True, index=True)
    document_id = Column(Integer, ForeignKey("documents.id"), nullable=False)
    page_number = Column(Integer, nullable=False)
    content_text = Column(Text, nullable=False)
    embedding = Column(JSON, nullable=True)  # OpenAI ada-002 dimension (stored as JSON array when pgvector unavailable)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    document = relationship("Document", back_populates="chunks")


class Slide(Base):
    """
    Slide model for in-app content viewing.
    Each slide represents a page from lecture materials.
    """
    __tablename__ = "slides"
    
    id = Column(Integer, primary_key=True, index=True)
    department = Column(String(255), nullable=False, index=True)  # "Adli Tıp", "Dermatoloji" vb.
    topic = Column(String(500), nullable=False)  # Konu adı (örn: "Ateşli Silah Yaralanmaları")
    page_number = Column(Integer, nullable=False)  # Sayfa numarası
    title = Column(String(500), nullable=True)  # Sayfa başlığı
    content = Column(Text, nullable=False)  # Metin içeriği (HTML/Markdown destekli)
    bullet_points = Column(JSON, nullable=True)  # Madde işaretli listeler
    image_url = Column(String(1000), nullable=True)  # Varsa resim URL'si
    professor = Column(String(255), nullable=True)  # Hocanın adı
    source_file = Column(String(500), nullable=True)  # Kaynak dosya adı
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    questions = relationship("Question", back_populates="related_slide")


class Question(Base):
    """Generated or imported question model."""
    __tablename__ = "questions"
    
    id = Column(Integer, primary_key=True, index=True)
    source_document_id = Column(Integer, ForeignKey("documents.id"), nullable=True)
    slide_id = Column(Integer, ForeignKey("slides.id"), nullable=True)  # İlgili slayt için
    page_number = Column(Integer, nullable=True)  # For "Go to Slide" feature
    department = Column(String(255), nullable=True, index=True)  # Departman bazlı filtreleme
    topic = Column(String(500), nullable=True, index=True)  # Konu bazlı filtreleme
    question_text = Column(Text, nullable=False)
    correct_answer = Column(String(500), nullable=False)
    distractors = Column(JSON, nullable=False)  # List of wrong answers
    explanation = Column(Text, nullable=True)
    difficulty = Column(SQLEnum(DifficultyLevel), default=DifficultyLevel.MEDIUM)
    question_type = Column(SQLEnum(QuestionType), default=QuestionType.GENERATED)
    is_past_paper = Column(Boolean, default=False, index=True)  # Çıkmış soru mu?
    source_file = Column(String(500), nullable=True)  # Kaynak dosya adı
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    source_document = relationship("Document", back_populates="questions")
    related_slide = relationship("Slide", back_populates="questions")
    exam_questions = relationship("ExamQuestion", back_populates="question")


class UserExam(Base):
    """User's scheduled exam."""
    __tablename__ = "user_exams"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    exam_name = Column(String(255), nullable=False)
    exam_date = Column(DateTime, nullable=False)
    course_id = Column(Integer, ForeignKey("courses.id"), nullable=True)
    status = Column(SQLEnum(ExamStatus), default=ExamStatus.SCHEDULED)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relationships
    user = relationship("User", back_populates="exams")
    exam_questions = relationship("ExamQuestion", back_populates="exam")


class ExamQuestion(Base):
    """Junction table for exam questions with user responses."""
    __tablename__ = "exam_questions"
    
    id = Column(Integer, primary_key=True, index=True)
    exam_id = Column(Integer, ForeignKey("user_exams.id"), nullable=False)
    question_id = Column(Integer, ForeignKey("questions.id"), nullable=False)
    user_answer = Column(String(500), nullable=True)
    is_correct = Column(Boolean, nullable=True)
    hint_used = Column(Boolean, default=False)
    answered_at = Column(DateTime, nullable=True)
    
    # Relationships
    exam = relationship("UserExam", back_populates="exam_questions")
    question = relationship("Question", back_populates="exam_questions")
