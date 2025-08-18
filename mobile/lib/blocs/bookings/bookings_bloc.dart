import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/booking.dart';

part 'bookings_event.dart';
part 'bookings_state.dart';

class BookingsBloc extends Bloc<BookingsEvent, BookingsState> {
  final ApiService _apiService;

  BookingsBloc(this._apiService) : super(BookingsInitial()) {
    on<BookingsLoadEvent>(_onLoadBookings);
    on<BookingDetailLoadEvent>(_onLoadBookingDetail);
    on<BookingCreateEvent>(_onCreateBooking);
    on<BookingUpdateEvent>(_onUpdateBooking);
    on<BookingCancelEvent>(_onCancelBooking);
    on<OwnerBookingsLoadEvent>(_onLoadOwnerBookings);
    on<BookingCheckInEvent>(_onCheckInBooking);
    on<BookingCheckOutEvent>(_onCheckOutBooking);
  }

  Future<void> _onLoadBookings(BookingsLoadEvent event, Emitter<BookingsState> emit) async {
    emit(BookingsLoading());
    
    try {
      final bookings = await _apiService.getUserBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadBookingDetail(BookingDetailLoadEvent event, Emitter<BookingsState> emit) async {
    emit(BookingDetailLoading());
    
    try {
      final booking = await _apiService.getBooking(event.bookingId);
      emit(BookingDetailLoaded(booking));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCreateBooking(BookingCreateEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());
    
    try {
      final booking = await _apiService.createBooking(event.bookingData);
      emit(BookingActionSuccess('Booking created successfully', booking));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onUpdateBooking(BookingUpdateEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());
    
    try {
      final booking = await _apiService.updateBooking(event.bookingId, event.bookingData);
      emit(BookingActionSuccess('Booking updated successfully', booking));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(BookingCancelEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());
    
    try {
      await _apiService.cancelBooking(event.bookingId);
      emit(BookingCancelSuccess('Booking cancelled successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadOwnerBookings(OwnerBookingsLoadEvent event, Emitter<BookingsState> emit) async {
    emit(BookingsLoading());
    
    try {
      final bookings = await _apiService.getHotelBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCheckInBooking(BookingCheckInEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());
    
    try {
      await _apiService.checkInBooking(event.bookingId);
      emit(BookingCancelSuccess('Guest checked in successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCheckOutBooking(BookingCheckOutEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());
    
    try {
      await _apiService.checkOutBooking(event.bookingId);
      emit(BookingCancelSuccess('Guest checked out successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }
}