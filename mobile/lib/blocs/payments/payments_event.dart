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
