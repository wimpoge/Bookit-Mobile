part of 'bookings_bloc.dart';

abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object> get props => [];
}

class BookingsInitial extends BookingsState {}

class BookingsLoading extends BookingsState {}

class BookingsLoaded extends BookingsState {
  final List<Booking> bookings;

  const BookingsLoaded(this.bookings);

  @override
  List<Object> get props => [bookings];
}

class BookingDetailLoading extends BookingsState {}

class BookingDetailLoaded extends BookingsState {
  final Booking booking;

  const BookingDetailLoaded(this.booking);

  @override
  List<Object> get props => [booking];
}

class BookingActionLoading extends BookingsState {}

class BookingActionSuccess extends BookingsState {
  final String message;
  final Booking? booking;

  const BookingActionSuccess(this.message, [this.booking]);

  @override
  List<Object> get props => [message, if (booking != null) booking!];
}

class BookingCancelSuccess extends BookingsState {
  final String message;

  const BookingCancelSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class BookingsError extends BookingsState {
  final String message;

  const BookingsError(this.message);

  @override
  List<Object> get props => [message];
}