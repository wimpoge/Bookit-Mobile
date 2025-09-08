import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/hotels/hotels_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../models/hotel.dart';
import '../../widgets/owner_hotel_card.dart';
import '../../widgets/discount_dialog.dart';
import '../../services/api_service.dart';

class OwnerHotelsScreen extends StatefulWidget {
  const OwnerHotelsScreen({Key? key}) : super(key: key);

  @override
  State<OwnerHotelsScreen> createState() => _OwnerHotelsScreenState();
}

class _OwnerHotelsScreenState extends State<OwnerHotelsScreen> {
  // Filter and pagination state
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Full, Recent
  String _sortBy = 'Name'; // Name, Rating, Rooms, Price, Date
  bool _sortAscending = true;
  int _currentPage = 0;
  final int _itemsPerPage = 5;
  
  // Price range filter state
  double _minPrice = 0;
  double _maxPrice = 1000;
  bool _usePriceFilter = false;
  
  // Rating filter state
  double? _ratingFilter;
  
  // Scroll controller for scroll-to-top functionality
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });
    
    // Listen to scroll changes
    _scrollController.addListener(() {
      if (_scrollController.offset > 300 && !_showScrollToTop) {
        setState(() {
          _showScrollToTop = true;
        });
      } else if (_scrollController.offset <= 300 && _showScrollToTop) {
        setState(() {
          _showScrollToTop = false;
        });
      }
    });
  }
  
  void _applyFilters() {
    final status = _selectedFilter == 'All' ? null : _selectedFilter.toLowerCase();
    final sortBy = _sortBy.toLowerCase();
    
    print('🔍 Applying filters:');
    print('   - Filter: $_selectedFilter');
    print('   - Sort: $_sortBy (${_sortAscending ? 'ASC' : 'DESC'})');
    print('   - Search: $_searchQuery');
    print('   - Price Range: $_usePriceFilter ? $_minPrice-$_maxPrice : null');
    
    context.read<HotelsBloc>().add(OwnerHotelsFilterEvent(
      search: _searchQuery.isEmpty ? null : _searchQuery,
      status: status,
      sortBy: sortBy,
      sortDesc: !_sortAscending,
      minPrice: _usePriceFilter ? _minPrice : null,
      maxPrice: _usePriceFilter ? _maxPrice : null,
      minRating: _ratingFilter,
    ));
    
    setState(() {
      _currentPage = 0;
    });
  }
  
  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedFilter = 'All';
      _sortBy = 'Name';
      _sortAscending = true;
      _usePriceFilter = false;
      _minPrice = 0;
      _maxPrice = 1000;
      _ratingFilter = null;
      _currentPage = 0;
    });
    
    _applyFilters();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  

  void _showOwnerFilters() {
    print('🔧 _showOwnerFilters called');
    // Create local variables for modal state
    String tempSelectedFilter = _selectedFilter;
    String tempSortBy = _sortBy;
    bool tempSortAscending = _sortAscending;
    bool tempUsePriceFilter = _usePriceFilter;
    double tempMinPrice = _minPrice;
    double tempMaxPrice = _maxPrice;
    
    // Additional filter states
    DateTime? tempStartDate;
    DateTime? tempEndDate;
    String? tempRoomFilter;
    double? tempRatingFilter = _ratingFilter;
    
    // Store sort directions for each field
    Map<String, bool> sortDirections = {
      'Name': true,
      'Rating': true,
      'Rooms': true,
      'Price': true,
      'Date': true,
    };
    
    // Set current sort direction
    sortDirections[_sortBy] = _sortAscending;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black54,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: GestureDetector(
                  onTap: () {}, // Prevent tap through
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        
                        // Header
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Text(
                                'Filter Hotels',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Status Filters with Clear All
                                Row(
                                  children: [
                                    Text(
                                      'Status Filter',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                                        setModalState(() {
                                          tempSelectedFilter = 'All';
                                          tempSortBy = 'Name';
                                          tempSortAscending = true;
                                          tempUsePriceFilter = false;
                                          tempMinPrice = 0;
                                          tempMaxPrice = 1000;
                                          // Reset all sort directions
                                          sortDirections.updateAll((key, value) => true);
                                        });
                                      },
                                      child: Text(
                                        'Clear All',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: ['All', 'Active', 'Full', 'Recent'].map((filter) {
                                    final isSelected = tempSelectedFilter == filter;
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempSelectedFilter = filter;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              _getFilterIcon(filter),
                                              size: 16,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              filter,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                color: isSelected
                                                    ? Theme.of(context).colorScheme.onPrimary
                                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Sort Options
                                Text(
                                  'Sort By',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                
                                ...['Name', 'Rating', 'Rooms', 'Price', 'Date'].map((sort) {
                                  final isSelected = tempSortBy == sort;
                                  final sortAsc = sortDirections[sort] ?? true;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                          : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(16),
                                      border: isSelected ? Border.all(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                        width: 1,
                                      ) : null,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getSortIcon(sort),
                                          size: 24,
                                          color: isSelected 
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            sort,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              color: isSelected 
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Theme.of(context).colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                        // Sort direction toggle
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              tempSortBy = sort;
                                              tempSortAscending = true;
                                              sortDirections[sort] = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: sortAsc && isSelected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.arrow_upward,
                                                  size: 16,
                                                  color: sortAsc && isSelected
                                                      ? Theme.of(context).colorScheme.onPrimary
                                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'ASC',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: sortAsc && isSelected
                                                        ? Theme.of(context).colorScheme.onPrimary
                                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setModalState(() {
                                              tempSortBy = sort;
                                              tempSortAscending = false;
                                              sortDirections[sort] = false;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: !sortAsc && isSelected
                                                  ? Theme.of(context).colorScheme.primary
                                                  : Colors.transparent,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.arrow_downward,
                                                  size: 16,
                                                  color: !sortAsc && isSelected
                                                      ? Theme.of(context).colorScheme.onPrimary
                                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'DESC',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: !sortAsc && isSelected
                                                        ? Theme.of(context).colorScheme.onPrimary
                                                        : Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                
                                const SizedBox(height: 32),
                                
                                // Rating Filter
                                Text(
                                  'Minimum Rating',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: [null, 1.0, 2.0, 3.0, 4.0, 4.5].map((rating) {
                                    final isSelected = tempRatingFilter == rating;
                                    final label = rating == null ? 'Any' : '${rating.toString()}★';
                                    return GestureDetector(
                                      onTap: () {
                                        setModalState(() {
                                          tempRatingFilter = rating;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context).colorScheme.primary
                                              : Theme.of(context).colorScheme.surfaceVariant,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: isSelected
                                                ? Theme.of(context).colorScheme.primary
                                                : Colors.transparent,
                                            width: 2,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: isSelected
                                                  ? Theme.of(context).colorScheme.onPrimary
                                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              label,
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                                color: isSelected
                                                    ? Theme.of(context).colorScheme.onPrimary
                                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                
                                const SizedBox(height: 32),
                                
                                // Price Range Filter
                                Row(
                                  children: [
                                    Text(
                                      'Price Range',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: tempUsePriceFilter,
                                      onChanged: (value) {
                                        setModalState(() {
                                          tempUsePriceFilter = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (tempUsePriceFilter) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Min Price: \$${tempMinPrice.round()}',
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                            Slider(
                                              value: tempMinPrice,
                                              min: 0,
                                              max: 1000,
                                              divisions: 20,
                                              onChanged: (value) {
                                                setModalState(() {
                                                  tempMinPrice = value;
                                                  if (tempMinPrice > tempMaxPrice) {
                                                    tempMaxPrice = tempMinPrice;
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Max Price: \$${tempMaxPrice.round()}',
                                              style: GoogleFonts.poppins(fontSize: 14),
                                            ),
                                            Slider(
                                              value: tempMaxPrice,
                                              min: 0,
                                              max: 1000,
                                              divisions: 20,
                                              onChanged: (value) {
                                                setModalState(() {
                                                  tempMaxPrice = value;
                                                  if (tempMaxPrice < tempMinPrice) {
                                                    tempMinPrice = tempMaxPrice;
                                                  }
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                
                                const SizedBox(height: 32),
                                
                                // Action Buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setModalState(() {
                                            tempSelectedFilter = 'All';
                                            tempSortBy = 'Name';
                                            tempSortAscending = true;
                                            tempUsePriceFilter = false;
                                            tempMinPrice = 0;
                                            tempMaxPrice = 1000;
                                            tempRatingFilter = null;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: const Text('Reset'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedFilter = tempSelectedFilter;
                                            _sortBy = tempSortBy;
                                            _sortAscending = tempSortAscending;
                                            _usePriceFilter = tempUsePriceFilter;
                                            _minPrice = tempMinPrice;
                                            _maxPrice = tempMaxPrice;
                                            _ratingFilter = tempRatingFilter;
                                            _currentPage = 0;
                                          });
                                          _applyFilters();
                                          Navigator.pop(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                        ),
                                        child: const Text('Apply Filters'),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'All': return Icons.all_inclusive;
      case 'Active': return Icons.check_circle;
      case 'Full': return Icons.hotel;
      case 'Recent': return Icons.access_time;
      default: return Icons.filter_list;
    }
  }

  IconData _getSortIcon(String sort) {
    switch (sort) {
      case 'Name': return Icons.sort_by_alpha;
      case 'Rating': return Icons.star;
      case 'Rooms': return Icons.meeting_room;
      case 'Price': return Icons.attach_money;
      case 'Date': return Icons.calendar_today;
      case 'Rating Filter': return Icons.star_rate;
      case 'Price Range': return Icons.price_change;
      case 'Date Range': return Icons.date_range;
      case 'Room Type': return Icons.hotel;
      default: return Icons.sort;
    }
  }
  
  
  List<Hotel> _getCurrentPageHotels(List<Hotel> hotels) {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, hotels.length);
    return hotels.sublist(startIndex, endIndex);
  }
  
  int _getTotalPages(List<Hotel> hotels) => (hotels.length / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Hotels',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: BlocConsumer<HotelsBloc, HotelsState>(
        listener: (context, state) {
          if (state is HotelActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            // Reload hotels after action
            context.read<HotelsBloc>().add(OwnerHotelsLoadEvent());
          } else if (state is HotelsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is HotelsLoading || state is HotelActionLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HotelsError) {
            return _buildErrorState(state.message);
          } else if (state is HotelsLoaded) {
            return _buildHotelsListWithFilters(state.hotels);
          }
          
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Scroll to top button
          if (_showScrollToTop)
            FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Theme.of(context).colorScheme.primary,
              elevation: 2,
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          
          if (_showScrollToTop) const SizedBox(height: 16),
          
          // Add hotel button
          FloatingActionButton(
            onPressed: () => context.go('/owner/hotels/add'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/500.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading hotels',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<HotelsBloc>().add(OwnerHotelsLoadEvent());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotelsListWithFilters(List<Hotel> hotels) {
    if (hotels.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        _applyFilters();
      },
      child: Column(
        children: [
          // Stats header
          Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                final ownerName = authState is AuthAuthenticated 
                    ? authState.user.fullName?.split(' ').first ?? 'Owner'
                    : 'Owner';
                
                return Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.hotel,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Welcome back, $ownerName!',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            '${hotels.length}',
                            'Hotels Found',
                            Icons.hotel,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatItem(
                            '${hotels.fold<int>(0, (sum, hotel) => sum + hotel.availableRooms)}',
                            'Available Rooms',
                            Icons.meeting_room,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatItem(
                            '${hotels.isNotEmpty ? (hotels.map((h) => h.rating).reduce((a, b) => a + b) / hotels.length).toStringAsFixed(1) : "0.0"}',
                            'Avg Rating',
                            Icons.star,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          
          // Search and Filter Controls
          _buildSearchAndFilters(),
          
          // Hotels list or empty filtered state
          Expanded(
            child: hotels.isEmpty 
                ? _buildEmptyFilteredState() 
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0), // No bottom padding
                    itemCount: _getCurrentPageHotels(hotels).length + (hotels.length > _itemsPerPage ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      if (index == _getCurrentPageHotels(hotels).length) {
                        // This is the pagination item
                        return _buildPaginationControls(hotels);
                      }
                      
                      final hotel = _getCurrentPageHotels(hotels)[index];
                      return OwnerHotelCard(
                        hotel: hotel,
                        onTap: () => _showHotelActionsBottomSheet(hotel),
                        onEdit: () => context.go('/owner/hotels/edit/${hotel.id}'),
                        onViewReviews: () => context.go('/owner/hotels/${hotel.id}/reviews'),
                        onDelete: () => _showDeleteDialog(hotel),
                        onDiscount: () => _showDiscountDialog(hotel),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search hotels by name, city, or country...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _currentPage = 0;
                          });
                          _applyFilters();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 0;
                });
                // Apply filters with a slight delay to avoid too many API calls
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchQuery == value) {
                    _applyFilters();
                  }
                });
              },
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Compact Filter Button
          _CompactFilterButton(
            hasActiveFilters: _selectedFilter != 'All' || 
                             _sortBy != 'Name' || 
                             !_sortAscending || 
                             _searchQuery.isNotEmpty || 
                             _usePriceFilter ||
                             _ratingFilter != null,
            onTap: _showOwnerFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(List<Hotel> hotels) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Page Info
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Page ${_currentPage + 1} of ${_getTotalPages(hotels)} (${hotels.length} hotels)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Modern Pagination
          _buildModernPagination(hotels),
        ],
      ),
    );
  }

  Widget _buildModernPagination(List<Hotel> hotels) {
    final totalPages = _getTotalPages(hotels);
    if (totalPages <= 1) return const SizedBox.shrink();
    
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 16, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Previous Button
          _buildPaginationButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 0 
                ? () => setState(() => _currentPage--) 
                : null,
            isEnabled: _currentPage > 0,
          ),
          
          // Page Indicators
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (totalPages <= 5) ...[
                  // Show all pages if 5 or fewer
                  for (int i = 0; i < totalPages; i++)
                    _buildPageDot(i),
                ] else ...[
                  // Show condensed version for many pages
                  _buildPageDot(0),
                  if (_currentPage > 2) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                  for (int i = (_currentPage - 1).clamp(1, totalPages - 2); 
                      i <= (_currentPage + 1).clamp(1, totalPages - 2); i++)
                    _buildPageDot(i),
                  if (_currentPage < totalPages - 3) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '...',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                  if (totalPages > 1) _buildPageDot(totalPages - 1),
                ],
              ],
            ),
          ),
          
          // Next Button  
          _buildPaginationButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < totalPages - 1 
                ? () => setState(() => _currentPage++) 
                : null,
            isEnabled: _currentPage < totalPages - 1,
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: isEnabled 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Colors.transparent,
        highlightColor: isEnabled 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isEnabled 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: isEnabled ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ] : [],
          ),
          child: Icon(
            icon,
            size: 18,
            color: isEnabled 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildPageDot(int pageIndex) {
    final isActive = pageIndex == _currentPage;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _currentPage = pageIndex),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/No Hotels Found.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Try adjusting your search or filter criteria',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                  _sortBy = 'Name';
                  _sortAscending = true;
                  _usePriceFilter = false;
                  _minPrice = 0;
                  _maxPrice = 1000;
                  _currentPage = 0;
                });
                // Load all hotels without filters
                context.read<HotelsBloc>().add(OwnerHotelsLoadEvent());
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/No Hotels Found.png',
              width: 120,
              height: 120,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 24),
            Text(
              'Start by adding your first hotel to begin accepting bookings',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/owner/hotels/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Your First Hotel'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHotelActionsBottomSheet(Hotel hotel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 40,
                      height: 40,
                      color: Colors.grey[300],
                      child: hotel.hasImages
                          ? Image.network(
                              hotel.mainImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.hotel, color: Colors.grey[600]);
                              },
                            )
                          : Icon(Icons.hotel, color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hotel.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${hotel.city}, ${hotel.country}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Action items
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('Edit Hotel', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                context.go('/owner/hotels/edit/${hotel.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline),
              title: Text('View Reviews', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                context.go('/owner/hotels/${hotel.id}/reviews');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.local_offer_outlined,
                color: hotel.isDeal ? Colors.orange : null,
              ),
              title: Text(
                hotel.isDeal ? 'Update Discount' : 'Add Discount',
                style: GoogleFonts.poppins(),
              ),
              subtitle: hotel.isDeal && hotel.discountPercentage != null
                  ? Text(
                      '${hotel.discountPercentage!.toStringAsFixed(0)}% OFF',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _showDiscountDialog(hotel);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text('View as Guest', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                _showHotelAsGuest(hotel);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text(
                'Delete Hotel',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(hotel);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(Hotel hotel) {
    showDialog(
      context: context,
      builder: (context) => DiscountDialog(
        hotelName: hotel.name,
        currentPrice: hotel.pricePerNight,
        currentDiscountPercentage: hotel.discountPercentage,
        onApplyDiscount: (discountPercentage) async {
          try {
            await ApiService().updateHotelDiscount(hotel.id, discountPercentage);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    discountPercentage > 0 
                        ? 'Discount applied successfully!'
                        : 'Discount removed successfully!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
              // Reload hotels to show updated discount
              _applyFilters();
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update discount: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        onRemoveDiscount: hotel.isDeal && hotel.discountPercentage != null && hotel.discountPercentage! > 0
            ? () async {
                try {
                  await ApiService().updateHotelDiscount(hotel.id, 0.0);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Discount removed successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    // Reload hotels to show updated discount
                    _applyFilters();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to remove discount: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            : null,
      ),
    );
  }

  void _showDeleteDialog(Hotel hotel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Hotel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete "${hotel.name}"? This action cannot be undone and will cancel all active bookings.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<HotelsBloc>().add(HotelDeleteEvent(hotelId: hotel.id));
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHotelAsGuest(Hotel hotel) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;
    
    // Responsive dimensions
    final modalHeight = isDesktop ? screenHeight * 0.85 : (isTablet ? screenHeight * 0.88 : screenHeight * 0.92);
    final horizontalPadding = isDesktop ? 32.0 : (isTablet ? 24.0 : 20.0);
    final headerFontSize = isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: modalHeight,
        constraints: BoxConstraints(
          maxWidth: isDesktop ? 800 : double.infinity,
        ),
        margin: isDesktop ? EdgeInsets.symmetric(horizontal: (screenWidth - 800) / 2) : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility,
                    color: Theme.of(context).colorScheme.primary,
                    size: isTablet ? 26 : 24,
                  ),
                  SizedBox(width: isTablet ? 16 : 12),
                  Text(
                    'Guest View',
                    style: GoogleFonts.poppins(
                      fontSize: headerFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: isTablet ? 28 : 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Hotel Preview as Guest would see it
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel Image
                    Container(
                      height: isDesktop ? 300 : (isTablet ? 250 : 200),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[300],
                      ),
                      child: hotel.hasImages
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                hotel.images.first.startsWith('http')
                                    ? hotel.images.first
                                    : 'http://192.168.1.4:8000${hotel.images.first}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.hotel,
                                      size: 64,
                                      color: Colors.grey[600],
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.hotel,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Hotel Name and Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                style: GoogleFonts.poppins(
                                  fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: isTablet ? 6 : 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: isTablet ? 18 : 16,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  SizedBox(width: isTablet ? 6 : 4),
                                  Flexible(
                                    child: Text(
                                      '${hotel.city}, ${hotel.country}',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 16 : 12, 
                            vertical: isTablet ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: isTablet ? 18 : 16,
                              ),
                              SizedBox(width: isTablet ? 6 : 4),
                              Text(
                                hotel.rating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Price
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                size: isTablet ? 32 : 28,
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Current price (discounted if applicable)
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          hotel.isDeal && hotel.discountPrice != null
                                              ? '\$${hotel.discountPrice!.toStringAsFixed(0)}'
                                              : '\$${hotel.pricePerNight.toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(
                                            fontSize: isDesktop ? 36 : (isTablet ? 32 : 28),
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            'per night',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 18 : 16,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    
                                    // Original price if discounted
                                    if (hotel.isDeal && hotel.discountPrice != null && hotel.discountPercentage != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            '\$${hotel.pricePerNight.toStringAsFixed(0)}',
                                            style: GoogleFonts.poppins(
                                              fontSize: isTablet ? 16 : 14,
                                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${hotel.discountPercentage!.toStringAsFixed(0)}% OFF',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (isTablet) SizedBox(height: 12),
                          if (!isTablet) SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '${hotel.availableRooms} rooms available',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 16 : 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: isTablet ? 24 : 20),
                    
                    // Description
                    if (hotel.description != null && hotel.description!.isNotEmpty) ...[
                      Text(
                        'About this hotel',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 12 : 8),
                      Text(
                        hotel.description!,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: isTablet ? 24 : 20),
                    ],
                    
                    // Amenities
                    if (hotel.amenities.isNotEmpty) ...[
                      Text(
                        'Amenities',
                        style: GoogleFonts.poppins(
                          fontSize: isDesktop ? 22 : (isTablet ? 20 : 18),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: isTablet ? 16 : 12),
                      Wrap(
                        spacing: isTablet ? 12 : 8,
                        runSpacing: isTablet ? 12 : 8,
                        children: hotel.amenities.map((amenity) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 16 : 12, 
                              vertical: isTablet ? 8 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getAmenityIcon(amenity),
                                  size: isTablet ? 18 : 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: isTablet ? 8 : 6),
                                Text(
                                  amenity,
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 14 : 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: isTablet ? 24 : 20),
                    ],
                    
                    // Address
                    Container(
                      padding: EdgeInsets.all(isTablet ? 20 : 16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location',
                            style: GoogleFonts.poppins(
                              fontSize: isDesktop ? 20 : (isTablet ? 18 : 16),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isTablet ? 12 : 8),
                          Text(
                            hotel.address,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Book Now Button (Preview only)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: null, // Disabled in preview
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        ),
                        child: Text(
                          'Book Now (Preview Only)',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
      case 'wi-fi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'pool':
      case 'swimming pool':
        return Icons.pool;
      case 'gym':
      case 'fitness center':
        return Icons.fitness_center;
      case 'restaurant':
        return Icons.restaurant;
      case 'room service':
        return Icons.room_service;
      case 'spa':
        return Icons.spa;
      case 'beach':
        return Icons.beach_access;
      case 'fireplace':
        return Icons.fireplace;
      case 'air conditioning':
      case 'ac':
        return Icons.ac_unit;
      default:
        return Icons.check_circle;
    }
  }
}

class _CompactFilterButton extends StatelessWidget {
  final bool hasActiveFilters;
  final VoidCallback onTap;

  const _CompactFilterButton({
    required this.hasActiveFilters,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print('🔧 Filter button tapped');
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: hasActiveFilters 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasActiveFilters 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.2),
              width: hasActiveFilters ? 2 : 1,
            ),
            boxShadow: hasActiveFilters ? [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.tune,
                size: 24,
                color: hasActiveFilters
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.onPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final String? sortDirection;
  final VoidCallback onTap;

  const _SortOption({
    required this.icon,
    required this.title,
    required this.isSelected,
    this.sortDirection,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      splashColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      highlightColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected 
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (sortDirection != null)
                    Text(
                      sortDirection!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isSelected 
                  ? Icons.check_circle
                  : Icons.chevron_right,
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}