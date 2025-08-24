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
    on<BookingSelfCheckInEvent>(_onSelfCheckInBooking);
    on<BookingSelfCheckOutEvent>(_onSelfCheckOutBooking);
    on<BookingConfirmEvent>(_onConfirmBooking);
    on<BookingRejectEvent>(_onRejectBooking);
  }

  Future<void> _onLoadBookings(
      BookingsLoadEvent event, Emitter<BookingsState> emit) async {
    emit(BookingsLoading());

    try {
      final bookings = await _apiService.getUserBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadBookingDetail(
      BookingDetailLoadEvent event, Emitter<BookingsState> emit) async {
    emit(BookingDetailLoading());

    try {
      final booking = await _apiService.getBooking(event.bookingId);
      emit(BookingDetailLoaded(booking));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCreateBooking(
      BookingCreateEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      final booking = await _apiService.createBooking(event.bookingData);
      emit(BookingActionSuccess('Booking created successfully', booking));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onUpdateBooking(
      BookingUpdateEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      final booking =
          await _apiService.updateBooking(event.bookingId, event.bookingData);
      emit(BookingActionSuccess('Booking updated successfully', booking));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCancelBooking(
      BookingCancelEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.cancelBooking(event.bookingId);
      emit(BookingCancelSuccess('Booking cancelled successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onLoadOwnerBookings(
      OwnerBookingsLoadEvent event, Emitter<BookingsState> emit) async {
    emit(BookingsLoading());

    try {
      final bookings = await _apiService.getHotelBookings();
      emit(BookingsLoaded(bookings));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCheckInBooking(
      BookingCheckInEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.checkInBooking(event.bookingId);
      emit(BookingCheckInSuccess('Guest checked in successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onCheckOutBooking(
      BookingCheckOutEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.checkOutBooking(event.bookingId);
      emit(BookingCheckOutSuccess('Guest checked out successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onSelfCheckInBooking(
      BookingSelfCheckInEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.selfCheckInBooking(event.bookingId);
      emit(BookingCheckInSuccess('Successfully checked in'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onSelfCheckOutBooking(
      BookingSelfCheckOutEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.selfCheckOutBooking(event.bookingId);
      emit(BookingCheckOutSuccess('Successfully checked out'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onConfirmBooking(
      BookingConfirmEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.confirmBooking(event.bookingId);
      emit(BookingConfirmSuccess('Booking confirmed successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }

  Future<void> _onRejectBooking(
      BookingRejectEvent event, Emitter<BookingsState> emit) async {
    emit(BookingActionLoading());

    try {
      await _apiService.rejectBooking(event.bookingId);
      emit(BookingRejectSuccess('Booking rejected successfully'));
    } catch (e) {
      emit(BookingsError(e.toString()));
    }
  }
}
