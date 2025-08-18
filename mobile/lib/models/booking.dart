import 'dart:convert';
import 'hotel.dart';

enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  checkedIn('checked_in'),
  checkedOut('checked_out'),
  cancelled('cancelled');

  const BookingStatus(this.value);
  final String value;

  static BookingStatus fromString(String value) {
    return BookingStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

class Booking {
  final int id;
  final int userId;
  final int hotelId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalPrice;
  final BookingStatus status;
  final DateTime createdAt;
  final Hotel hotel;

  Booking({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.hotel,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      userId: json['user_id'],
      hotelId: json['hotel_id'],
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      guests: json['guests'],
      totalPrice: json['total_price'].toDouble(),
      status: BookingStatus.fromString(json['status']),
      createdAt: DateTime.parse(json['created_at']),
      hotel: Hotel.fromJson(json['hotel']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'hotel_id': hotelId,
      'check_in_date': checkInDate.toIso8601String(),
      'check_out_date': checkOutDate.toIso8601String(),
      'guests': guests,
      'total_price': totalPrice,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'hotel': hotel.toMap(),
    };
  }

  String toJson() => jsonEncode(toMap());

  Booking copyWith({
    int? id,
    int? userId,
    int? hotelId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    double? totalPrice,
    BookingStatus? status,
    DateTime? createdAt,
    Hotel? hotel,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      guests: guests ?? this.guests,
      totalPrice: totalPrice ?? this.totalPrice,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      hotel: hotel ?? this.hotel,
    );
  }

  int get numberOfNights {
    return checkOutDate.difference(checkInDate).inDays;
  }

  bool get canCancel {
    return status == BookingStatus.pending || status == BookingStatus.confirmed;
  }

  bool get canCheckIn {
    return status == BookingStatus.confirmed;
  }

  bool get canCheckOut {
    return status == BookingStatus.checkedIn;
  }

  bool get canReview {
    return status == BookingStatus.checkedOut;
  }

  bool get isUpcoming {
    final now = DateTime.now();
    return checkInDate.isAfter(now) && 
           (status == BookingStatus.pending || status == BookingStatus.confirmed);
  }

  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(checkInDate) && 
           now.isBefore(checkOutDate) && 
           status == BookingStatus.checkedIn;
  }

  bool get isPast {
    final now = DateTime.now();
    return checkOutDate.isBefore(now) || status == BookingStatus.checkedOut;
  }
}