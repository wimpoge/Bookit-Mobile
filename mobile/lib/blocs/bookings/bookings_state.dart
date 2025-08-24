part of 'bookings_bloc.dart';

abstract class BookingsState extends Equatable {
  const BookingsState();

  @override
  List<Object> get props => [];

  String get message => '';
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
  final String _message;
  final Booking? booking;

  const BookingActionSuccess(this._message, [this.booking]);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message, if (booking != null) booking!];
}

class BookingCancelSuccess extends BookingsState {
  final String _message;

  const BookingCancelSuccess(this._message);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message];
}

class BookingCheckInSuccess extends BookingsState {
  final String _message;

  const BookingCheckInSuccess(this._message);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message];
}

class BookingCheckOutSuccess extends BookingsState {
  final String _message;

  const BookingCheckOutSuccess(this._message);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message];
}

class BookingConfirmSuccess extends BookingsState {
  final String _message;

  const BookingConfirmSuccess(this._message);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message];
}

class BookingRejectSuccess extends BookingsState {
  final String _message;

  const BookingRejectSuccess(this._message);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message];
}

class BookingsError extends BookingsState {
  final String _message;

  const BookingsError(this._message);

  @override
  String get message => _message;

  @override
  List<Object> get props => [_message];
}
