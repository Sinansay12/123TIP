import sqlite3
import os

db_path = 'c:/123TIP/backend/medical_app.db'

if not os.path.exists(db_path):
    print(f"Hata: {db_path} bulunamadı.")
else:
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Tabloları listele
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
    tables = cursor.fetchall()
    print("Mevcut Tablolar:")
    for table in tables:
        table_name = table[0]
        cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
        count = cursor.fetchone()[0]
        print(f"- {table_name}: {count} kayıt")
    
    conn.close()
