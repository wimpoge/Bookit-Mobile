part of 'bookings_bloc.dart';

abstract class BookingsEvent extends Equatable {
  const BookingsEvent();

  @override
  List<Object> get props => [];
}

class BookingsLoadEvent extends BookingsEvent {}

class BookingDetailLoadEvent extends BookingsEvent {
  final String bookingId;

  const BookingDetailLoadEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingCreateEvent extends BookingsEvent {
  final Map<String, dynamic> bookingData;

  const BookingCreateEvent({required this.bookingData});

  @override
  List<Object> get props => [bookingData];
}

class BookingUpdateEvent extends BookingsEvent {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const BookingUpdateEvent({
    required this.bookingId,
    required this.bookingData,
  });

  @override
  List<Object> get props => [bookingId, bookingData];
}

class BookingCancelEvent extends BookingsEvent {
  final String bookingId;

  const BookingCancelEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class OwnerBookingsLoadEvent extends BookingsEvent {}

class BookingCheckInEvent extends BookingsEvent {
  final String bookingId;

  const BookingCheckInEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingCheckOutEvent extends BookingsEvent {
  final String bookingId;

  const BookingCheckOutEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingConfirmEvent extends BookingsEvent {
  final String bookingId;

  const BookingConfirmEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingRejectEvent extends BookingsEvent {
  final String bookingId;

  const BookingRejectEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingSelfCheckInEvent extends BookingsEvent {
  final String bookingId;

  const BookingSelfCheckInEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}

class BookingSelfCheckOutEvent extends BookingsEvent {
  final String bookingId;

  const BookingSelfCheckOutEvent({required this.bookingId});

  @override
  List<Object> get props => [bookingId];
}
