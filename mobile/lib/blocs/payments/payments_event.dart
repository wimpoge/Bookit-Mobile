part of 'payments_bloc.dart';

abstract class PaymentsEvent extends Equatable {
  const PaymentsEvent();

  @override
  List<Object> get props => [];
}

class PaymentMethodsLoadEvent extends PaymentsEvent {}

class PaymentMethodAddEvent extends PaymentsEvent {
  final Map<String, dynamic> paymentMethodData;

  const PaymentMethodAddEvent({required this.paymentMethodData});

  @override
  List<Object> get props => [paymentMethodData];
}

class PaymentMethodUpdateEvent extends PaymentsEvent {
  final String methodId;
  final Map<String, dynamic> paymentMethodData;

  const PaymentMethodUpdateEvent({
    required this.methodId,
    required this.paymentMethodData,
  });

  @override
  List<Object> get props => [methodId, paymentMethodData];
}

class PaymentMethodDeleteEvent extends PaymentsEvent {
  final String methodId;

  const PaymentMethodDeleteEvent({required this.methodId});

  @override
  List<Object> get props => [methodId];
}

class PaymentProcessEvent extends PaymentsEvent {
  final Map<String, dynamic> paymentData;

  const PaymentProcessEvent({required this.paymentData});

  @override
  List<Object> get props => [paymentData];
}

class PaymentsLoadEvent extends PaymentsEvent {}

// Stripe-specific events
class StripeSetupIntentCreateEvent extends PaymentsEvent {}

class StripePaymentMethodAddEvent extends PaymentsEvent {
  final String paymentMethodId;
  final bool isDefault;

  const StripePaymentMethodAddEvent({
    required this.paymentMethodId,
    this.isDefault = false,
  });

  @override
  List<Object> get props => [paymentMethodId, isDefault];
}

class StripePaymentIntentCreateEvent extends PaymentsEvent {
  final String bookingId;
  final String paymentMethodId;
  final bool confirm;

  const StripePaymentIntentCreateEvent({
    required this.bookingId,
    required this.paymentMethodId,
    this.confirm = true,
  });

  @override
  List<Object> get props => [bookingId, paymentMethodId, confirm];
}

class StripePaymentConfirmEvent extends PaymentsEvent {
  final String paymentIntentId;

  const StripePaymentConfirmEvent({required this.paymentIntentId});

  @override
  List<Object> get props => [paymentIntentId];
}
