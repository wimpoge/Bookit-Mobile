import 'dart:convert';

class Hotel {
  final int id;
  final String name;
  final String? description;
  final String address;
  final String city;
  final String country;
  final double pricePerNight;
  final double rating;
  final List<String> amenities;
  final List<String> images;
  final int totalRooms;
  final int availableRooms;
  final int ownerId;
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
    required this.rating,
    required this.amenities,
    required this.images,
    required this.totalRooms,
    required this.availableRooms,
    required this.ownerId,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  factory Hotel.fromJson(Map<String, dynamic> json) {
    return Hotel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      pricePerNight: json['price_per_night'].toDouble(),
      rating: json['rating'].toDouble(),
      amenities: List<String>.from(json['amenities'] ?? []),
      images: List<String>.from(json['images'] ?? []),
      totalRooms: json['total_rooms'],
      availableRooms: json['available_rooms'],
      ownerId: json['owner_id'],
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
      'rating': rating,
      'amenities': amenities,
      'images': images,
      'total_rooms': totalRooms,
      'available_rooms': availableRooms,
      'owner_id': ownerId,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String toJson() => jsonEncode(toMap());

  Hotel copyWith({
    int? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? country,
    double? pricePerNight,
    double? rating,
    List<String>? amenities,
    List<String>? images,
    int? totalRooms,
    int? availableRooms,
    int? ownerId,
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
      rating: rating ?? this.rating,
      amenities: amenities ?? this.amenities,
      images: images ?? this.images,
      totalRooms: totalRooms ?? this.totalRooms,
      availableRooms: availableRooms ?? this.availableRooms,
      ownerId: ownerId ?? this.ownerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullAddress => '$address, $city, $country';
  bool get hasImages => images.isNotEmpty;
  String get mainImage => hasImages ? images.first : '';
  bool get isAvailable => availableRooms > 0;
}