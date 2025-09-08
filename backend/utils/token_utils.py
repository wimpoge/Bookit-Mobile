import secrets
import string
from datetime import datetime, timedelta
from typing import Tuple

def generate_reset_token() -> str:
    """
    Generate a cryptographically secure reset token.
    
    Returns:
        str: A 32-character secure token
    """
    # Generate a secure random token using secrets module
    # This is cryptographically secure and suitable for password reset tokens
    alphabet = string.ascii_letters + string.digits
    token = ''.join(secrets.choice(alphabet) for _ in range(32))
    return token

def create_reset_token_with_expiry(expiry_hours: int = 1) -> Tuple[str, datetime]:
    """
    Create a reset token with expiry time.
    
    Args:
        expiry_hours (int): Number of hours until token expires (default: 1)
        
    Returns:
        Tuple[str, datetime]: Token and its expiry datetime
    """
    token = generate_reset_token()
    expiry = datetime.utcnow() + timedelta(hours=expiry_hours)
    return token, expiry

def is_token_expired(expiry_time: datetime) -> bool:
    """
    Check if a token has expired.
    
    Args:
        expiry_time (datetime): The expiry time to check
        
    Returns:
        bool: True if token has expired, False otherwise
    """
    return datetime.utcnow() > expiry_time