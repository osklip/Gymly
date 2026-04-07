from sqlalchemy import Column, Integer, String, Numeric, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import relationship
from database import Base

class Uzytkownik(Base):
    __tablename__ = "uzytkownik"

    id = Column(String, primary_key=True, index=True) # Firebase UID
    nazwa_uzytkownika = Column(String(50), unique=True, nullable=False)
    suma_punktow = Column(Integer, default=0)
    data_rejestracji = Column(DateTime, nullable=False)

    plany = relationship("PlanTreningowy", back_populates="autor")
    sesje = relationship("SesjaTreningowa", back_populates="uzytkownik")
    pomiary = relationship("PomiarCiala", back_populates="uzytkownik")
    odznaki = relationship("OdznakaUzytkownika", back_populates="uzytkownik")
    historia_punktow = relationship("HistoriaPunktow", back_populates="uzytkownik")

class SlownikKategoriiPunktow(Base):
    __tablename__ = "slownik_kategorii_punktow"

    id = Column(Integer, primary_key=True, index=True)
    nazwa_aktywnosci = Column(String(100), unique=True, nullable=False)
    domyslna_wartosc_punktowa = Column(Integer, nullable=False)

    wpisy_historyczne = relationship("HistoriaPunktow", back_populates="kategoria")

class HistoriaPunktow(Base):
    __tablename__ = "historia_punktow"

    id = Column(Integer, primary_key=True, index=True)
    uzytkownik_id = Column(String, ForeignKey("uzytkownik.id"), nullable=False)
    kategoria_id = Column(Integer, ForeignKey("slownik_kategorii_punktow.id"), nullable=False)
    ilosc_przyznanych_punktow = Column(Integer, nullable=False)
    data_przyznania = Column(DateTime, nullable=False)

    uzytkownik = relationship("Uzytkownik", back_populates="historia_punktow")
    kategoria = relationship("SlownikKategoriiPunktow", back_populates="wpisy_historyczne")

class PomiarCiala(Base):
    __tablename__ = "pomiar_ciala"

    id = Column(Integer, primary_key=True, index=True)
    uzytkownik_id = Column(String, ForeignKey("uzytkownik.id"), nullable=False)
    waga_kg = Column(Numeric(5, 2))
    data_pomiaru = Column(DateTime, nullable=False)
    dodatkowe_wymiary = Column(JSONB)

    uzytkownik = relationship("Uzytkownik", back_populates="pomiary")

class Cwiczenie(Base):
    __tablename__ = "cwiczenie"

    id = Column(Integer, primary_key=True, index=True)
    nazwa = Column(String(100), nullable=False)
    partia_miesniowa = Column(String(50), nullable=False)
    rodzaj_sprzetu = Column(String(50), nullable=False)
    typ_ruchu = Column(String(50))

class PlanTreningowy(Base):
    __tablename__ = "plan_treningowy"

    id = Column(Integer, primary_key=True, index=True)
    uzytkownik_id = Column(String, ForeignKey("uzytkownik.id"), nullable=False)
    nazwa = Column(String(100), nullable=False)
    data_utworzenia = Column(DateTime, nullable=False)

    autor = relationship("Uzytkownik", back_populates="plany")
    cwiczenia_w_planie = relationship("CwiczenieWPlanie", back_populates="plan")
    sesje = relationship("SesjaTreningowa", back_populates="plan")

class CwiczenieWPlanie(Base):
    __tablename__ = "cwiczenie_w_planie"

    id = Column(Integer, primary_key=True, index=True)
    plan_id = Column(Integer, ForeignKey("plan_treningowy.id"), nullable=False)
    cwiczenie_id = Column(Integer, ForeignKey("cwiczenie.id"), nullable=False)
    kolejnosc = Column(Integer, nullable=False)
    docelowe_serie = Column(Integer, nullable=False)
    docelowe_powtorzenia = Column(Integer, nullable=False)

    plan = relationship("PlanTreningowy", back_populates="cwiczenia_w_planie")
    cwiczenie = relationship("Cwiczenie")

class SesjaTreningowa(Base):
    __tablename__ = "sesja_treningowa"

    id = Column(Integer, primary_key=True, index=True)
    uzytkownik_id = Column(String, ForeignKey("uzytkownik.id"), nullable=False)
    plan_id = Column(Integer, ForeignKey("plan_treningowy.id"))
    czas_rozpoczecia = Column(DateTime, nullable=False)
    czas_zakonczenia = Column(DateTime, nullable=False)
    calkowita_objetosc = Column(Numeric(10, 2), default=0)
    notatki = Column(Text)

    uzytkownik = relationship("Uzytkownik", back_populates="sesje")
    plan = relationship("PlanTreningowy", back_populates="sesje")
    serie = relationship("SeriaTreningowa", back_populates="sesja")

class SeriaTreningowa(Base):
    __tablename__ = "seria_treningowa"

    id = Column(Integer, primary_key=True, index=True)
    sesja_id = Column(Integer, ForeignKey("sesja_treningowa.id"), nullable=False)
    cwiczenie_id = Column(Integer, ForeignKey("cwiczenie.id"), nullable=False)
    numer_serii = Column(Integer, nullable=False)
    powtorzenia = Column(Integer, nullable=False)
    obciazenie = Column(Numeric(6, 2), nullable=False)
    rpe = Column(Integer)

    sesja = relationship("SesjaTreningowa", back_populates="serie")
    cwiczenie = relationship("Cwiczenie")

class RekomendacjaAI(Base):
    __tablename__ = "rekomendacja_ai"

    id = Column(Integer, primary_key=True, index=True)
    uzytkownik_id = Column(String, ForeignKey("uzytkownik.id"), nullable=False)
    cwiczenie_id = Column(Integer, ForeignKey("cwiczenie.id"), nullable=False)
    sugerowane_obciazenie = Column(Numeric(6, 2))
    sugerowane_powtorzenia = Column(Integer)
    data_rekomendacji = Column(DateTime, nullable=False)
    czy_zaakceptowano = Column(Boolean)

class Odznaka(Base):
    __tablename__ = "odznaka"

    id = Column(Integer, primary_key=True, index=True)
    nazwa = Column(String(100), nullable=False)
    opis = Column(Text, nullable=False)
    ikona_url = Column(String(255), nullable=False)

class OdznakaUzytkownika(Base):
    __tablename__ = "odznaka_uzytkownika"

    id = Column(Integer, primary_key=True, index=True)
    uzytkownik_id = Column(String, ForeignKey("uzytkownik.id"), nullable=False)
    odznaka_id = Column(Integer, ForeignKey("odznaka.id"), nullable=False)
    data_odblokowania = Column(DateTime, nullable=False)

    uzytkownik = relationship("Uzytkownik", back_populates="odznaki")
    odznaka = relationship("Odznaka")