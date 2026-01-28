"""
Document Upload and Processing Router.
Handles file upload, parsing, and question generation.
"""
import os
import uuid
from typing import Annotated
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, BackgroundTasks
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from app.database import get_db
from app.config import get_settings
from app.models import User, Document, DocumentChunk, Question, Course, DifficultyLevel
from app.schemas import DocumentResponse
from app.routers.auth import get_current_user
from app.services.document_parser import DocumentParser
from app.services.ai_service import AIService

router = APIRouter(prefix="/documents", tags=["Documents"])
settings = get_settings()


async def process_document_background(
    document_id: int,
    file_path: str,
    db_url: str
):
    """
    Background task to process uploaded document.
    
    1. Parse document (extract text per page)
    2. Create embeddings for each page
    3. Generate questions from content
    """
    from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
    
    engine = create_async_engine(db_url)
    async_session = async_sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    parser = DocumentParser()
    ai_service = AIService()
    
    async with async_session() as db:
        try:
            # Get document
            result = await db.execute(select(Document).where(Document.id == document_id))
            document = result.scalar_one()
            
            # Parse document
            pages = parser.parse(file_path)
            document.total_pages = len(pages)
            
            for page_num, content in pages:
                # Create embedding
                embedding = await ai_service.create_embedding(content)
                
                # Store chunk with embedding
                chunk = DocumentChunk(
                    document_id=document.id,
                    page_number=page_num,
                    content_text=content,
                    embedding=embedding
                )
                db.add(chunk)
                
                # Generate questions from this page
                questions = await ai_service.generate_questions(
                    content,
                    num_questions=2,  # 2 questions per page
                    difficulty="medium"
                )
                
                for q in questions:
                    question = Question(
                        source_document_id=document.id,
                        page_number=page_num,
                        question_text=q.get("question_text", ""),
                        correct_answer=q.get("correct_answer", ""),
                        distractors=q.get("distractors", []),
                        explanation=q.get("explanation", ""),
                        difficulty=DifficultyLevel.MEDIUM
                    )
                    db.add(question)
            
            document.is_processed = True
            await db.commit()
            
        except Exception as e:
            document.is_processed = False
            await db.commit()
            raise e


@router.post("/upload", response_model=DocumentResponse, status_code=201)
async def upload_document(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    course_id: int = Form(...),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload a PDF or PPTX document.
    
    The document will be processed in the background:
    1. Text extraction per page
    2. Vector embedding creation
    3. AI question generation
    
    Returns immediately with document metadata.
    """
    # Validate file type
    allowed_extensions = [".pdf", ".pptx", ".ppt"]
    file_ext = os.path.splitext(file.filename)[1].lower()
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=f"Invalid file type. Allowed: {', '.join(allowed_extensions)}"
        )
    
    # Verify course exists
    result = await db.execute(select(Course).where(Course.id == course_id))
    if not result.scalar_one_or_none():
        raise HTTPException(status_code=404, detail="Course not found")
    
    # Save file
    os.makedirs(settings.upload_dir, exist_ok=True)
    unique_filename = f"{uuid.uuid4()}{file_ext}"
    file_path = os.path.join(settings.upload_dir, unique_filename)
    
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)
    
    # Create document record
    document = Document(
        course_id=course_id,
        filename=file.filename,
        file_path=file_path,
        file_type=file_ext.replace(".", ""),
        is_processed=False
    )
    
    db.add(document)
    await db.commit()
    await db.refresh(document)
    
    # Start background processing
    background_tasks.add_task(
        process_document_background,
        document.id,
        file_path,
        settings.database_url
    )
    
    return document


@router.get("/", response_model=list[DocumentResponse])
async def list_documents(
    course_id: int | None = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """List all documents, optionally filtered by course."""
    query = select(Document)
    
    if course_id:
        query = query.where(Document.course_id == course_id)
    
    result = await db.execute(query.order_by(Document.uploaded_at.desc()))
    return result.scalars().all()


@router.get("/{document_id}", response_model=DocumentResponse)
async def get_document(
    document_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Get a specific document by ID."""
    result = await db.execute(select(Document).where(Document.id == document_id))
    document = result.scalar_one_or_none()
    
    if not document:
        raise HTTPException(status_code=404, detail="Document not found")
    
    return document
