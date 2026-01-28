"""
Groups Router - API endpoints for study groups/departments
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from ..database import get_db

router = APIRouter(prefix="/groups", tags=["groups"])

# 5. sınıf staj grupları (departmanları)
FIFTH_YEAR_DEPARTMENTS = [
    "Adli Tıp",
    "Anestezi ve Reanimasyon",
    "Dermatoloji",
    "Fizik Tedavi ve Rehabilitasyon",
    "Göz",
    "Göğüs Cerrahisi",
    "Göğüs Hastalıkları",
    "Halk Sağlığı",
    "Kalp ve Damar Cerrahisi",
    "Nöroşiruji",
    "Plastik",
    "Psikiyatri",
    "Kardiyoloji",
    "Kulak Burun Boğaz",
    "Nöroloji",
    "Ortopedi ve Travmatoloji",
]

# 4. ve 6. sınıf staj grupları
CLINICAL_GROUPS = [
    "Dahiliye A",
    "Dahiliye B",
    "Cerrahi A",
    "Cerrahi B",
    "Pediatri",
    "Kadın Doğum",
]


@router.get("/by-term/{term}")
async def get_groups_by_term(term: int):
    """Get study groups for a specific term"""
    if term == 5:
        return {
            "term": term,
            "groups": FIFTH_YEAR_DEPARTMENTS,
            "type": "department"
        }
    elif term >= 4:
        return {
            "term": term,
            "groups": CLINICAL_GROUPS,
            "type": "clinical_group"
        }
    else:
        return {
            "term": term,
            "groups": [],
            "type": "preclinical"
        }


@router.get("/departments")
async def get_all_departments():
    """Get all 5th year departments"""
    return {
        "departments": FIFTH_YEAR_DEPARTMENTS,
        "count": len(FIFTH_YEAR_DEPARTMENTS)
    }


@router.get("/department/{department_name}/content")
async def get_department_content(department_name: str, db: Session = Depends(get_db)):
    """Get all content (slides, past exams) for a department"""
    # TODO: Implement database query for content
    return {
        "department": department_name,
        "slides": [],
        "past_exams": [],
        "notes": []
    }
