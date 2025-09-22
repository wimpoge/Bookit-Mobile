import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/payment.dart';

part 'payments_event.dart';
part 'payments_state.dart';

class PaymentsBloc extends Bloc<PaymentsEvent, PaymentsState> {
  final ApiService _apiService;
  
  ApiService get apiService => _apiService;

  PaymentsBloc(this._apiService) : super(PaymentsInitial()) {
    on<PaymentMethodsLoadEvent>(_onLoadPaymentMethods);
    on<PaymentMethodAddEvent>(_onAddPaymentMethod);
    on<PaymentMethodUpdateEvent>(_onUpdatePaymentMethod);
    on<PaymentMethodDeleteEvent>(_onDeletePaymentMethod);
    on<PaymentProcessEvent>(_onProcessPayment);
    on<PaymentsLoadEvent>(_onLoadPayments);
  }

  Future<void> _onLoadPaymentMethods(PaymentMethodsLoadEvent event, Emitter<PaymentsState> emit) async {
    emit(PaymentMethodsLoading());
    
    try {
      final paymentMethods = await _apiService.getPaymentMethods();
      emit(PaymentMethodsLoaded(paymentMethods));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onAddPaymentMethod(PaymentMethodAddEvent event, Emitter<PaymentsState> emit) async {
    emit(PaymentMethodActionLoading());
    
    try {
      final paymentMethod = await _apiService.addPaymentMethod(event.paymentMethodData);
      emit(PaymentMethodActionSuccess('Payment method added successfully'));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onUpdatePaymentMethod(PaymentMethodUpdateEvent event, Emitter<PaymentsState> emit) async {
    emit(PaymentMethodActionLoading());
    
    try {
      final paymentMethod = await _apiService.updatePaymentMethod(event.methodId, event.paymentMethodData);
      emit(PaymentMethodActionSuccess('Payment method updated successfully'));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onDeletePaymentMethod(PaymentMethodDeleteEvent event, Emitter<PaymentsState> emit) async {
    emit(PaymentMethodActionLoading());
    
    try {
      await _apiService.deletePaymentMethod(event.methodId);
      emit(PaymentMethodActionSuccess('Payment method deleted successfully'));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onProcessPayment(PaymentProcessEvent event, Emitter<PaymentsState> emit) async {
    emit(PaymentProcessLoading());
    
    try {
      final payment = await _apiService.processPayment(event.paymentData);
      emit(PaymentProcessSuccess('Payment processed successfully', payment));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }

  Future<void> _onLoadPayments(PaymentsLoadEvent event, Emitter<PaymentsState> emit) async {
    emit(PaymentsLoading());
    
    try {
      final payments = await _apiService.getUserPayments();
      emit(PaymentsLoaded(payments));
    } catch (e) {
      emit(PaymentsError(e.toString()));
    }
  }
}