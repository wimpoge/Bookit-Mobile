import 'dart:convert';

class RoomType {
  final String id;
  final String hotelId;
  final String name;
  final String type;
  final String? description;
  final int maxGuests;
  final int maxAdults;
  final int maxChildren;
  final int? sizeSqm;
  final String? bedType;
  final int bedCount;
  final double basePrice;
  final double? weekendPrice;
  final double? holidayPrice;
  final int totalRooms;
  final List<String> amenities;
  final List<String> images;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomType({
    required this.id,
    required this.hotelId,
    required this.name,
    required this.type,
    this.description,
    required this.maxGuests,
    required this.maxAdults,
    this.maxChildren = 0,
    this.sizeSqm,
    this.bedType,
    this.bedCount = 1,
    required this.basePrice,
    this.weekendPrice,
    this.holidayPrice,
    required this.totalRooms,
    required this.amenities,
    required this.images,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RoomType.fromJson(Map<String, dynamic> json) {
    return RoomType(
      id: json['id'].toString(),
      hotelId: json['hotel_id'].toString(),
      name: json['name'],
      type: json['type'],
      description: json['description'],
      maxGuests: json['max_guests'],
      maxAdults: json['max_adults'],
      maxChildren: json['max_children'] ?? 0,
      sizeSqm: json['size_sqm'],
      bedType: json['bed_type'],
      bedCount: json['bed_count'] ?? 1,
      basePrice: json['base_price'].toDouble(),
      weekendPrice: json['weekend_price']?.toDouble(),
      holidayPrice: json['holiday_price']?.toDouble(),
      totalRooms: json['total_rooms'],
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'name': name,
      'type': type,
      'description': description,
      'max_guests': maxGuests,
      'max_adults': maxAdults,
      'max_children': maxChildren,
      'size_sqm': sizeSqm,
      'bed_type': bedType,
      'bed_count': bedCount,
      'base_price': basePrice,
      'weekend_price': weekendPrice,
      'holiday_price': holidayPrice,
      'total_rooms': totalRooms,
      'amenities': amenities,
      'images': images,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get formattedBedInfo {
    if (bedType != null && bedCount > 0) {
      return '$bedCount x $bedType bed${bedCount > 1 ? 's' : ''}';
    }
    return 'Bed information not available';
  }

  String get guestCapacityText {
    return 'Up to $maxGuests guest${maxGuests > 1 ? 's' : ''}';
  }

  String get sizeText {
    if (sizeSqm != null) {
      return '$sizeSqm m²';
    }
    return 'Size not specified';
  }

  bool get hasImages => images.isNotEmpty;
  String get mainImage => hasImages ? images.first : '';
}