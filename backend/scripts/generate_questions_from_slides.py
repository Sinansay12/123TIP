"""
Script to generate questions from existing slides using Gemini AI.
This reads slides from the database and creates questions for each department.
Supports progressive generation - tracks which slides have been processed.
"""
import asyncio
import sqlite3
import json
import os
import sys
from datetime import datetime

# Add parent directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from google import genai
from google.genai import types

# Gemini API Key
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "AIzaSyBwEbtjr-FwDolwoSh2gwk0js8LAUw6XNc")
client = genai.Client(api_key=GEMINI_API_KEY)

# Database path
DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "medical_app.db")

# Progress file - tracks which slides have been processed
PROGRESS_FILE = os.path.join(os.path.dirname(__file__), "generation_progress.json")

# Configuration
QUESTIONS_PER_RUN = 15  # Number of questions to generate per run
QUESTIONS_PER_SLIDE = 3  # Questions per slide batch


def load_progress():
    """Load progress from JSON file."""
    if os.path.exists(PROGRESS_FILE):
        with open(PROGRESS_FILE, 'r', encoding='utf-8') as f:
            return json.load(f)
    return {
        "last_processed_slide_id": 0,
        "total_questions_generated": 0,
        "last_run": None,
        "departments_completed": []
    }


def save_progress(progress):
    """Save progress to JSON file."""
    progress["last_run"] = datetime.now().isoformat()
    with open(PROGRESS_FILE, 'w', encoding='utf-8') as f:
        json.dump(progress, f, ensure_ascii=False, indent=2)


def get_next_slides(last_slide_id: int, limit: int = 5):
    """Get the next batch of slides to process."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute(
        """
        SELECT id, department, topic, page_number, title, content 
        FROM slides 
        WHERE id > ? AND LENGTH(content) > 100
        ORDER BY id
        LIMIT ?
        """,
        (last_slide_id, limit)
    )
    slides = cursor.fetchall()
    conn.close()
    return slides


def get_slides_by_department(department: str, limit: int = 10):
    """Get slides for a specific department."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute(
        """
        SELECT id, department, topic, page_number, title, content 
        FROM slides 
        WHERE department = ? AND LENGTH(content) > 100
        ORDER BY id
        LIMIT ?
        """,
        (department, limit)
    )
    slides = cursor.fetchall()
    conn.close()
    return slides


def get_all_departments():
    """Get all unique departments with slides."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute("SELECT DISTINCT department FROM slides ORDER BY department")
    departments = [row[0] for row in cursor.fetchall()]
    conn.close()
    return departments


def get_slide_count():
    """Get total number of slides."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute("SELECT COUNT(*) FROM slides WHERE LENGTH(content) > 100")
    count = cursor.fetchone()[0]
    conn.close()
    return count


def get_max_slide_id():
    """Get the maximum slide ID."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute("SELECT MAX(id) FROM slides")
    max_id = cursor.fetchone()[0] or 0
    conn.close()
    return max_id


async def generate_questions_for_content(content: str, topic: str, department: str, num_questions: int = 3) -> list:
    """Generate questions from slide content using Gemini AI."""
    
    prompt = f"""Sen bir tıp eğitimi uzmanısın. Aşağıdaki tıbbi ders içeriğine dayanarak,
{num_questions} adet çoktan seçmeli soru oluştur.

DEPARTMAN: {department}
KONU: {topic}

İÇERİK:
{content}

KESİN KURALLAR:
1. SADECE yukarıdaki içerikten soru oluştur.
2. Her soru için tam 3 adet yanlış cevap (çeldirici) oluştur.
3. Doğru cevabın neden doğru olduğuna dair kısa açıklama ekle.
4. Türkçe olarak soru oluştur.
5. Tıp öğrencileri için uygun zorlukta sorular hazırla.

Yanıtını tam olarak bu JSON formatında ver:
{{
    "questions": [
        {{
            "question_text": "Soru metni?",
            "correct_answer": "Doğru cevap",
            "distractors": ["Yanlış 1", "Yanlış 2", "Yanlış 3"],
            "explanation": "Açıklama..."
        }}
    ]
}}

