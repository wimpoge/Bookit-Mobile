import openai
import sqlite3
from typing import List, Dict, Any, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class AIService:
    def __init__(self, openai_api_key: str, db_path: str):
        self.client = openai.OpenAI(api_key=openai_api_key)
        self.db_path = db_path
        
    def get_hotel_context(self) -> str:
        """Get relevant hotel data for AI context"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            # Get hotels with basic info
            cursor.execute("""
                SELECT h.id, h.name, h.city, h.country, h.price_per_night, 
                       h.rating, h.amenities, h.description, h.address
                FROM hotels h
                WHERE h.is_active = 1
                ORDER BY h.rating DESC
                LIMIT 50
            """)
            hotels = cursor.fetchall()
            
            # Get booking statistics
            cursor.execute("""
                SELECT h.name, COUNT(b.id) as booking_count
                FROM hotels h
                LEFT JOIN bookings b ON h.id = b.hotel_id
                WHERE h.is_active = 1
                GROUP BY h.id, h.name
                ORDER BY booking_count DESC
                LIMIT 20
            """)
            popular_hotels = cursor.fetchall()
            
            conn.close()
            
            # Format context
            context = "Available Hotels Data:\n\n"
            
            for hotel in hotels:
                context += f"Hotel: {hotel[1]} (ID: {hotel[0]})\n"
                context += f"Location: {hotel[2]}, {hotel[3]}\n"
                context += f"Price: ${hotel[4]}/night\n"
                context += f"Rating: {hotel[5]}/5\n"
                context += f"Amenities: {hotel[6] or 'None listed'}\n"
                context += f"Description: {hotel[7] or 'No description'}\n"
                context += f"Address: {hotel[8] or 'Address not available'}\n"
                context += "---\n"
            
            context += "\nPopular Hotels (by booking count):\n"
            for hotel_name, count in popular_hotels:
                context += f"{hotel_name}: {count} bookings\n"
            
            return context
            
        except Exception as e:
            logger.error(f"Error getting hotel context: {e}")
            return "Error accessing hotel database."
    
    def save_ai_chat_history(self, user_id: int, message: str, response: str) -> bool:
        """Save AI chat history to database"""
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO ai_chat_history (user_id, message, ai_response, created_at)
                VALUES (?, ?, ?, ?)
            """, (user_id, message, response, datetime.utcnow()))
            
            conn.commit()
            conn.close()
            return True
            
        except Exception as e:
            logger.error(f"Error saving AI chat history: {e}")
            return False
    
    async def chat_with_ai(self, user_id: int, message: str) -> Dict[str, Any]:
        """Process user message with AI"""
        try:
            # Get hotel context
            hotel_context = self.get_hotel_context()
            
            # Create system prompt with few-shot examples
            system_prompt = f"""You are a friendly hotel booking assistant named BookIt AI. You help users with hotel bookings, recommendations, and travel information based on the provided hotel database.

PERSONALITY & STYLE:
- Be warm, friendly, and professional
- You can respond to greetings naturally but always guide the conversation toward hotels
- Use clear, conversational language without markdown formatting (**bold**, *italic*, etc.)
- Be enthusiastic about helping with hotel needs

CONVERSATION RULES:
1. You CAN respond to greetings and pleasantries, but always connect them to hotel services
2. For hotel-related questions, provide detailed, helpful answers based ONLY on the provided data
3. For completely unrelated topics (weather, politics, cooking, etc.), politely redirect to hotels
4. Include specific hotel names, prices, ratings, and amenities in recommendations
5. Be honest about data limitations

RESPONSE EXAMPLES:

User: "Hi"
Assistant: "Hello! Welcome to BookIt! I'm here to help you find the perfect hotel for your stay. Are you looking for accommodation in a specific city, or would you like me to show you our available hotels?"

User: "Good morning"
Assistant: "Good morning! I hope you're planning something exciting. I can help you find great hotels with the best prices and amenities. What kind of hotel experience are you looking for today?"

User: "What's the weather like?"
Assistant: "I can't help with weather information, but I can help you find hotels with great amenities for any weather! Are you looking for hotels with indoor pools, spas, or other facilities for your stay?"

User: "Show me hotels"
Assistant: "I'd be happy to show you our available hotels! Here are the options..." [then list hotels with details]

AVAILABLE HOTEL DATA:
{hotel_context}

Remember: Respond naturally and helpfully, avoid markdown formatting, and always focus on providing excellent hotel booking assistance!"""

            # Call OpenAI API
            response = self.client.chat.completions.create(
                model="gpt-4o-mini",
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": message}
                ],
                max_tokens=500,
                temperature=0.7
            )
            
            ai_response = response.choices[0].message.content.strip()
            
            # Save to history
            self.save_ai_chat_history(user_id, message, ai_response)
            
            return {
                "success": True,
                "response": ai_response,
                "message": "Response generated successfully"
            }
            
        except Exception as e:
            logger.error(f"Error in AI chat: {e}")
            return {
                "success": False,
                "response": "Sorry, I'm experiencing technical difficulties. Please try again later.",
                "message": str(e)
            }