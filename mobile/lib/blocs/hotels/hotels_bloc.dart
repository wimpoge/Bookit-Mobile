import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/api_service.dart';
import '../../models/hotel.dart';

part 'hotels_event.dart';
part 'hotels_state.dart';

class HotelsBloc extends Bloc<HotelsEvent, HotelsState> {
  final ApiService _apiService;

  HotelsBloc(this._apiService) : super(HotelsInitial()) {
    on<HotelsLoadEvent>(_onLoadHotels);
    on<HotelsSearchEvent>(_onSearchHotels);
    on<HotelsFilterEvent>(_onFilterHotels);
    on<HotelDetailLoadEvent>(_onLoadHotelDetail);
    on<HotelCreateEvent>(_onCreateHotel);
    on<HotelUpdateEvent>(_onUpdateHotel);
    on<HotelDeleteEvent>(_onDeleteHotel);
    on<OwnerHotelsLoadEvent>(_onLoadOwnerHotels);
    on<OwnerHotelsFilterEvent>(_onFilterOwnerHotels);
    on<HotelsNearbyEvent>(_onLoadNearbyHotels);
    on<HotelsDealsEvent>(_onLoadHotelDeals);
  }

  Future<void> _onLoadHotels(
      HotelsLoadEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final hotels = await _apiService.getHotels(
        skip: event.skip,
        limit: event.limit,
      );
      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onSearchHotels(
      HotelsSearchEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final hotels = await _apiService.searchHotels(event.query);
      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onFilterHotels(
      HotelsFilterEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final amenitiesString = event.amenities?.join(',');

      final hotels = await _apiService.getHotels(
        city: event.city,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        amenities: amenitiesString,
        amenitiesMatchAll: event.amenitiesMatchAll ?? false,
      );

      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onLoadHotelDetail(
      HotelDetailLoadEvent event, Emitter<HotelsState> emit) async {
    emit(HotelDetailLoading());

    try {
      final hotel = await _apiService.getHotel(event.hotelId);
      emit(HotelDetailLoaded(hotel));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onCreateHotel(
      HotelCreateEvent event, Emitter<HotelsState> emit) async {
    emit(HotelActionLoading());

    try {
      final hotel = await _apiService.createHotel(event.hotelData);
      emit(HotelActionSuccess('Hotel created successfully'));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onUpdateHotel(
      HotelUpdateEvent event, Emitter<HotelsState> emit) async {
    emit(HotelActionLoading());

    try {
      final hotel =
          await _apiService.updateHotel(event.hotelId, event.hotelData);
      emit(HotelActionSuccess('Hotel updated successfully'));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onDeleteHotel(
      HotelDeleteEvent event, Emitter<HotelsState> emit) async {
    emit(HotelActionLoading());

    try {
      await _apiService.deleteHotel(event.hotelId);
      emit(HotelActionSuccess('Hotel deleted successfully'));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onLoadOwnerHotels(
      OwnerHotelsLoadEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final hotels = await _apiService.getOwnerHotels();
      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onFilterOwnerHotels(
      OwnerHotelsFilterEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final hotels = await _apiService.getOwnerHotels(
        skip: event.skip,
        limit: event.limit,
        city: event.city,
        status: event.status,
        sortBy: event.sortBy,
        sortDesc: event.sortDesc,
        search: event.search,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        minRating: event.minRating,
      );
      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onLoadNearbyHotels(
      HotelsNearbyEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final hotels = await _apiService.getNearbyHotels(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
      );
      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }

  Future<void> _onLoadHotelDeals(
      HotelsDealsEvent event, Emitter<HotelsState> emit) async {
    emit(HotelsLoading());

    try {
      final hotels = await _apiService.getHotelDeals(
        maxPrice: event.maxPriceFilter,
      );
      emit(HotelsLoaded(hotels));
    } catch (e) {
      emit(HotelsError(e.toString()));
    }
  }
}
