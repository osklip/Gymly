# backend_fastapi/main.py
from fastapi import FastAPI, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from pydantic import BaseModel
import firebase_admin
from firebase_admin import credentials, auth
import models
from database import engine, get_db

# Inicjalizacja bazy danych PostgreSQL
models.Base.metadata.create_all(bind=engine)

# Inicjalizacja Firebase Admin SDK
try:
    cred = credentials.Certificate("firebase_credentials.json")
    firebase_admin.initialize_app(cred)
except Exception as e:
    print(f"Błąd inicjalizacji Firebase: {e}")

app = FastAPI(
    title="GymApp API",
    description="Backend aplikacji wspierającej trening siłowy i grywalizację",
    version="1.0.0"
)

# Schematy Pydantic do walidacji danych wejściowych
class RejestracjaRequest(BaseModel):
    nazwa_uzytkownika: str

def verify_firebase_token(authorization: str = Header(...)):
    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy format nagłówka autoryzacyjnego."
        )
    token = authorization.split(" ")[1]
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Nieprawidłowy lub wygasły token: {str(e)}"
        )

@app.post("/api/login")
def login_user(decoded_token: dict = Depends(verify_firebase_token), db: Session = Depends(get_db)):
    firebase_uid = decoded_token.get("uid")
    db_user = db.query(models.Uzytkownik).filter(models.Uzytkownik.id == firebase_uid).first()
    
    if not db_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Użytkownik zweryfikowany w Firebase, ale brak rekordu w PostgreSQL."
        )
    
    return {
        "status": "Sukces",
        "wiadomosc": f"Witaj, {db_user.nazwa_uzytkownika}!",
        "uid": db_user.id
    }

@app.post("/api/register", status_code=status.HTTP_201_CREATED)
def register_user(
    request: RejestracjaRequest,
    decoded_token: dict = Depends(verify_firebase_token),
    db: Session = Depends(get_db)
):
    """
    Endpoint rejestracji. Oczekuje ważnego tokenu Firebase nowo utworzonego użytkownika 
    oraz unikalnej nazwy użytkownika w ciele żądania.
    """
    firebase_uid = decoded_token.get("uid")
    
    # Walidacja 1: Sprawdzenie, czy UID już istnieje w bazie (zabezpieczenie przed podwójnym wywołaniem)
    existing_user = db.query(models.Uzytkownik).filter(models.Uzytkownik.id == firebase_uid).first()
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Konto dla tego identyfikatora Firebase już istnieje w bazie bazy danych."
        )

    # Walidacja 2: Sprawdzenie unikalności nazwy użytkownika
    existing_username = db.query(models.Uzytkownik).filter(models.Uzytkownik.nazwa_uzytkownika == request.nazwa_uzytkownika).first()
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Ta nazwa użytkownika jest już zajęta."
        )

    # Zapis nowego użytkownika
    new_user = models.Uzytkownik(
        id=firebase_uid,
        nazwa_uzytkownika=request.nazwa_uzytkownika,
        data_rejestracji=datetime.now(timezone.utc)
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    return {"status": "Sukces", "wiadomosc": "Konto zostało w pełni utworzone."}