SADECE JSON döndür, başka metin ekleme."""

    max_retries = 3
    retry_delay = 35  # seconds
    
    for attempt in range(max_retries):
        try:
            response = client.models.generate_content(
                model="gemini-2.5-flash",
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    response_mime_type="application/json"
                )
            )
            
            result = response.text
            parsed = json.loads(result)
            
            if isinstance(parsed, dict) and "questions" in parsed:
                return parsed["questions"]
            elif isinstance(parsed, list):
                return parsed
            else:
                return []
        except json.JSONDecodeError as e:
            print(f"  [WARN] JSON parse error: {e}")
            return []
        except Exception as e:
            error_str = str(e)
            if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                if attempt < max_retries - 1:
                    print(f"  [RATE LIMIT] Bekleniyor {retry_delay}s... (deneme {attempt + 1}/{max_retries})")
                    await asyncio.sleep(retry_delay)
                    continue
            print(f"  [ERROR] Question generation error: {e}")
            return []
    return []


def save_question_to_db(question: dict, department: str, topic: str, slide_id: int):
    """Save a generated question to the database."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    try:
        cursor.execute(
            """
            INSERT INTO questions (
                slide_id, department, topic, question_text, correct_answer, 
                distractors, explanation, difficulty, question_type, is_past_paper
            ) VALUES (?, ?, ?, ?, ?, ?, ?, 'medium', 'generated', 0)
            """,
            (
                slide_id,
                department,
                topic,
                question["question_text"],
                question["correct_answer"],
                json.dumps(question.get("distractors", []), ensure_ascii=False),
                question.get("explanation", ""),
            )
        )
        conn.commit()
        return cursor.lastrowid
    except Exception as e:
        print(f"  ⚠️ DB error: {e}")
        return None
    finally:
        conn.close()


def get_question_counts():
    """Get question counts by department."""
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.execute(
        """
        SELECT department, COUNT(*) as count 
        FROM questions 
        WHERE question_type = 'generated'
        GROUP BY department 
        ORDER BY count DESC
        """
    )
    counts = {row[0]: row[1] for row in cursor.fetchall()}
    conn.close()
    return counts


