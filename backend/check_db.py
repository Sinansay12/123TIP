"""Check database status"""
import sqlite3

conn = sqlite3.connect('medical_app.db')
cursor = conn.cursor()

print("=== Slides by Department ===")
cursor.execute('SELECT department, COUNT(*) as cnt FROM slides GROUP BY department ORDER BY cnt DESC')
for r in cursor.fetchall():
    print(f"{r[0]}: {r[1]} slides")

print()
print("=== Questions by Department ===")
cursor.execute('SELECT department, COUNT(*) as cnt FROM questions GROUP BY department ORDER BY cnt DESC')
for r in cursor.fetchall():
    print(f"{r[0]}: {r[1]} questions")

print()
print("=== Sample Questions ===")
cursor.execute('SELECT id, department, question_text FROM questions LIMIT 3')
for r in cursor.fetchall():
    print(f"[{r[0]}] {r[1]}: {r[2][:80]}...")

conn.close()
