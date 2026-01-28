"""
AI Service for Question Generation, Smart Hints, and Embeddings.
Uses Google Gemini AI (Free Tier) for LLM operations.
Updated to use the new google.genai SDK.
"""
import json
from typing import List, Dict, Any, Optional
from google import genai
from google.genai import types
from app.config import get_settings

settings = get_settings()

# Configure Gemini client
client = genai.Client(api_key=settings.gemini_api_key)


class AIService:
    """AI-powered services for question generation and hints using Gemini."""
    
    def __init__(self):
        self.model_name = "gemini-2.5-flash"
        self.embedding_model = "text-embedding-004"
    
    async def create_embedding(self, text: str) -> List[float]:
        """
        Create vector embedding for text content using Gemini.
        
        Args:
            text: Text to embed.
            
        Returns:
            List of floats representing the embedding vector (768 dimensions).
        """
        try:
            result = client.models.embed_content(
                model=self.embedding_model,
                contents=text,
            )
            return result.embeddings[0].values
        except Exception as e:
            print(f"Embedding error: {e}")
            return []
    
    async def generate_questions(
        self, 
        content: str, 
        num_questions: int = 3,
        difficulty: str = "medium"
    ) -> List[Dict[str, Any]]:
        """
        Generate multiple-choice questions from document content.
        
        Args:
            content: Text content from a document page/slide.
            num_questions: Number of questions to generate.
            difficulty: Difficulty level (easy, medium, hard).
            
        Returns:
            List of question dictionaries with:
            - question_text
            - correct_answer
            - distractors (list of 3 wrong answers)
            - explanation
        """
        prompt = f"""Sen bir tıp eğitimi uzmanısın. Aşağıdaki tıbbi ders içeriğine dayanarak,
{difficulty} zorluk seviyesinde {num_questions} adet çoktan seçmeli soru oluştur.

İÇERİK:
{content}

KESİN GROUNDING KURALLARI:
1. SADECE yukarıdaki içerikten soru oluştur - kendi bilgini ASLA ekleme.
2. Eğer içerik yetersizse, daha az soru üret - uydurma.
3. Her soru anlama becerisini test etmeli, sadece ezber değil.
4. Her soru için tam 3 adet yanlış cevap (çeldirici) oluştur - akla yatkın ama kesinlikle yanlış olmalı.
5. Doğru cevabın neden doğru olduğuna dair detaylı açıklama ekle - açıklama da içerikle sınırlı olmalı.
6. Klinik olarak önemli bilgilere odaklan.

Yanıtını tam olarak bu JSON formatında ver:
{{
    "questions": [
        {{
            "question_text": "Soru metni?",
            "correct_answer": "Doğru cevap",
            "distractors": ["Yanlış cevap 1", "Yanlış cevap 2", "Yanlış cevap 3"],
            "explanation": "Bu cevabın neden doğru olduğunun detaylı açıklaması..."
        }}
    ]
}}

SADECE JSON döndür, başka metin ekleme."""

        try:
            response = client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.7,
                    response_mime_type="application/json"
                )
            )
            
            result = response.text
            parsed = json.loads(result)
            
            # Handle both {"questions": [...]} and [...] formats
            if isinstance(parsed, dict) and "questions" in parsed:
                return parsed["questions"]
            elif isinstance(parsed, list):
                return parsed
            else:
                return []
        except json.JSONDecodeError as e:
            print(f"JSON parse error: {e}")
            return []
        except Exception as e:
            print(f"Question generation error: {e}")
            return []
    
    async def generate_smart_hint(
        self, 
        question: str, 
        correct_answer: str,
        content_context: Optional[str] = None
    ) -> str:
        """
        Generate a semantic hint that doesn't reveal the answer directly.
        
        The hint focuses on:
        - Function/physiology
        - Clinical relevance
        - Related concepts
        
        NEVER reveals starting letters or direct word hints.
        
        Args:
            question: The question text.
            correct_answer: The correct answer.
            content_context: Optional context from source document.
            
        Returns:
            A helpful, semantic hint string.
        """
        context_section = ""
        if content_context:
            context_section = f"\nKAYNAK BAĞLAMI:\n{content_context}\n"
        
        prompt = f"""Bir soruya takılan tıp öğrencisine yardım ediyorsun.
Aşağıdaki soru ve cevap için yardımcı bir İPUCU ver.

SORU: {question}
DOĞRU CEVAP: {correct_answer}
{context_section}

KESİN GROUNDING KURALLARI:
1. SADECE yukarıdaki KAYNAK BAĞLAMI'ndaki bilgileri kullan.
2. Kaynak bağlamı yoksa veya yetersizse, "Bu konuda ipucu veremiyorum" de.
3. Kendi genel tıp bilgini ASLA kullanma - sadece verilen içeriğe bağlı kal.

HARF/KELİME İPUCU YASAĞI:
1. Cevabın hiçbir harfini ASLA söyleme (örn. "M ile başlar")
2. ASLA kafiye veya kelime çağrışımı kullanma
3. Cevabı ASLA doğrudan söyleme

ODAKLAN:
- İşlev veya fizyolojik rol (kaynak bağlamında varsa)
- Klinik önemi (kaynak bağlamında varsa)
- İlgili anatomik/biyokimyasal ilişkiler (kaynak bağlamında varsa)
- Etki mekanizması (kaynak bağlamında varsa)

ÖRNEK:
Cevap "Mitokondri" ise:
KÖTÜ İPUCU: "M ile başlar" veya "10 harfli"
İYİ İPUCU: "Bu organel, hücrenin enerji santrali olarak bilinir ve oksidatif fosforilasyon yoluyla ATP üretiminden sorumludur."

Tek, öz bir ipucu ver (en fazla 2-3 cümle):"""

        try:
            response = client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.5,
                    max_output_tokens=200
                )
            )
            
            return response.text.strip()
        except Exception as e:
            print(f"Hint generation error: {e}")
            return "İpucu şu anda oluşturulamıyor. Lütfen daha sonra tekrar deneyin."
    
    async def find_relevant_slide(
        self,
        question_text: str,
        document_chunks: List[Dict[str, Any]]
    ) -> Optional[Dict[str, Any]]:
        """
        Find the most relevant slide/page for a question.
        Uses embedding similarity to match question to source content.
        
        Args:
            question_text: The question to find source for.
            document_chunks: List of dicts with 'content_text', 'page_number', etc.
            
        Returns:
            The most relevant chunk dict or None.
        """
        try:
            # Create embedding for the question
            question_embedding = await self.create_embedding(question_text)
            if not question_embedding:
                return None
            
            # Find most similar chunk
            best_match = None
            best_score = -1
            
            import numpy as np
            
            for chunk in document_chunks:
                if chunk.get("embedding"):
                    chunk_emb = chunk["embedding"]
                    # Cosine similarity
                    q_np = np.array(question_embedding)
                    c_np = np.array(chunk_emb)
                    score = float(np.dot(q_np, c_np) / (np.linalg.norm(q_np) * np.linalg.norm(c_np)))
                    
                    if score > best_score:
                        best_score = score
                        best_match = chunk
            
            return best_match
        except Exception as e:
            print(f"Slide finding error: {e}")
            return None
    
    async def semantic_search(
        self, 
        query_embedding: List[float], 
        document_embeddings: List[Dict[str, Any]],
        top_k: int = 5
    ) -> List[Dict[str, Any]]:
        """
        Find most similar document chunks based on embedding similarity.
        
        Note: In production, this would use pgvector's built-in similarity search.
        This is a fallback for demonstration.
        
        Args:
            query_embedding: Query vector.
            document_embeddings: List of dicts with 'embedding' and metadata.
            top_k: Number of results to return.
            
        Returns:
            Top k most similar document chunks.
        """
        import numpy as np
        
        def cosine_similarity(a: List[float], b: List[float]) -> float:
            a_np, b_np = np.array(a), np.array(b)
            return float(np.dot(a_np, b_np) / (np.linalg.norm(a_np) * np.linalg.norm(b_np)))
        
        scored = []
        for doc in document_embeddings:
            if doc.get("embedding"):
                score = cosine_similarity(query_embedding, doc["embedding"])
                scored.append({**doc, "score": score})
        
        scored.sort(key=lambda x: x["score"], reverse=True)
        return scored[:top_k]
    
    async def answer_from_content(
        self,
        question: str,
        slide_content: str,
        slide_title: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Answer a question STRICTLY from provided slide content only.
        This implements NotebookLM-like behavior - no hallucination allowed.
        
        Args:
            question: User's question.
            slide_content: The text content from relevant slides.
            slide_title: Optional title of the source slide.
            
        Returns:
            Dict with:
            - answer: The answer text or "I don't know" message
            - found_in_content: Boolean indicating if answer was found
            - source_reference: Reference to where the answer was found
        """
        source_info = f"\nKAYNAK: {slide_title}" if slide_title else ""
        
        prompt = f"""Sen bir tıp eğitimi asistanısın. Aşağıdaki SLAYT İÇERİĞİNE DAYANARAK soruyu cevapla.

SLAYT İÇERİĞİ:
{slide_content}
{source_info}

SORU: {question}

KESİN KURALLAR - BUNLARA MUTLAKA UY:
1. SADECE yukarıdaki slayt içeriğindeki bilgileri kullan.
2. Kendi genel bilgini veya eğitim verini ASLA kullanma.
3. Eğer cevap slayt içeriğinde YOKSA, şu JSON'u döndür: {{"found": false, "answer": "Bu bilgi verilen slaytlarda bulunmuyor.", "source": null}}
4. Eğer cevap slayt içeriğinde VARSA, şu JSON'u döndür: {{"found": true, "answer": "Cevap metni...", "source": "Cevabın bulunduğu bölüm veya sayfa"}}
5. Cevabı slayttaki bilgilerle sınırlı tut, ekleme yapma.
6. Emin değilsen, "bulunmuyor" de - yanlış bilgi vermektense bilmemek tercih edilir.

SADECE JSON formatında yanıt ver:"""

        try:
            response = client.models.generate_content(
                model=self.model_name,
                contents=prompt,
                config=types.GenerateContentConfig(
                    temperature=0.1,  # Very low temperature for factual responses
                    response_mime_type="application/json"
                )
            )
            
            result = json.loads(response.text)
            
            return {
                "answer": result.get("answer", "Cevap işlenirken bir hata oluştu."),
                "found_in_content": result.get("found", False),
                "source_reference": result.get("source")
            }
        except json.JSONDecodeError as e:
            print(f"JSON parse error in answer_from_content: {e}")
            return {
                "answer": "Cevap işlenirken bir hata oluştu.",
                "found_in_content": False,
                "source_reference": None
            }
        except Exception as e:
            print(f"Answer generation error: {e}")
            return {
                "answer": "Şu anda cevap oluşturulamıyor. Lütfen daha sonra tekrar deneyin.",
                "found_in_content": False,
                "source_reference": None
            }
    
    async def chat_with_slides(
        self,
        question: str,
        all_slide_contents: List[Dict[str, Any]],
        max_context_slides: int = 5
    ) -> Dict[str, Any]:
        """
        Chat interface that searches slides and answers strictly from content.
        Implements full RAG pipeline with strict grounding.
        
        Args:
            question: User's question.
            all_slide_contents: List of dicts with 'content_text', 'title', 'embedding'.
            max_context_slides: Maximum number of slides to use as context.
            
        Returns:
            Dict with answer, sources, and confidence info.
        """
        try:
            # Step 1: Create embedding for the question
            question_embedding = await self.create_embedding(question)
            if not question_embedding:
                return {
                    "answer": "Soru işlenirken bir hata oluştu.",
                    "found_in_content": False,
                    "sources": []
                }
            
            # Step 2: Find most relevant slides using semantic search
            relevant_slides = await self.semantic_search(
                question_embedding, 
                all_slide_contents, 
                top_k=max_context_slides
            )
            
            if not relevant_slides:
                return {
                    "answer": "İlgili slayt bulunamadı.",
                    "found_in_content": False,
                    "sources": []
                }
            
            # Step 3: Combine relevant slide contents
            combined_content = "\n\n---\n\n".join([
                f"[{slide.get('title', 'Slayt')}]\n{slide.get('content_text', '')}"
                for slide in relevant_slides
            ])
            
            # Step 4: Answer strictly from the combined content
            result = await self.answer_from_content(
                question=question,
                slide_content=combined_content,
                slide_title="Birleştirilmiş Slaytlar"
            )
            
            # Add source information
            result["sources"] = [
                {
                    "title": slide.get("title"),
                    "page_number": slide.get("page_number"),
                    "relevance_score": slide.get("score", 0)
                }
                for slide in relevant_slides
            ]
            
            return result
            
        except Exception as e:
            print(f"Chat with slides error: {e}")
            return {
                "answer": "Sohbet sırasında bir hata oluştu.",
                "found_in_content": False,
                "sources": []
            }
