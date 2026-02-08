"""
Seed Data for Medical Study App
This module provides initial sample data for the application.
Called during application startup to populate empty database.
"""
import os
import json
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models import Slide, Question, DifficultyLevel, QuestionType


# Sample departments and topics
SAMPLE_SLIDES = [
    # Adli Tıp
    {"department": "Adli Tıp", "topic": "Adli Tıp'a Giriş", "page_number": 1, "title": "Adli Tıp Nedir?", 
     "content": "Adli tıp, tıbbi bilgi ve becerilerin hukuki sorunların çözümüne uygulanmasıdır.", "professor": "Prof. Dr. Hakan Kar"},
    {"department": "Adli Tıp", "topic": "Ölüm ve Ölüm Belirtileri", "page_number": 1, "title": "Ölüm Tanımı", 
     "content": "Ölüm, yaşamsal fonksiyonların geri dönüşümsüz olarak durmasıdır.", "professor": "Prof. Dr. Hakan Kar"},
    {"department": "Adli Tıp", "topic": "Yaralar ve Yaralanmalar", "page_number": 1, "title": "Yara Sınıflandırması", 
     "content": "Yaralar mekanik, termal, kimyasal ve elektrik kaynaklı olabilir.", "professor": "Prof. Dr. Halis Dokgöz"},
    
    # Kardiyoloji
    {"department": "Kardiyoloji", "topic": "Kalp Yetmezliği", "page_number": 1, "title": "Kalp Yetmezliği Tanımı", 
     "content": "Kalp yetmezliği, kalbin vücudun ihtiyacı olan kanı pompalayamaması durumudur.", "professor": "Kardiyoloji Anabilim Dalı"},
    {"department": "Kardiyoloji", "topic": "Koroner Arter Hastalığı", "page_number": 1, "title": "KAH Patofizyolojisi", 
     "content": "Koroner arterlerde aterosklerotik plak birikimi sonucu oluşan darlık.", "professor": "Kardiyoloji Anabilim Dalı"},
    {"department": "Kardiyoloji", "topic": "Hipertansiyon", "page_number": 1, "title": "Hipertansiyon Kriterleri", 
     "content": "Sistolik kan basıncı ≥140 mmHg ve/veya diyastolik kan basıncı ≥90 mmHg olması.", "professor": "Kardiyoloji Anabilim Dalı"},
    
    # Nöroloji
    {"department": "Nöroloji", "topic": "İnme (Stroke)", "page_number": 1, "title": "İnme Tipleri", 
     "content": "İnme iskemik (%85) ve hemorajik (%15) olarak ikiye ayrılır.", "professor": "Nöroloji Anabilim Dalı"},
    {"department": "Nöroloji", "topic": "Epilepsi", "page_number": 1, "title": "Epilepsi Tanımı", 
     "content": "Beynin anormal elektriksel aktivitesi sonucu tekrarlayan nöbetlerle karakterize hastalık.", "professor": "Nöroloji Anabilim Dalı"},
    {"department": "Nöroloji", "topic": "Parkinson Hastalığı", "page_number": 1, "title": "Parkinson Belirtileri", 
     "content": "Tremor, bradikinezi, rijidite ve postüral instabilite başlıca belirtilerdir.", "professor": "Nöroloji Anabilim Dalı"},
    
    # Dermatoloji
    {"department": "Dermatoloji", "topic": "Deri Anatomisi", "page_number": 1, "title": "Deri Katmanları", 
     "content": "Deri epidermis, dermis ve hipodermis olmak üzere üç katmandan oluşur.", "professor": "Dermatoloji Anabilim Dalı"},
    {"department": "Dermatoloji", "topic": "Egzama", "page_number": 1, "title": "Atopik Dermatit", 
     "content": "Kronik, kaşıntılı, inflamatuar bir deri hastalığıdır.", "professor": "Dermatoloji Anabilim Dalı"},
    
    # Psikiyatri
    {"department": "Psikiyatri", "topic": "Depresyon", "page_number": 1, "title": "Major Depresif Bozukluk", 
     "content": "En az 2 hafta süren depresif duygudurum ve/veya anhedoni ile karakterize.", "professor": "Psikiyatri Anabilim Dalı"},
    {"department": "Psikiyatri", "topic": "Anksiyete Bozuklukları", "page_number": 1, "title": "Anksiyete Tanımı", 
     "content": "Aşırı endişe, gerginlik ve somatik belirtilerle karakterize bozukluklar.", "professor": "Psikiyatri Anabilim Dalı"},
    
    # Göz
    {"department": "Göz", "topic": "Glokom", "page_number": 1, "title": "Glokom Tanımı", 
     "content": "Göz içi basıncının yükselmesiyle optik sinir hasarı oluşan hastalık.", "professor": "Göz Hastalıkları Anabilim Dalı"},
    {"department": "Göz", "topic": "Katarakt", "page_number": 1, "title": "Katarakt Tanımı", 
     "content": "Göz merceğinin saydamlığını kaybetmesi sonucu görme azalması.", "professor": "Göz Hastalıkları Anabilim Dalı"},
    
    # Kulak Burun Boğaz
    {"department": "Kulak Burun Boğaz", "topic": "Otit Media", "page_number": 1, "title": "Orta Kulak İltihabı", 
     "content": "Orta kulağın enfeksiyonu, çocuklarda sık görülür.", "professor": "KBB Anabilim Dalı"},
    {"department": "Kulak Burun Boğaz", "topic": "Sinüzit", "page_number": 1, "title": "Sinüzit Tanımı", 
     "content": "Paranazal sinüslerin enfeksiyonu veya inflamasyonu.", "professor": "KBB Anabilim Dalı"},
    
    # Göğüs Hastalıkları
    {"department": "Göğüs Hastalıkları", "topic": "KOAH", "page_number": 1, "title": "KOAH Tanımı", 
     "content": "Kronik obstrüktif akciğer hastalığı, kalıcı hava akımı kısıtlaması ile karakterize.", "professor": "Göğüs Hastalıkları Anabilim Dalı"},
    {"department": "Göğüs Hastalıkları", "topic": "Astım", "page_number": 1, "title": "Bronşiyal Astım", 
     "content": "Havayollarının kronik inflamatuar hastalığı, geri dönüşümlü obstrüksiyon.", "professor": "Göğüs Hastalıkları Anabilim Dalı"},
]


