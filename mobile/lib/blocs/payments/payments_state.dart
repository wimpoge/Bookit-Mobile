part of 'payments_bloc.dart';

abstract class PaymentsState extends Equatable {
  const PaymentsState();

  @override
  List<Object> get props => [];
}

class PaymentsInitial extends PaymentsState {}

class PaymentMethodsLoading extends PaymentsState {}

class PaymentMethodsLoaded extends PaymentsState {
  final List<PaymentMethod> paymentMethods;

  const PaymentMethodsLoaded(this.paymentMethods);

  @override
  List<Object> get props => [paymentMethods];
}

class PaymentMethodActionLoading extends PaymentsState {}

class PaymentMethodActionSuccess extends PaymentsState {
  final String message;

  const PaymentMethodActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class PaymentProcessLoading extends PaymentsState {}

class PaymentProcessSuccess extends PaymentsState {
  final String message;
  final Payment payment;

  const PaymentProcessSuccess(this.message, this.payment);

  @override
  List<Object> get props => [message, payment];
}

class PaymentsLoading extends PaymentsState {}

class PaymentsLoaded extends PaymentsState {
  final List<Payment> payments;

  const PaymentsLoaded(this.payments);

  @override
  List<Object> get props => [payments];
}

class PaymentsError extends PaymentsState {
  final String message;

  const PaymentsError(this.message);

  @override
  List<Object> get props => [message];
}
