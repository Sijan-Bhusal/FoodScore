from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
from app.config import DATABASE_URL

if not DATABASE_URL:
	raise RuntimeError(
		"DATABASE_URL is not set. Add it to backend/.env, for example: "
		"postgresql://user:password@localhost:5432/dbname"
	)

engine = create_engine(DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()
