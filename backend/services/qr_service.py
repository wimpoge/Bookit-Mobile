import qrcode
import io
import base64
from typing import Dict, Any
import uuid

class QRCodeService:
    def __init__(self):
        pass

    def generate_booking_qr_data(self, booking_id: str, user_id: str, hotel_id: str) -> str:
        """Generate QR code data for booking check-in"""
        qr_data = f"BOOKING_{booking_id}_{user_id}_{hotel_id}_{uuid.uuid4().hex[:8].upper()}"
        return qr_data

    def generate_qr_code_image(self, data: str) -> str:
        """Generate QR code image and return as base64 string"""
        try:
            qr = qrcode.QRCode(
                version=1,
                error_correction=qrcode.constants.ERROR_CORRECT_L,
                box_size=10,
                border=4,
            )
            qr.add_data(data)
            qr.make(fit=True)

            # Create QR code image
            img = qr.make_image(fill_color="black", back_color="white")

            # Convert to base64
            buffer = io.BytesIO()
            img.save(buffer, format='PNG')
            img_str = base64.b64encode(buffer.getvalue()).decode()

            return f"data:image/png;base64,{img_str}"
        except Exception as e:
            raise Exception(f"Error generating QR code: {str(e)}")

    def generate_booking_qr_code(self, booking_id: str, user_id: str, hotel_id: str) -> Dict[str, str]:
        """Generate both QR data and QR code image for booking"""
        try:
            qr_data = self.generate_booking_qr_data(booking_id, user_id, hotel_id)
            qr_image = self.generate_qr_code_image(qr_data)

            return {
                'qr_data': qr_data,
                'qr_image': qr_image
            }
        except Exception as e:
            raise Exception(f"Error generating booking QR code: {str(e)}")

    def verify_qr_data(self, qr_data: str) -> Dict[str, Any]:
        """Verify and extract information from QR code data"""
        try:
            if not qr_data.startswith("BOOKING_"):
                return {"valid": False, "reason": "Invalid QR code format"}

            parts = qr_data.split("_")
            if len(parts) < 5:
                return {"valid": False, "reason": "Invalid QR code structure"}

            return {
                "valid": True,
                "booking_id": parts[1],
                "user_id": parts[2],
                "hotel_id": parts[3],
                "verification_code": parts[4]
            }
        except Exception as e:
            return {"valid": False, "reason": f"Error verifying QR code: {str(e)}"}

# Singleton instance
qr_service = QRCodeService()