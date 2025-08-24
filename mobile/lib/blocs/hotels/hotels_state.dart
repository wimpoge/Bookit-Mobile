part of 'hotels_bloc.dart';

abstract class HotelsState extends Equatable {
  const HotelsState();

  @override
  List<Object?> get props => [];
}

class HotelsInitial extends HotelsState {}

class HotelsLoading extends HotelsState {}

class HotelsLoaded extends HotelsState {
  final List<Hotel> hotels;
  final Map<String, dynamic>? debugInfo;

  const HotelsLoaded(this.hotels, {this.debugInfo});

  @override
  List<Object?> get props => [hotels, debugInfo];
}

class HotelDetailLoading extends HotelsState {}

class HotelDetailLoaded extends HotelsState {
  final Hotel hotel;

  const HotelDetailLoaded(this.hotel);

  @override
  List<Object> get props => [hotel];
}

class HotelActionLoading extends HotelsState {}

class HotelActionSuccess extends HotelsState {
  final String message;

  const HotelActionSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class HotelsError extends HotelsState {
  final String message;

  const HotelsError(this.message);

  @override
  List<Object> get props => [message];
}
