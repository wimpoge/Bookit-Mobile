from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./hotel_booking.db")

engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def init_database():
    Base.metadata.create_all(bind=engine)
    
    with engine.connect() as conn:
        try:
            result = conn.execute(text("PRAGMA table_info(chat_messages)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'is_from_owner' not in columns:
                conn.execute(text("ALTER TABLE chat_messages ADD COLUMN is_from_owner BOOLEAN DEFAULT FALSE"))
                conn.commit()
                print("Added is_from_owner column to chat_messages")
                
            if 'is_read' not in columns:
                conn.execute(text("ALTER TABLE chat_messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE"))
                conn.commit()
                print("Added is_read column to chat_messages")
                
            if 'updated_at' not in columns:
                conn.execute(text("ALTER TABLE chat_messages ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                print("Added updated_at column to chat_messages")
                
        except Exception as e:
            print(f"Database initialization note: {e}")
            
        try:
            result = conn.execute(text("PRAGMA table_info(payments)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'updated_at' not in columns:
                conn.execute(text("ALTER TABLE payments ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                print("Added updated_at column to payments")
                
        except Exception as e:
            print(f"Payments table update note: {e}")
            
        try:
            result = conn.execute(text("PRAGMA table_info(payment_methods)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'updated_at' not in columns:
                conn.execute(text("ALTER TABLE payment_methods ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                print("Added updated_at column to payment_methods")
                
        except Exception as e:
            print(f"Payment methods table update note: {e}")
            
        try:
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_chat_messages_hotel_user 
                ON chat_messages(hotel_id, user_id)
            """))
            conn.execute(text("""
                CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at 
                ON chat_messages(created_at)
            """))
            conn.commit()
            print("Database indexes created successfully")
        except Exception as e:
            print(f"Index creation note: {e}")

if __name__ == "__main__":
    init_database()
    print("Database initialization completed")