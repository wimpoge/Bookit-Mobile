import 'dart:convert';
import 'hotel.dart';
import 'review.dart';

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
  final String id;
  final String userId;
  final String hotelId;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final int guests;
  final double totalPrice;
  final BookingStatus status;
  final String? qrCode;
  final bool hasReview;
  final DateTime createdAt;
  final Hotel hotel;
  final Review? review;

  Booking({
    required this.id,
    required this.userId,
    required this.hotelId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.guests,
    required this.totalPrice,
    required this.status,
    this.qrCode,
    this.hasReview = false,
    required this.createdAt,
    required this.hotel,
    this.review,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      hotelId: json['hotel_id'].toString(),
      checkInDate: DateTime.parse(json['check_in_date']),
      checkOutDate: DateTime.parse(json['check_out_date']),
      guests: json['guests'],
      totalPrice: json['total_price'].toDouble(),
      status: BookingStatus.fromString(json['status']),
      qrCode: json['qr_code'],
      hasReview: json['has_review'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      hotel: Hotel.fromJson(json['hotel']),
      review: json['review'] != null ? Review.fromJson(json['review']) : null,
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
      'qr_code': qrCode,
      'has_review': hasReview,
      'created_at': createdAt.toIso8601String(),
      'review': review?.toMap(),
      'hotel': hotel.toMap(),
    };
  }

  String toJson() => jsonEncode(toMap());

  Booking copyWith({
    String? id,
    String? userId,
    String? hotelId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    int? guests,
    double? totalPrice,
    BookingStatus? status,
    String? qrCode,
    bool? hasReview,
    DateTime? createdAt,
    Hotel? hotel,
    Review? review,
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
      qrCode: qrCode ?? this.qrCode,
      hasReview: hasReview ?? this.hasReview,
      createdAt: createdAt ?? this.createdAt,
      hotel: hotel ?? this.hotel,
      review: review ?? this.review,
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
    return status == BookingStatus.checkedOut && !hasReview;
  }

  // FIXED: Better date comparison logic for upcoming bookings
  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkInDay =
        DateTime(checkInDate.year, checkInDate.month, checkInDate.day);

    return checkInDay.isAfter(today) &&
        (status == BookingStatus.pending || status == BookingStatus.confirmed);
  }

  bool get isCurrent {
    // Current bookings are pending, confirmed, or checked-in bookings
    // These are active bookings that need attention from the user
    return status == BookingStatus.pending || 
           status == BookingStatus.confirmed || 
           status == BookingStatus.checkedIn;
  }

  bool get isPast {
    // Past bookings are only checked-out bookings
    // These are completed stays that are part of history
    return status == BookingStatus.checkedOut;
  }
}
