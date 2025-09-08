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
                
            if 'is_read' not in columns:
                conn.execute(text("ALTER TABLE chat_messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE"))
                conn.commit()
                
            if 'updated_at' not in columns:
                conn.execute(text("ALTER TABLE chat_messages ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                
        except Exception as e:
            pass
            
        # Add AI chat history table
        try:
            conn.execute(text("""
                CREATE TABLE IF NOT EXISTS ai_chat_history (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    user_id INTEGER NOT NULL,
                    message TEXT NOT NULL,
                    ai_response TEXT NOT NULL,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (user_id) REFERENCES users (id)
                )
            """))
            conn.commit()
        except Exception as e:
            pass
            
        try:
            result = conn.execute(text("PRAGMA table_info(payments)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'updated_at' not in columns:
                conn.execute(text("ALTER TABLE payments ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                
        except Exception as e:
            pass
            
        try:
            result = conn.execute(text("PRAGMA table_info(payment_methods)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'updated_at' not in columns:
                conn.execute(text("ALTER TABLE payment_methods ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP"))
                conn.commit()
                
        except Exception as e:
            pass
            
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
        except Exception as e:
            pass
            
        # Add discount columns to hotels table
        try:
            result = conn.execute(text("PRAGMA table_info(hotels)"))
            columns = [row[1] for row in result.fetchall()]
            
            if 'discount_percentage' not in columns:
                conn.execute(text("ALTER TABLE hotels ADD COLUMN discount_percentage DECIMAL(5,2) DEFAULT 0.0"))
                conn.commit()
                
            if 'discount_price' not in columns:
                conn.execute(text("ALTER TABLE hotels ADD COLUMN discount_price DECIMAL(10,2)"))
                conn.commit()
                
            if 'is_deal' not in columns:
                conn.execute(text("ALTER TABLE hotels ADD COLUMN is_deal BOOLEAN DEFAULT FALSE"))
                conn.commit()
                
        except Exception as e:
            pass

if __name__ == "__main__":
    init_database()
