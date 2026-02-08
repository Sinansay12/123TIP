"""
Export questions from local database to JSON for import to Render.
"""
import sqlite3
import json
import os

# Database path
DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "medical_app.db")
OUTPUT_FILE = os.path.join(os.path.dirname(__file__), "questions_export.json")


def export_questions():
    """Export all questions to JSON file."""
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.execute("""
        SELECT 
            id, slide_id, department, topic, question_text, correct_answer,
            distractors, explanation, difficulty, question_type, is_past_paper, source_file
        FROM questions
    """)
    
    questions = []
    for row in cursor.fetchall():
        q = dict(row)
        # Parse distractors JSON string
        if q["distractors"]:
            try:
                q["distractors"] = json.loads(q["distractors"])
            except:
                q["distractors"] = []
        questions.append(q)
    
    conn.close()
    
    # Write to file
    with open(OUTPUT_FILE, 'w', encoding='utf-8') as f:
        json.dump(questions, f, ensure_ascii=False, indent=2)
    
    print(f"Exported {len(questions)} questions to {OUTPUT_FILE}")
    return questions


if __name__ == "__main__":
    export_questions()