async def run_progressive_generation(max_questions: int = QUESTIONS_PER_RUN):
    """Run progressive question generation - continues from where it left off."""
    print("=" * 60)
    print("[AI] Gunluk Soru Uretici - Progresif Mod")
    print(f"[INFO] Tarih: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)
    
    # Load progress
    progress = load_progress()
    last_slide_id = progress["last_processed_slide_id"]
    
    print(f"\n[PROGRESS] Son islenen slayt ID: {last_slide_id}")
    print(f"[PROGRESS] Toplam uretilen soru: {progress['total_questions_generated']}")
    
    max_slide_id = get_max_slide_id()
    total_slides = get_slide_count()
    print(f"[INFO] Toplam slayt: {total_slides}, Max ID: {max_slide_id}")
    
    # Check if we've completed all slides
    if last_slide_id >= max_slide_id:
        print("\n[INFO] Tum slaytlar islendi! Bastan baslaniyor...")
        last_slide_id = 0
        progress["last_processed_slide_id"] = 0
    
    total_questions = 0
    slides_processed = 0
    
    while total_questions < max_questions:
        # Get next batch of slides
        slides = get_next_slides(last_slide_id, limit=3)
        
        if not slides:
            print("\n[INFO] Islenecek slayt kalmadi.")
            break
        
        # Combine content from slides
        combined_content = ""
        slide_ids = []
        department = ""
        topic = ""
        
        for slide in slides:
            slide_id, dept, slide_topic, page_num, title, content = slide
            combined_content += f"\n\n[Sayfa {page_num}] {title or ''}\n{content}"
            slide_ids.append(slide_id)
            last_slide_id = slide_id  # Update to latest processed ID
            if not department:
                department = dept
            if not topic:
                topic = slide_topic
        
        print(f"\n[PROCESSING] Departman: {department}")
        print(f"   Konu: {topic}")
        print(f"   Slayt IDs: {slide_ids}")
        
        # Calculate how many questions we need
        remaining = max_questions - total_questions
        questions_to_generate = min(QUESTIONS_PER_SLIDE, remaining)
        
        # Generate questions
        print(f"   [GENERATING] {questions_to_generate} soru uretiliyor...")
        questions = await generate_questions_for_content(
            combined_content[:4000],
            topic,
            department,
            num_questions=questions_to_generate
        )
        
        if questions:
            for q in questions:
                q_id = save_question_to_db(q, department, topic, slide_ids[0] if slide_ids else None)
                if q_id:
                    total_questions += 1
                    print(f"   [OK] Soru #{q_id}: {q['question_text'][:50]}...")
        
        slides_processed += len(slides)
        
        # Update progress after each batch
        progress["last_processed_slide_id"] = last_slide_id
        progress["total_questions_generated"] += len(questions) if questions else 0
        save_progress(progress)
        
        # Small delay to avoid rate limiting
        await asyncio.sleep(0.5)
    
    print("\n" + "=" * 60)
    print(f"[DONE] TAMAMLANDI!")
    print(f"   - Uretilen soru: {total_questions}")
    print(f"   - Islenen slayt: {slides_processed}")
    print(f"   - Son slayt ID: {last_slide_id}")
    print("=" * 60)
    
    # Show summary
    counts = get_question_counts()
    print("\n[SUMMARY] Departman bazli toplam soru sayilari:")
    for dept, count in counts.items():
        print(f"   {dept}: {count} soru")
    
    return {
        "questions_generated": total_questions,
        "slides_processed": slides_processed,
        "last_slide_id": last_slide_id,
        "question_counts": counts
    }


async def run_full_generation():
    """Run full generation for all departments (legacy mode)."""
    print("=" * 60)
    print("[AI] Soru Uretici - Tam Mod (Tum Departmanlar)")
    print("=" * 60)
    
    departments = get_all_departments()
    print(f"\n[INFO] {len(departments)} departman bulundu:")
    for dept in departments:
        print(f"   - {dept}")
    
    total_questions = 0
    
    for dept in departments:
        print(f"\n[PROCESSING] {dept}")
        print("-" * 40)
        
        slides = get_slides_by_department(dept, limit=5)
        
        if not slides:
            print(f"   [WARN] Slayt bulunamadi")
            continue
        
        dept_questions = 0
        combined_content = ""
        slide_ids = []
        topic = ""
        
        for slide in slides:
            slide_id, department, slide_topic, page_num, title, content = slide
            combined_content += f"\n\n[Sayfa {page_num}] {title or ''}\n{content}"
            slide_ids.append(slide_id)
            if not topic:
                topic = slide_topic
        
        print(f"   [GENERATING] {len(slides)} slayttan soru uretiliyor...")
        questions = await generate_questions_for_content(
            combined_content[:4000],
            topic,
            dept,
            num_questions=5
        )
        
        if questions:
            for q in questions:
                q_id = save_question_to_db(q, dept, topic, slide_ids[0] if slide_ids else None)
                if q_id:
                    dept_questions += 1
                    print(f"   [OK] Soru #{q_id}: {q['question_text'][:50]}...")
        
        total_questions += dept_questions
        print(f"   [STATS] {dept_questions} soru olusturuldu")
        
        await asyncio.sleep(1)
    
    print("\n" + "=" * 60)
    print(f"[DONE] TAMAMLANDI! Toplam {total_questions} soru olusturuldu")
    print("=" * 60)
    
    return {"total_questions": total_questions}


async def main():
    """Main entry point - runs progressive generation by default."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Generate questions from slides')
    parser.add_argument('--full', action='store_true', help='Run full generation for all departments')
    parser.add_argument('--count', type=int, default=QUESTIONS_PER_RUN, help=f'Number of questions to generate (default: {QUESTIONS_PER_RUN})')
    parser.add_argument('--reset', action='store_true', help='Reset progress and start from beginning')
    
    args = parser.parse_args()
    
    if args.reset:
        if os.path.exists(PROGRESS_FILE):
            os.remove(PROGRESS_FILE)
            print("[RESET] Progress silindi, bastan baslanacak.")
    
    if args.full:
        await run_full_generation()
    else:
        await run_progressive_generation(max_questions=args.count)


if __name__ == "__main__":
    asyncio.run(main())
