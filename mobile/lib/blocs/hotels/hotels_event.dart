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
  final int hotelId;

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
  final int hotelId;
  final Map<String, dynamic> hotelData;

  const HotelUpdateEvent({
    required this.hotelId,
    required this.hotelData,
  });

  @override
  List<Object> get props => [hotelId, hotelData];
}

class HotelDeleteEvent extends HotelsEvent {
  final int hotelId;

  const HotelDeleteEvent({required this.hotelId});

  @override
  List<Object> get props => [hotelId];
}

class OwnerHotelsLoadEvent extends HotelsEvent {}
