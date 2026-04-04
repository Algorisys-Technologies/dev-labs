from sqlmodel import Session, create_engine, SQLModel
import os

DATABASE_URL = "sqlite:///./backend/orders.db"

engine = create_engine(DATABASE_URL)

def create_db_and_tables():
    SQLModel.metadata.create_all(engine)

def get_session():
    with Session(engine) as session:
        yield session
