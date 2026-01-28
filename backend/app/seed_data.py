"""
Seed Data for Medical Study App
This module provides initial sample data for the application.
Called during application startup to populate empty database.
"""
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from app.models import Slide, Question


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
    
    if slide_count > 0:
        print(f"Database already has {slide_count} slides. Skipping seed.")
        return
    
    print("Seeding database with sample data...")
    
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
    
    # Add questions
    for q_data in SAMPLE_QUESTIONS:
        key = f"{q_data['department']}|{q_data['topic']}"
        slide_id = slide_map.get(key)
        
        # Get distractors (options without correct answer)
        distractors = [opt for opt in q_data["options"] if opt != q_data["correct_answer"]]
        
        question = Question(
            slide_id=slide_id,
            department=q_data["department"],
            topic=q_data["topic"],
            question_text=q_data["question_text"],
            correct_answer=q_data["correct_answer"],
            distractors=distractors,
            is_past_paper=False,
        )
        db.add(question)
    
    await db.commit()
    print(f"Seeded {len(SAMPLE_SLIDES)} slides and {len(SAMPLE_QUESTIONS)} questions.")
