import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/hotel.dart';
import '../../services/api_service.dart';
import '../../widgets/hotel_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({Key? key}) : super(key: key);

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ApiService _apiService = ApiService.instance;
  List<Hotel> _favoriteHotels = [];
  List<Hotel> _filteredHotels = [];
  bool _isLoading = true;
  bool _isGridView = false;
  
  // Filter variables
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  String? _selectedAmenities;
  bool _amenitiesMatchAll = false;
  
  // Filter options
  final List<String> _cities = ['New York', 'Paris', 'London', 'Tokyo', 'Sydney'];
  final List<String> _amenities = ['WiFi', 'Pool', 'Spa', 'Restaurant', 'Bar', 'Gym', 'Parking'];

  @override
  void initState() {
    super.initState();
    _loadFavoriteHotels();
  }

  Future<void> _loadFavoriteHotels() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final hotels = await _apiService.getFavoriteHotels(
        city: _selectedCity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        amenities: _selectedAmenities,
        amenitiesMatchAll: _amenitiesMatchAll,
      );
      
      if (mounted) {
        setState(() {
          _favoriteHotels = hotels;
          _filteredHotels = hotels;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load favorite hotels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        selectedCity: _selectedCity,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        selectedAmenities: _selectedAmenities,
        amenitiesMatchAll: _amenitiesMatchAll,
        cities: _cities,
        amenities: _amenities,
        onApplyFilters: (city, minPrice, maxPrice, amenities, amenitiesMatchAll) {
          setState(() {
            _selectedCity = city;
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _selectedAmenities = amenities;
            _amenitiesMatchAll = amenitiesMatchAll;
          });
          _loadFavoriteHotels();
        },
        onClearFilters: () {
          setState(() {
            _selectedCity = null;
            _minPrice = null;
            _maxPrice = null;
            _selectedAmenities = null;
            _amenitiesMatchAll = false;
          });
          _loadFavoriteHotels();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorite Hotels',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.view_module),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteHotels.isEmpty
              ? _buildEmptyState()
              : _buildHotelsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Favorite Hotels',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start adding hotels to your favorites to see them here.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.go('/home');
              },
              child: Text(
                'Explore Hotels',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsList() {
    if (_isGridView) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final isTablet = screenWidth > 600;
            final crossAxisCount = isTablet ? 3 : 2;
            final itemHeight = isTablet ? 300.0 : 250.0;
            
            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: screenWidth / (crossAxisCount * itemHeight),
              ),
              itemCount: _filteredHotels.length,
              itemBuilder: (context, index) {
                final hotel = _filteredHotels[index];
                return HotelCard(
                  hotel: hotel,
                  isGridView: true,
                  onTap: () {
                    context.go('/hotel/${hotel.id}');
                  },
                );
              },
            );
          },
        ),
      );
    } else {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredHotels.length,
        itemBuilder: (context, index) {
          final hotel = _filteredHotels[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: HotelCard(
              hotel: hotel,
              isGridView: false,
              onTap: () {
                context.go('/hotel/${hotel.id}');
              },
            ),
          );
        },
      );
    }
  }
}

class _FilterDialog extends StatefulWidget {
  final String? selectedCity;
  final double? minPrice;
  final double? maxPrice;
  final String? selectedAmenities;
  final bool amenitiesMatchAll;
  final List<String> cities;
  final List<String> amenities;
  final Function(String?, double?, double?, String?, bool) onApplyFilters;
  final VoidCallback onClearFilters;

  const _FilterDialog({
    Key? key,
    required this.selectedCity,
    required this.minPrice,
    required this.maxPrice,
    required this.selectedAmenities,
    required this.amenitiesMatchAll,
    required this.cities,
    required this.amenities,
    required this.onApplyFilters,
    required this.onClearFilters,
  }) : super(key: key);

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  String? _selectedCity;
  double? _minPrice;
  double? _maxPrice;
  List<String> _selectedAmenities = [];
  bool _amenitiesMatchAll = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.selectedCity;
    _minPrice = widget.minPrice;
    _maxPrice = widget.maxPrice;
    _amenitiesMatchAll = widget.amenitiesMatchAll;
    
    if (widget.selectedAmenities != null) {
      _selectedAmenities = widget.selectedAmenities!.split(',').map((e) => e.trim()).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Text(
                    'Filter Favorites',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City filter
                    Text(
                      'City',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: const InputDecoration(
                        hintText: 'Select city',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.cities.map((city) {
                        return DropdownMenuItem(
                          value: city,
                          child: Text(city),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCity = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    // Price range
                    Text(
                      'Price Range (per night)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: _minPrice?.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Min Price',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _minPrice = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: _maxPrice?.toString(),
                            decoration: const InputDecoration(
                              labelText: 'Max Price',
                              prefixText: '\$',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _maxPrice = double.tryParse(value);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Amenities
                    Text(
                      'Amenities',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.amenities.map((amenity) {
                        final isSelected = _selectedAmenities.contains(amenity);
                        return FilterChip(
                          label: Text(amenity),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedAmenities.add(amenity);
                              } else {
                                _selectedAmenities.remove(amenity);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    if (_selectedAmenities.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      CheckboxListTile(
                        title: Text(
                          'Match all amenities',
                          style: GoogleFonts.poppins(fontSize: 14),
                        ),
                        value: _amenitiesMatchAll,
                        onChanged: (value) {
                          setState(() {
                            _amenitiesMatchAll = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onClearFilters();
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Clear All',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final amenitiesString = _selectedAmenities.isEmpty 
                            ? null 
                            : _selectedAmenities.join(',');
                        
                        widget.onApplyFilters(
                          _selectedCity,
                          _minPrice,
                          _maxPrice,
                          amenitiesString,
                          _amenitiesMatchAll,
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Apply Filters',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}