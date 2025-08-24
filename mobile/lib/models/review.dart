import 'dart:convert';
import 'user.dart';

class Review {
  final int id;
  final int? userId;
  final int? hotelId;
  final int bookingId;
  final int rating;
  final String? comment;
  final String? ownerReply;
  final DateTime createdAt;
  final User? user;
  final ReviewHotel? hotel;
  final bool? needsReply;

  Review({
    required this.id,
    this.userId,
    this.hotelId,
    required this.bookingId,
    required this.rating,
    this.comment,
    this.ownerReply,
    required this.createdAt,
    this.user,
    this.hotel,
    this.needsReply,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      userId: json['user_id'],
      hotelId: json['hotel_id'],
      bookingId: json['booking_id'],
      rating: json['rating'],
      comment: json['comment'],
      ownerReply: json['owner_reply'],
      createdAt: DateTime.parse(json['created_at']),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      hotel: json['hotel'] != null ? ReviewHotel.fromJson(json['hotel']) : null,
      needsReply: json['needs_reply'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'hotel_id': hotelId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'owner_reply': ownerReply,
      'created_at': createdAt.toIso8601String(),
      'user': user?.toMap(),
      'hotel': hotel?.toMap(),
      'needs_reply': needsReply,
    };
  }

  String toJson() => jsonEncode(toMap());

  Review copyWith({
    int? id,
    int? userId,
    int? hotelId,
    int? bookingId,
    int? rating,
    String? comment,
    String? ownerReply,
    DateTime? createdAt,
    User? user,
    ReviewHotel? hotel,
    bool? needsReply,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      hotelId: hotelId ?? this.hotelId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      ownerReply: ownerReply ?? this.ownerReply,
      createdAt: createdAt ?? this.createdAt,
      user: user ?? this.user,
      hotel: hotel ?? this.hotel,
      needsReply: needsReply ?? this.needsReply,
    );
  }

  bool get hasOwnerReply => ownerReply != null && ownerReply!.isNotEmpty;
  
  String get ratingText {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }
}

class ReviewHotel {
  final int id;
  final String name;
  final String location;
  final String? imageUrl;

  ReviewHotel({
    required this.id,
    required this.name,
    required this.location,
    this.imageUrl,
  });

  factory ReviewHotel.fromJson(Map<String, dynamic> json) {
    return ReviewHotel(
      id: json['id'],
      name: json['name'],
      location: json['location'],
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'image_url': imageUrl,
    };
  }
}