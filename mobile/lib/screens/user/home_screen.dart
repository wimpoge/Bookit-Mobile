import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/hotels/hotels_bloc.dart';
import '../../blocs/theme/theme_bloc.dart';
import '../../widgets/hotel_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/location_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  bool _isGridView = false;

  String? _activeQuickFilter;
  bool _hasActiveFilters = false;
  
  // Pagination state
  int _currentPage = 0;
  final int _itemsPerPage = 8;
  List<dynamic> _allHotels = [];
  List<dynamic> _currentPageHotels = [];

  @override
  void initState() {
    super.initState();
    context.read<HotelsBloc>().add(const HotelsLoadEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updatePagination(List<dynamic> hotels) {
    _allHotels = hotels;
    _currentPage = 0; // Reset to first page
    _updateCurrentPageHotels();
  }

  void _updateCurrentPageHotels() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, _allHotels.length);
    _currentPageHotels = _allHotels.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_allHotels.length / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();

  Widget _buildModernPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                ? () => setState(() {
                    _currentPage--;
                    _updateCurrentPageHotels();
                  }) 
                : null,
            isEnabled: _currentPage > 0,
          ),
          
          // Page Indicators
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_totalPages <= 5) ...[
                  // Show all pages if 5 or fewer
                  for (int i = 0; i < _totalPages; i++)
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
                  for (int i = (_currentPage - 1).clamp(1, _totalPages - 2); 
                      i <= (_currentPage + 1).clamp(1, _totalPages - 2); i++)
                    _buildPageDot(i),
                  if (_currentPage < _totalPages - 3) ...[
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
                  if (_totalPages > 1) _buildPageDot(_totalPages - 1),
                ],
              ],
            ),
          ),
          
          // Next Button  
          _buildPaginationButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages - 1 
                ? () => setState(() {
                    _currentPage++;
                    _updateCurrentPageHotels();
                  }) 
                : null,
            isEnabled: _currentPage < _totalPages - 1,
          ),
        ],
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
        borderRadius: BorderRadius.circular(12),
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
        onTap: () => setState(() {
          _currentPage = pageIndex;
          _updateCurrentPageHotels();
        }),
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

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        onApplyFilters: (filters) {
          context.read<HotelsBloc>().add(HotelsFilterEvent(
                city: filters['city'],
                minPrice: filters['minPrice'],
                maxPrice: filters['maxPrice'],
                amenities: filters['amenities'],
                amenitiesMatchAll: filters['amenitiesMatchAll'],
              ));
          setState(() {
            _hasActiveFilters = true;
            _activeQuickFilter = null;
          });
        },
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _activeQuickFilter = null;
      _hasActiveFilters = false;
      _searchController.clear();
    });
    context.read<HotelsBloc>().add(const HotelsLoadEvent());
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<HotelsBloc>().add(const HotelsLoadEvent());
      setState(() {
        _hasActiveFilters = false;
        _activeQuickFilter = null;
      });
    } else {
      context.read<HotelsBloc>().add(HotelsSearchEvent(query: query.trim()));
      setState(() {
        _hasActiveFilters = true;
        _activeQuickFilter = null;
      });
    }
  }

  void _onQuickFilterTap(String filterType) async {
    setState(() {
      if (_activeQuickFilter == filterType) {
        _activeQuickFilter = null;
        _hasActiveFilters = false;
        context.read<HotelsBloc>().add(const HotelsLoadEvent());
      } else {
        _activeQuickFilter = filterType;
        _hasActiveFilters = true;
      }
    });

    if (_activeQuickFilter == filterType) {
      switch (filterType) {
        case 'nearme':
          await _handleNearMeFilter();
          break;
        case 'deals':
          _handleDealsFilter();
          break;
        case 'luxury':
          context.read<HotelsBloc>().add(const HotelsFilterEvent(
                amenities: ['Spa', 'Pool', 'Restaurant'],
              ));
          break;
        case 'business':
          context.read<HotelsBloc>().add(const HotelsFilterEvent(
                amenities: ['WiFi', 'Business Center'],
              ));
          break;
      }
    }
  }

  Future<void> _handleNearMeFilter() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text('Getting your location...', style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );

      // Get user's current location
      final locationService = LocationService();
      final locationData = await locationService.getCurrentLocation();

      if (locationData != null) {
        // Use the location to fetch nearby hotels
        context.read<HotelsBloc>().add(HotelsNearbyEvent(
          latitude: locationData.latitude!,
          longitude: locationData.longitude!,
          radiusKm: 15.0, // 15km radius
        ));

        // Show success message with location info
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Showing hotels near ${locationData.latitude!.toStringAsFixed(4)}, ${locationData.longitude!.toStringAsFixed(4)} (15km radius)',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle location error
      setState(() {
        _activeQuickFilter = null;
        _hasActiveFilters = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location access required. Please enable GPS and location permissions.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _onQuickFilterTap('nearme'),
          ),
        ),
      );
    }
  }

  void _handleDealsFilter() {
    // Show hotels with good prices (under $150 per night)
    context.read<HotelsBloc>().add(const HotelsDealsEvent(
      maxPriceFilter: 150.0,
    ));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Showing best deals under \$150/night',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort Hotels',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Highest Rated'),
              onTap: () {
                context.read<HotelsBloc>().add(const HotelsLoadEvent());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Price: Low to High'),
              onTap: () {
                context.read<HotelsBloc>().add(const HotelsLoadEvent());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Price: High to Low'),
              onTap: () {
                context.read<HotelsBloc>().add(const HotelsLoadEvent());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 24.0 : 20.0);
    final gridColumns = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final userName = state is AuthAuthenticated
                                    ? state.user.fullName?.split(' ').first ??
                                        'User'
                                    : 'User';
                                return Text(
                                  'Hello, $userName',
                                  style: GoogleFonts.poppins(
                                    fontSize: isTablet ? 28 : 24,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Find Your Perfect Stay',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 18 : 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onBackground
                                    .withOpacity(0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isGridView ? Icons.view_list : Icons.grid_view,
                              color: Theme.of(context).colorScheme.onBackground,
                              size: isTablet ? 28 : 24,
                            ),
                            onPressed: () {
                              setState(() {
                                _isGridView = !_isGridView;
                              });
                            },
                          ),
                          BlocBuilder<ThemeBloc, ThemeState>(
                            builder: (context, state) {
                              return IconButton(
                                icon: Icon(
                                  state.isDarkMode
                                      ? Icons.light_mode
                                      : Icons.dark_mode,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  size: isTablet ? 28 : 24,
                                ),
                                onPressed: () {
                                  context
                                      .read<ThemeBloc>()
                                      .add(ThemeToggleEvent());
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: isTablet ? 32 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          controller: _searchController,
                          hintText: 'Where are you going?',
                          prefixIcon: const Icon(Icons.search),
                          onChanged: _onSearch,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 20,
                          ),
                          onPressed: _showFilterBottomSheet,
                        ),
                      ),
                    ],
                  ),
                  // Only show filter buttons if hotels are loaded and not empty
                  BlocBuilder<HotelsBloc, HotelsState>(
                    builder: (context, state) {
                      final showFilters = state is HotelsLoaded && state.hotels.isNotEmpty;
                      if (!showFilters) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          SizedBox(height: isTablet ? 32 : 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _ModernFilterIcon(
                                icon: Icons.location_on,
                                label: 'Near',
                                isSelected: _activeQuickFilter == 'nearme',
                                onTap: () => _onQuickFilterTap('nearme'),
                              ),
                              _ModernFilterIcon(
                                icon: Icons.local_offer,
                                label: 'Deals',
                                isSelected: _activeQuickFilter == 'deals',
                                onTap: () => _onQuickFilterTap('deals'),
                              ),
                              _ModernFilterIcon(
                                icon: Icons.diamond,
                                label: 'Luxury',
                                isSelected: _activeQuickFilter == 'luxury',
                                onTap: () => _onQuickFilterTap('luxury'),
                              ),
                              _ModernFilterIcon(
                                icon: Icons.business,
                                label: 'Business',
                                isSelected: _activeQuickFilter == 'business',
                                onTap: () => _onQuickFilterTap('business'),
                              ),
                              _ModernFilterIcon(
                                icon: Icons.sort,
                                label: 'Sort',
                                isSelected: false,
                                onTap: _showSortOptions,
                              ),
                            ],
                          ),
                          if (_hasActiveFilters) ...[
                            const SizedBox(height: 12),
                            Center(
                              child: TextButton.icon(
                                onPressed: _clearAllFilters,
                                icon: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                                label: Text(
                                  'Clear Filters',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: isTablet ? 24 : 16),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hotels',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                        BlocBuilder<HotelsBloc, HotelsState>(
                          builder: (context, state) {
                            if (state is HotelsLoaded) {
                              return Text(
                                '${state.hotels.length} found',
                                style: GoogleFonts.poppins(
                                  fontSize: isTablet ? 16 : 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground
                                      .withOpacity(0.6),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BlocBuilder<HotelsBloc, HotelsState>(
                        builder: (context, state) {
                          if (state is HotelsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is HotelsError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/500.png',
                                      width: isTablet ? 160 : 120,
                                      height: isTablet ? 160 : 120,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading hotels',
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 20 : 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      state.message,
                                      style: GoogleFonts.poppins(
                                        fontSize: isTablet ? 16 : 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.6),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: () {
                                        context
                                            .read<HotelsBloc>()
                                            .add(const HotelsLoadEvent());
                                      },
                                      child: Text(
                                        'Retry',
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else if (state is HotelsLoaded) {
                            if (state.hotels.isEmpty) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/No Hotels Found.png',
                                        width: isTablet ? 160 : 120,
                                        height: isTablet ? 160 : 120,
                                        fit: BoxFit.contain,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Try adjusting your search or filters',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 18 : 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground
                                              .withOpacity(0.7),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Update pagination when hotels change
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_allHotels.length != state.hotels.length) {
                                setState(() {
                                  _updatePagination(state.hotels);
                                });
                              }
                            });

                            if (_isGridView) {
                              return Column(
                                children: [
                                  Expanded(
                                    child: GridView.builder(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridColumns,
                                        childAspectRatio: isTablet ? 0.8 : 0.75,
                                        crossAxisSpacing: isTablet ? 20 : 16,
                                        mainAxisSpacing: isTablet ? 20 : 16,
                                      ),
                                      itemCount: _currentPageHotels.length,
                                      itemBuilder: (context, index) {
                                        final hotel = _currentPageHotels[index];
                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            return HotelCard(
                                              hotel: hotel,
                                              isGridView: true,
                                              onTap: () => context
                                                  .go('/hotel/${hotel.id}'),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  if (_allHotels.length > _itemsPerPage)
                                    _buildModernPagination(),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.only(bottom: 0),
                                      itemCount: _currentPageHotels.length,
                                      separatorBuilder: (context, index) => SizedBox(
                                        height: isTablet ? 20 : 16,
                                      ),
                                      itemBuilder: (context, index) {
                                        final hotel = _currentPageHotels[index];
                                        return HotelCard(
                                          hotel: hotel,
                                          isGridView: false,
                                          onTap: () =>
                                              context.go('/hotel/${hotel.id}'),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_allHotels.length > _itemsPerPage)
                                    _buildModernPagination(),
                                ],
                              );
                            }
                          }

                          return const SizedBox.shrink();
                        },
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
}

class _ModernFilterIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModernFilterIcon({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    )
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}