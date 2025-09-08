part of 'hotels_bloc.dart';

abstract class HotelsEvent extends Equatable {
  const HotelsEvent();

  @override
  List<Object?> get props => [];
}

class HotelsLoadEvent extends HotelsEvent {
  final int skip;
  final int limit;

  const HotelsLoadEvent({
    this.skip = 0,
    this.limit = 100,
  });

  @override
  List<Object> get props => [skip, limit];
}

class HotelsSearchEvent extends HotelsEvent {
  final String query;

  const HotelsSearchEvent({required this.query});

  @override
  List<Object> get props => [query];
}

class HotelsFilterEvent extends HotelsEvent {
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final List<String>? amenities;
  final bool? amenitiesMatchAll;

  const HotelsFilterEvent({
    this.city,
    this.minPrice,
    this.maxPrice,
    this.amenities,
    this.amenitiesMatchAll = false,
  });

  @override
  List<Object?> get props =>
      [city, minPrice, maxPrice, amenities, amenitiesMatchAll];
}

class HotelDetailLoadEvent extends HotelsEvent {
  final String hotelId;

  const HotelDetailLoadEvent({required this.hotelId});

  @override
  List<Object> get props => [hotelId];
}

class HotelCreateEvent extends HotelsEvent {
  final Map<String, dynamic> hotelData;

  const HotelCreateEvent({required this.hotelData});

  @override
  List<Object> get props => [hotelData];
}

class HotelUpdateEvent extends HotelsEvent {
  final String hotelId;
  final Map<String, dynamic> hotelData;

  const HotelUpdateEvent({
    required this.hotelId,
    required this.hotelData,
  });

  @override
  List<Object> get props => [hotelId, hotelData];
}

class HotelDeleteEvent extends HotelsEvent {
  final String hotelId;

  const HotelDeleteEvent({required this.hotelId});

  @override
  List<Object> get props => [hotelId];
}

class OwnerHotelsLoadEvent extends HotelsEvent {}

class OwnerHotelsFilterEvent extends HotelsEvent {
  final int skip;
  final int limit;
  final String? city;
  final String? status;
  final String? sortBy;
  final bool sortDesc;
  final String? search;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;

  const OwnerHotelsFilterEvent({
    this.skip = 0,
    this.limit = 100,
    this.city,
    this.status,
    this.sortBy,
    this.sortDesc = false,
    this.search,
    this.minPrice,
    this.maxPrice,
    this.minRating,
  });

  @override
  List<Object?> get props => [
    skip, limit, city, status, sortBy, sortDesc, search, minPrice, maxPrice, minRating
  ];
}

class HotelsNearbyEvent extends HotelsEvent {
  final double latitude;
  final double longitude;
  final double radiusKm;

  const HotelsNearbyEvent({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0, // Default 10km radius
  });

  @override
  List<Object> get props => [latitude, longitude, radiusKm];
}

class HotelsDealsEvent extends HotelsEvent {
  final double? maxPriceFilter;

  const HotelsDealsEvent({this.maxPriceFilter});

  @override
  List<Object?> get props => [maxPriceFilter];
}
