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

  void _onQuickFilterTap(String filterType) {
    setState(() {
      if (_activeQuickFilter == filterType) {
        _activeQuickFilter = null;
        _hasActiveFilters = false;
        context.read<HotelsBloc>().add(const HotelsLoadEvent());
      } else {
        _activeQuickFilter = filterType;
        _hasActiveFilters = true;

        switch (filterType) {
          case 'nearme':
            context.read<HotelsBloc>().add(const HotelsLoadEvent());
            break;
          case 'deals':
            context.read<HotelsBloc>().add(const HotelsLoadEvent());
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
    });
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
                  SizedBox(height: isTablet ? 32 : 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _QuickFilterChip(
                                label: 'Near me',
                                isSelected: _activeQuickFilter == 'nearme',
                                onTap: () => _onQuickFilterTap('nearme'),
                              ),
                              const SizedBox(width: 12),
                              _QuickFilterChip(
                                label: 'Best deals',
                                isSelected: _activeQuickFilter == 'deals',
                                onTap: () => _onQuickFilterTap('deals'),
                              ),
                              const SizedBox(width: 12),
                              _QuickFilterChip(
                                label: 'Luxury',
                                isSelected: _activeQuickFilter == 'luxury',
                                onTap: () => _onQuickFilterTap('luxury'),
                              ),
                              const SizedBox(width: 12),
                              _QuickFilterChip(
                                label: 'Business',
                                isSelected: _activeQuickFilter == 'business',
                                onTap: () => _onQuickFilterTap('business'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_hasActiveFilters) ...[
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: _clearAllFilters,
                          icon: Icon(
                            Icons.clear,
                            size: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          label: Text(
                            'Clear',
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
                      ],
                    ],
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
                                    Icon(
                                      Icons.error_outline,
                                      size: isTablet ? 80 : 64,
                                      color:
                                          Theme.of(context).colorScheme.error,
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
                                      Icon(
                                        Icons.search_off,
                                        size: isTablet ? 80 : 64,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onBackground
                                            .withOpacity(0.3),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No hotels found',
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
                                        'Try adjusting your search or filters',
                                        style: GoogleFonts.poppins(
                                          fontSize: isTablet ? 16 : 14,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onBackground
                                              .withOpacity(0.6),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            if (_isGridView) {
                              return GridView.builder(
                                padding: const EdgeInsets.only(bottom: 20),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: gridColumns,
                                  childAspectRatio: isTablet ? 0.8 : 0.75,
                                  crossAxisSpacing: isTablet ? 20 : 16,
                                  mainAxisSpacing: isTablet ? 20 : 16,
                                ),
                                itemCount: state.hotels.length,
                                itemBuilder: (context, index) {
                                  final hotel = state.hotels[index];
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
                              );
                            } else {
                              return ListView.separated(
                                padding: const EdgeInsets.only(bottom: 20),
                                itemCount: state.hotels.length,
                                separatorBuilder: (context, index) => SizedBox(
                                  height: isTablet ? 20 : 16,
                                ),
                                itemBuilder: (context, index) {
                                  final hotel = state.hotels[index];
                                  return HotelCard(
                                    hotel: hotel,
                                    isGridView: false,
                                    onTap: () =>
                                        context.go('/hotel/${hotel.id}'),
                                  );
                                },
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

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