# Sample questions for slides
SAMPLE_QUESTIONS = [
    {"department": "Adli Tıp", "topic": "Adli Tıp'a Giriş", "question_text": "Adli tıbbın temel amacı nedir?",
     "correct_answer": "Tıbbi bilgilerin hukuki sorunların çözümünde kullanılması",
     "options": ["Sadece otopsi yapmak", "Tıbbi bilgilerin hukuki sorunların çözümünde kullanılması", 
                 "Hastane yönetimi", "İlaç geliştirme"], "difficulty": "easy"},
    
    {"department": "Kardiyoloji", "topic": "Hipertansiyon", "question_text": "Hipertansiyon tanısı için sistolik kan basıncı kaç mmHg ve üzeri olmalıdır?",
     "correct_answer": "140 mmHg",
     "options": ["120 mmHg", "130 mmHg", "140 mmHg", "150 mmHg"], "difficulty": "easy"},
    
    {"department": "Kardiyoloji", "topic": "Kalp Yetmezliği", "question_text": "Kalp yetmezliğinin tanımı nedir?",
     "correct_answer": "Kalbin vücudun ihtiyacı olan kanı pompalayamaması",
     "options": ["Kalp ritminin düzensizliği", "Kalbin vücudun ihtiyacı olan kanı pompalayamaması",
                 "Kalp kapaklarının bozulması", "Koroner arterlerin tıkanması"], "difficulty": "easy"},
    
    {"department": "Nöroloji", "topic": "İnme (Stroke)", "question_text": "İnmelerin yüzde kaçı iskemik tiptir?",
     "correct_answer": "%85",
     "options": ["%50", "%65", "%75", "%85"], "difficulty": "medium"},
    
    {"department": "Nöroloji", "topic": "Parkinson Hastalığı", "question_text": "Parkinson hastalığının kardinal bulguları hangileridir?",
     "correct_answer": "Tremor, bradikinezi, rijidite, postüral instabilite",
     "options": ["Sadece tremor", "Tremor ve ataksi", 
                 "Tremor, bradikinezi, rijidite, postüral instabilite", "Paralizi ve spastisite"], "difficulty": "medium"},
    
    {"department": "Psikiyatri", "topic": "Depresyon", "question_text": "Major depresif bozukluk tanısı için belirtiler en az ne kadar sürelidir?",
     "correct_answer": "2 hafta",
     "options": ["1 hafta", "2 hafta", "1 ay", "3 ay"], "difficulty": "easy"},
    
    {"department": "Göz", "topic": "Glokom", "question_text": "Glokomda hangi yapı hasar görür?",
     "correct_answer": "Optik sinir",
     "options": ["Kornea", "Lens", "Retina", "Optik sinir"], "difficulty": "medium"},
    
    {"department": "Göğüs Hastalıkları", "topic": "KOAH", "question_text": "KOAH'ta hava akımı kısıtlaması nasıl bir özelliktedir?",
     "correct_answer": "Kalıcı (geri dönüşümsüz)",
     "options": ["Geçici", "Geri dönüşümlü", "Kalıcı (geri dönüşümsüz)", "Değişken"], "difficulty": "medium"},
    
    {"department": "Göğüs Hastalıkları", "topic": "Astım", "question_text": "Astımda hava yolu obstrüksiyonu nasıl bir özelliktedir?",
     "correct_answer": "Geri dönüşümlü",
     "options": ["Kalıcı", "Geri dönüşümlü", "İlerleyici", "Sabit"], "difficulty": "easy"},
    
    {"department": "Dermatoloji", "topic": "Deri Anatomisi", "question_text": "Derinin en dış katmanı hangisidir?",
     "correct_answer": "Epidermis",
     "options": ["Dermis", "Epidermis", "Hipodermis", "Subkutis"], "difficulty": "easy"},
]


