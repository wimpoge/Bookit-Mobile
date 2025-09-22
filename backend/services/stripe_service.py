import stripe
import os
from typing import Dict, Any, Optional
from dotenv import load_dotenv

load_dotenv()

stripe.api_key = os.getenv("STRIPE_SECRET_KEY")

class StripeService:
    def __init__(self):
        self.api_key = os.getenv("STRIPE_SECRET_KEY")
        self.publishable_key = os.getenv("STRIPE_PUBLISHABLE_KEY")
        if not self.api_key:
            raise ValueError("STRIPE_SECRET_KEY not found in environment variables")
        stripe.api_key = self.api_key

    def create_customer(self, email: str, name: str) -> str:
        """Create a Stripe customer"""
        try:
            customer = stripe.Customer.create(
                email=email,
                name=name,
            )
            return customer.id
        except stripe.error.StripeError as e:
            raise Exception(f"Error creating Stripe customer: {str(e)}")

    def create_setup_intent(self, customer_id: str) -> Dict[str, Any]:
        """Create a SetupIntent for saving payment method"""
        try:
            setup_intent = stripe.SetupIntent.create(
                customer=customer_id,
                usage='off_session',
                payment_method_types=['card'],
            )
            return {
                'client_secret': setup_intent.client_secret,
                'setup_intent_id': setup_intent.id
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error creating setup intent: {str(e)}")

    def attach_payment_method(self, payment_method_id: str, customer_id: str) -> Dict[str, Any]:
        """Attach payment method to customer"""
        try:
            payment_method = stripe.PaymentMethod.attach(
                payment_method_id,
                customer=customer_id,
            )
            return {
                'id': payment_method.id,
                'type': payment_method.type,
                'card': payment_method.card if payment_method.card else None,
                'last4': payment_method.card.last4 if payment_method.card else None,
                'brand': payment_method.card.brand if payment_method.card else None,
                'exp_month': payment_method.card.exp_month if payment_method.card else None,
                'exp_year': payment_method.card.exp_year if payment_method.card else None,
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error attaching payment method: {str(e)}")

    def list_payment_methods(self, customer_id: str) -> list:
        """List customer payment methods"""
        try:
            payment_methods = stripe.PaymentMethod.list(
                customer=customer_id,
                type="card",
            )
            return [{
                'id': pm.id,
                'type': pm.type,
                'card': {
                    'last4': pm.card.last4,
                    'brand': pm.card.brand,
                    'exp_month': pm.card.exp_month,
                    'exp_year': pm.card.exp_year,
                }
            } for pm in payment_methods.data]
        except stripe.error.StripeError as e:
            raise Exception(f"Error listing payment methods: {str(e)}")

    def detach_payment_method(self, payment_method_id: str) -> bool:
        """Detach payment method from customer"""
        try:
            stripe.PaymentMethod.detach(payment_method_id)
            return True
        except stripe.error.StripeError as e:
            raise Exception(f"Error detaching payment method: {str(e)}")

    def create_payment_intent(self,
                            amount: int,  # in cents
                            currency: str = "usd",
                            customer_id: Optional[str] = None,
                            payment_method_id: Optional[str] = None,
                            confirm: bool = False,
                            description: Optional[str] = None,
                            booking_id: Optional[str] = None) -> Dict[str, Any]:
        """Create a PaymentIntent with 1-minute timeout for booking payments"""
        try:
            intent_data = {
                'amount': amount,
                'currency': currency,
                'automatic_payment_methods': {
                    'enabled': True,
                },
            }

            if customer_id:
                intent_data['customer'] = customer_id

            if payment_method_id:
                intent_data['payment_method'] = payment_method_id

            if confirm:
                intent_data['confirm'] = True
                intent_data['return_url'] = 'https://your-website.com/return'

            if description:
                intent_data['description'] = description

            # Add metadata for booking tracking
            if booking_id:
                intent_data['metadata'] = {
                    'booking_id': booking_id,
                    'timeout_minutes': '1'  # 1-minute timeout
                }

            payment_intent = stripe.PaymentIntent.create(**intent_data)

            return {
                'id': payment_intent.id,
                'client_secret': payment_intent.client_secret,
                'status': payment_intent.status,
                'amount': payment_intent.amount,
                'currency': payment_intent.currency,
                'metadata': payment_intent.metadata
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error creating payment intent: {str(e)}")

    def confirm_payment_intent(self, payment_intent_id: str, payment_method_id: str) -> Dict[str, Any]:
        """Confirm a PaymentIntent"""
        try:
            payment_intent = stripe.PaymentIntent.confirm(
                payment_intent_id,
                payment_method=payment_method_id,
            )
            return {
                'id': payment_intent.id,
                'status': payment_intent.status,
                'amount': payment_intent.amount,
                'currency': payment_intent.currency,
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error confirming payment intent: {str(e)}")

    def retrieve_payment_intent(self, payment_intent_id: str) -> Dict[str, Any]:
        """Retrieve a PaymentIntent"""
        try:
            payment_intent = stripe.PaymentIntent.retrieve(payment_intent_id)
            return {
                'id': payment_intent.id,
                'status': payment_intent.status,
                'amount': payment_intent.amount,
                'currency': payment_intent.currency,
                'charges': payment_intent.charges.data if payment_intent.charges else []
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error retrieving payment intent: {str(e)}")

    def create_refund(self, payment_intent_id: str, amount: Optional[int] = None, reason: Optional[str] = None) -> Dict[str, Any]:
        """Create a refund"""
        try:
            refund_data = {'payment_intent': payment_intent_id}
            if amount:
                refund_data['amount'] = amount
            if reason:
                refund_data['reason'] = reason

            refund = stripe.Refund.create(**refund_data)
            return {
                'id': refund.id,
                'status': refund.status,
                'amount': refund.amount,
                'currency': refund.currency,
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error creating refund: {str(e)}")

    def get_publishable_key(self) -> str:
        """Get Stripe publishable key for frontend"""
        return self.publishable_key

    def cancel_payment_intent(self, payment_intent_id: str) -> Dict[str, Any]:
        """Cancel a PaymentIntent (if not already succeeded)"""
        try:
            payment_intent = stripe.PaymentIntent.cancel(payment_intent_id)
            return {
                'id': payment_intent.id,
                'status': payment_intent.status,
                'amount': payment_intent.amount,
                'currency': payment_intent.currency,
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error cancelling payment intent: {str(e)}")

    def create_booking_payment_intent(self,
                                    booking_id: str,
                                    amount: int,
                                    customer_id: str,
                                    description: str) -> Dict[str, Any]:
        """Create a PaymentIntent specifically for booking payments with 1-minute timeout"""
        try:
            payment_intent = stripe.PaymentIntent.create(
                amount=amount,
                currency="usd",
                customer=customer_id,
                automatic_payment_methods={'enabled': True},
                description=description,
                metadata={
                    'booking_id': booking_id,
                    'timeout_minutes': '1',
                    'payment_type': 'booking'
                }
            )

            return {
                'id': payment_intent.id,
                'client_secret': payment_intent.client_secret,
                'status': payment_intent.status,
                'amount': payment_intent.amount,
                'currency': payment_intent.currency,
                'metadata': payment_intent.metadata
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error creating booking payment intent: {str(e)}")

    def create_booking_payment_link(self,
                                  booking_id: str,
                                  amount: int,
                                  description: str,
                                  hotel_name: str,
                                  customer_email: str) -> Dict[str, Any]:
        """Create a Stripe Payment Link for booking with hosted checkout"""
        try:
            # Create a product first
            product = stripe.Product.create(
                name=f"Hotel Booking - {hotel_name}",
                description=description,
            )

            # Create a price for this booking
            price = stripe.Price.create(
                unit_amount=amount,
                currency="usd",
                product=product.id,
            )

            # Create payment link
            payment_link = stripe.PaymentLink.create(
                line_items=[{
                    'price': price.id,
                    'quantity': 1,
                }],
                metadata={
                    'booking_id': booking_id,
                    'payment_type': 'booking'
                },
                after_completion={
                    'type': 'redirect',
                    'redirect': {
                        'url': f'http://localhost:3000/payment-success?booking_id={booking_id}&session_id={{CHECKOUT_SESSION_ID}}'
                    }
                },
                allow_promotion_codes=False,
                billing_address_collection='auto',
                customer_creation='always',
                payment_method_types=['card'],
                shipping_address_collection=None,
                invoice_creation={
                    'enabled': True,
                    'invoice_data': {
                        'description': description,
                        'metadata': {
                            'booking_id': booking_id
                        },
                        'footer': 'Thank you for your booking!'
                    }
                }
            )

            return {
                'payment_link_id': payment_link.id,
                'url': payment_link.url,
                'active': payment_link.active,
                'metadata': payment_link.metadata
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error creating payment link: {str(e)}")

    def retrieve_payment_link(self, payment_link_id: str) -> Dict[str, Any]:
        """Retrieve a Payment Link"""
        try:
            payment_link = stripe.PaymentLink.retrieve(payment_link_id)
            return {
                'id': payment_link.id,
                'url': payment_link.url,
                'active': payment_link.active,
                'metadata': payment_link.metadata
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error retrieving payment link: {str(e)}")

    def get_payment_link_sessions(self, payment_link_id: str) -> Dict[str, Any]:
        """Get checkout sessions for a payment link"""
        try:
            sessions = stripe.checkout.Session.list(
                payment_link=payment_link_id,
                limit=10
            )
            return {
                'sessions': [{
                    'id': session.id,
                    'status': session.status,
                    'payment_status': session.payment_status,
                    'amount_total': session.amount_total,
                    'customer_email': session.customer_email,
                    'metadata': session.metadata
                } for session in sessions.data]
            }
        except stripe.error.StripeError as e:
            raise Exception(f"Error retrieving payment link sessions: {str(e)}")

# Singleton instance
stripe_service = StripeService()