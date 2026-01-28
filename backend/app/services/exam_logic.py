"""
Exam Logic Service - The 7-Day Algorithm.
Implements the time-based difficulty adjustment and question selection.
"""
from datetime import datetime, date
from typing import List, Tuple, Optional
from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession
from app.models import Question, UserExam, Course, DifficultyLevel, QuestionType
import random


class ExamLogicService:
    """
    Implements the 7-Day Logic algorithm for exam preparation.
    
    - If exam is > 7 days away: General review mode (easy-medium questions)
    - If exam is <= 7 days away: Cramming mode (medium-hard questions + past papers)
    """
    
    GENERAL_REVIEW_THRESHOLD = 7  # days
    
    # Difficulty weights for different modes
    GENERAL_REVIEW_WEIGHTS = {
        DifficultyLevel.EASY: 0.6,
        DifficultyLevel.MEDIUM: 0.4,
        DifficultyLevel.HARD: 0.0
    }
    
    CRAMMING_WEIGHTS = {
        DifficultyLevel.EASY: 0.0,
        DifficultyLevel.MEDIUM: 0.4,
        DifficultyLevel.HARD: 0.6
    }
    
    QUESTIONS_PER_COURSE = 7
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    def calculate_days_remaining(self, exam_date: datetime) -> int:
        """Calculate days between now and exam date."""
        today = datetime.now().date()
        exam_day = exam_date.date() if isinstance(exam_date, datetime) else exam_date
        delta = exam_day - today
        return max(0, delta.days)
    
    def get_mode(self, days_remaining: int) -> Tuple[str, dict, bool]:
        """
        Determine study mode based on days remaining.
        
        Returns:
            Tuple of (mode_name, difficulty_weights, past_papers_unlocked)
        """
        if days_remaining > self.GENERAL_REVIEW_THRESHOLD:
            return ("general_review", self.GENERAL_REVIEW_WEIGHTS, False)
        else:
            return ("cramming", self.CRAMMING_WEIGHTS, True)
    
    async def get_daily_questions(
        self,
        user_id: int,
        exam: Optional[UserExam] = None
    ) -> dict:
        """
        Generate daily question mix based on user's exam schedule.
        
        Implements the 7-Day Logic:
        - > 7 days: 7 questions per course, easy-medium
        - <= 7 days: Focus on exam course, medium-hard, unlock past papers
        
        Args:
            user_id: The user's ID.
            exam: Optional specific exam to prepare for.
            
        Returns:
            Dictionary with mode info and questions.
        """
        # Get user's upcoming exams if not specified
        if not exam:
            result = await self.db.execute(
                select(UserExam)
                .where(UserExam.user_id == user_id)
                .where(UserExam.exam_date >= datetime.now())
                .order_by(UserExam.exam_date)
                .limit(1)
            )
            exam = result.scalar_one_or_none()
        
        if not exam:
            # No upcoming exam - return general mixed questions
            return await self._get_general_mix()
        
        days_remaining = self.calculate_days_remaining(exam.exam_date)
        mode, weights, past_papers_unlocked = self.get_mode(days_remaining)
        
        if mode == "general_review":
            questions = await self._get_general_review_questions(weights)
        else:
            questions = await self._get_cramming_questions(
                exam.course_id, 
                weights, 
                past_papers_unlocked
            )
        
        return {
            "mode": mode,
            "days_remaining": days_remaining,
            "past_papers_unlocked": past_papers_unlocked,
            "exam_name": exam.exam_name,
            "questions": questions
        }
    
    async def _get_general_mix(self) -> dict:
        """Get a general mix of questions when no exam is scheduled."""
        result = await self.db.execute(
            select(Question)
            .where(Question.is_past_paper == False)
            .order_by(Question.id)  # Could be randomized
            .limit(20)
        )
        questions = result.scalars().all()
        
        return {
            "mode": "free_study",
            "days_remaining": -1,
            "past_papers_unlocked": False,
            "exam_name": None,
            "questions": list(questions)
        }
    
    async def _get_general_review_questions(
        self, 
        weights: dict
    ) -> List[Question]:
        """
        Get questions for general review mode (> 7 days).
        7 questions per course, weighted towards easy-medium.
        """
        # Get all courses
        result = await self.db.execute(select(Course))
        courses = result.scalars().all()
        
        all_questions = []
        
        for course in courses:
            # Get documents for this course
            # Then get questions from those documents
            course_questions = await self._get_weighted_questions(
                course_id=course.id,
                weights=weights,
                limit=self.QUESTIONS_PER_COURSE,
                include_past_papers=False
            )
            all_questions.extend(course_questions)
        
        random.shuffle(all_questions)
        return all_questions
    
    async def _get_cramming_questions(
        self,
        focus_course_id: Optional[int],
        weights: dict,
        include_past_papers: bool
    ) -> List[Question]:
        """
        Get questions for cramming mode (<= 7 days).
        Focus on exam course, include past papers.
        """
        questions = []
        
        if focus_course_id:
            # Get 70% questions from focus course
            focus_questions = await self._get_weighted_questions(
                course_id=focus_course_id,
                weights=weights,
                limit=15,
                include_past_papers=include_past_papers
            )
            questions.extend(focus_questions)
            
            # Get 30% from other courses
            other_questions = await self._get_weighted_questions(
                exclude_course_id=focus_course_id,
                weights=weights,
                limit=5,
                include_past_papers=False
            )
            questions.extend(other_questions)
        else:
            questions = await self._get_weighted_questions(
                weights=weights,
                limit=20,
                include_past_papers=include_past_papers
            )
        
        random.shuffle(questions)
        return questions
    
    async def _get_weighted_questions(
        self,
        weights: dict,
        limit: int,
        course_id: Optional[int] = None,
        exclude_course_id: Optional[int] = None,
        include_past_papers: bool = False
    ) -> List[Question]:
        """
        Get questions with weighted difficulty distribution.
        """
        # Calculate how many of each difficulty based on weights
        counts = {
            diff: int(limit * weight) 
            for diff, weight in weights.items() 
            if weight > 0
        }
        
        # Ensure we get at least 'limit' questions total
        remaining = limit - sum(counts.values())
        if remaining > 0:
            # Add remaining to medium difficulty
            counts[DifficultyLevel.MEDIUM] = counts.get(DifficultyLevel.MEDIUM, 0) + remaining
        
        all_questions = []
        
        for difficulty, count in counts.items():
            if count <= 0:
                continue
                
            query = select(Question).where(Question.difficulty == difficulty)
            
            if not include_past_papers:
                query = query.where(Question.is_past_paper == False)
            
            # Apply course filter if specified
            if course_id:
                # Join with documents to filter by course
                from app.models import Document
                query = query.join(Document).where(Document.course_id == course_id)
            elif exclude_course_id:
                from app.models import Document
                query = query.join(Document).where(Document.course_id != exclude_course_id)
            
            query = query.limit(count)
            
            result = await self.db.execute(query)
            questions = result.scalars().all()
            all_questions.extend(questions)
        
        return all_questions