async def seed_database(db: AsyncSession):
    """Seed the database with sample data if empty"""
    # Check if slides table is empty
    result = await db.execute(select(func.count(Slide.id)))
    slide_count = result.scalar()
    
    if slide_count == 0:
        print("Seeding database with sample slides...")
        
        # Add slides
        slide_map = {}  # To track slide IDs for questions
        for slide_data in SAMPLE_SLIDES:
            slide = Slide(
                department=slide_data["department"],
                topic=slide_data["topic"],
                page_number=slide_data["page_number"],
                title=slide_data["title"],
                content=slide_data["content"],
                professor=slide_data.get("professor"),
            )
            db.add(slide)
            await db.flush()
            # Store for question linking
            key = f"{slide_data['department']}|{slide_data['topic']}"
            slide_map[key] = slide.id
        
        await db.commit()
        print(f"Seeded {len(SAMPLE_SLIDES)} slides.")
    else:
        print(f"Database already has {slide_count} slides. Skipping slide seed.")
    
    # Load questions from JSON file
    await seed_questions_from_json(db)


async def seed_questions_from_json(db: AsyncSession):
    """Seed questions from the exported JSON file."""
    # Check if questions already exist
    result = await db.execute(select(func.count(Question.id)))
    question_count = result.scalar()
    
    if question_count > 10:  # More than sample questions
        print(f"Database already has {question_count} questions. Skipping question seed.")
        return
    
    # Find the JSON file - check multiple locations
    possible_paths = [
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "scripts", "questions_export.json"),
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "questions_export.json"),
        os.path.join(os.path.dirname(__file__), "questions_export.json"),
        "./scripts/questions_export.json",
        "./questions_export.json",
    ]
    
    json_path = None
    for path in possible_paths:
        if os.path.exists(path):
            json_path = path
            break
    
    if not json_path:
        print("questions_export.json not found. Seeding sample questions only...")
        # Seed sample questions if no JSON found
        await seed_sample_questions(db)
        return
    
    print(f"Loading questions from {json_path}...")
    
    try:
        with open(json_path, 'r', encoding='utf-8') as f:
            questions_data = json.load(f)
        
        imported_count = 0
        for q_data in questions_data:
            # Check if question already exists (by text)
            existing = await db.execute(
                select(Question).where(Question.question_text == q_data["question_text"])
            )
            if existing.scalar():
                continue
            
            # Map difficulty
            difficulty = DifficultyLevel.MEDIUM
            if q_data.get("difficulty"):
                diff_str = q_data["difficulty"].upper()
                if diff_str == "EASY":
                    difficulty = DifficultyLevel.EASY
                elif diff_str == "HARD":
                    difficulty = DifficultyLevel.HARD
            
            # Map question type
            question_type = QuestionType.PAST_PAPER
            if q_data.get("question_type"):
                type_str = q_data["question_type"].upper()
                if type_str == "GENERATED":
                    question_type = QuestionType.GENERATED
            
            question = Question(
                slide_id=q_data.get("slide_id"),
                department=q_data.get("department"),
                topic=q_data.get("topic"),
                question_text=q_data["question_text"],
                correct_answer=q_data["correct_answer"],
                distractors=q_data.get("distractors", []),
                explanation=q_data.get("explanation"),
                difficulty=difficulty,
                question_type=question_type,
                is_past_paper=bool(q_data.get("is_past_paper", False)),
                source_file=q_data.get("source_file"),
            )
            db.add(question)
            imported_count += 1
        
        await db.commit()
        print(f"Successfully imported {imported_count} questions from JSON!")
        
    except Exception as e:
        print(f"Error loading questions from JSON: {e}")
        await db.rollback()
        # Fall back to sample questions
        await seed_sample_questions(db)


async def seed_sample_questions(db: AsyncSession):
    """Seed sample questions for basic functionality."""
    for q_data in SAMPLE_QUESTIONS:
        existing = await db.execute(
            select(Question).where(Question.question_text == q_data["question_text"])
        )
        if existing.scalar():
            continue
        
        # Get distractors (options without correct answer)
        distractors = [opt for opt in q_data["options"] if opt != q_data["correct_answer"]]
        
        question = Question(
            department=q_data["department"],
            topic=q_data["topic"],
            question_text=q_data["question_text"],
            correct_answer=q_data["correct_answer"],
            distractors=distractors,
            is_past_paper=False,
        )
        db.add(question)
    
    await db.commit()
    print(f"Seeded {len(SAMPLE_QUESTIONS)} sample questions.")
