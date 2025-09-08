import 'dart:convert';
import 'room_type.dart';

class Hotel {
  final String id;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String country;
  final double pricePerNight;
  final double? discountPercentage;
  final double? discountPrice;
  final bool isDeal;
  final double rating;
  final List<String> amenities;
  final List<String> images;
  final int totalRooms;
  final int availableRooms;
  final String ownerId;
  final String? ownerName;
  final List<RoomType> roomTypes;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  Hotel({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    required this.city,
    required this.country,
    required this.pricePerNight,
    this.discountPercentage,
    this.discountPrice,
    this.isDeal = false,
    required this.rating,
    required this.amenities,
    required this.images,
    required this.totalRooms,
    required this.availableRooms,
    required this.ownerId,
    this.ownerName,
    this.roomTypes = const [],
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'].toString(),
      name: json['name'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      pricePerNight: json['price_per_night'].toDouble(),
      discountPercentage: json['discount_percentage']?.toDouble(),
      discountPrice: json['discount_price']?.toDouble(),
      isDeal: json['is_deal'] ?? false,
      rating: json['rating'].toDouble(),
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      totalRooms: json['total_rooms'],
      availableRooms: json['available_rooms'],
      ownerId: json['owner_id'].toString(),
      ownerName: json['owner_name'],
      roomTypes: (json['room_types'] as List<dynamic>?)
          ?.map((roomType) => RoomType.fromJson(roomType))
          .toList() ?? [],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'country': country,
      'price_per_night': pricePerNight,
      'discount_percentage': discountPercentage,
      'discount_price': discountPrice,
      'is_deal': isDeal,
      'rating': rating,
      'amenities': amenities,
      'images': images,
      'total_rooms': totalRooms,
      'available_rooms': availableRooms,
      'owner_id': ownerId,
      'owner_name': ownerName,
      'room_types': roomTypes.map((rt) => rt.toJson()).toList(),
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  Hotel copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? country,
    double? pricePerNight,
    double? discountPercentage,
    double? discountPrice,
    bool? isDeal,
    double? rating,
    List<String>? amenities,
    List<String>? images,
    int? totalRooms,
    int? availableRooms,
    String? ownerId,
    List<RoomType>? roomTypes,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return Hotel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      country: country ?? this.country,
      pricePerNight: pricePerNight ?? this.pricePerNight,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountPrice: discountPrice ?? this.discountPrice,
      isDeal: isDeal ?? this.isDeal,
      rating: rating ?? this.rating,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      totalRooms: totalRooms ?? this.totalRooms,
      availableRooms: availableRooms ?? this.availableRooms,
      ownerId: ownerId ?? this.ownerId,
      roomTypes: roomTypes ?? this.roomTypes,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullAddress => '$address, $city, $country';
  bool get hasImages => images.isNotEmpty;
  String get mainImage => hasImages ? images.first : '';
  bool get isAvailable => availableRooms > 0;
  
  // Get the effective price (discounted price if available, otherwise original price)
  double get effectivePrice => isDeal && discountPrice != null ? discountPrice! : pricePerNight;
  
  // Get formatted price string with discount information
  String get priceDisplay {
    if (isDeal && discountPrice != null && discountPercentage != null) {
      return '\$${discountPrice!.toStringAsFixed(0)}/night';
    }
    return '\$${pricePerNight.toStringAsFixed(0)}/night';
  }
  
  // Get original price display (crossed out if there's a discount)
  String? get originalPriceDisplay {
    if (isDeal && discountPrice != null && discountPercentage != null) {
      return '\$${pricePerNight.toStringAsFixed(0)}';
    }
    return null;
  }
  
  // Get discount percentage as formatted string
  String? get discountDisplay {
    if (isDeal && discountPercentage != null && discountPercentage! > 0) {
      return '${discountPercentage!.toStringAsFixed(0)}% OFF';
    }
    return null;
  }
}
