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
          ));
        },
      ),
    );
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<HotelsBloc>().add(const HotelsLoadEvent());
    } else {
      context.read<HotelsBloc>().add(HotelsSearchEvent(query: query.trim()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              final userName = state is AuthAuthenticated 
                                  ? state.user.fullName?.split(' ').first ?? 'User'
                                  : 'User';
                              return Text(
                                'Hello, $userName',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              );
                            },
                          ),
                          Text(
                            'Find Your Perfect Stay',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isGridView ? Icons.view_list : Icons.grid_view,
                              color: Theme.of(context).colorScheme.onBackground,
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
                                  state.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                                onPressed: () {
                                  context.read<ThemeBloc>().add(ThemeToggleEvent());
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Search bar
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
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.tune,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                          onPressed: _showFilterBottomSheet,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Quick filters
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _QuickFilterChip(
                          label: 'Near me',
                          isSelected: false,
                          onTap: () {
                            // TODO: Implement location-based filtering
                          },
                        ),
                        const SizedBox(width: 12),
                        _QuickFilterChip(
                          label: 'Best deals',
                          isSelected: false,
                          onTap: () {
                            // TODO: Implement best deals filtering
                          },
                        ),
                        const SizedBox(width: 12),
                        _QuickFilterChip(
                          label: 'Luxury',
                          isSelected: false,
                          onTap: () {
                            context.read<HotelsBloc>().add(const HotelsFilterEvent(
                              amenities: ['Spa', 'Pool', 'Restaurant'],
                            ));
                          },
                        ),
                        const SizedBox(width: 12),
                        _QuickFilterChip(
                          label: 'Business',
                          isSelected: false,
                          onTap: () {
                            context.read<HotelsBloc>().add(const HotelsFilterEvent(
                              amenities: ['WiFi', 'Business Center'],
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Hotels section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hotels',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
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
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Hotels list
                    Expanded(
                      child: BlocBuilder<HotelsBloc, HotelsState>(
                        builder: (context, state) {
                          if (state is HotelsLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is HotelsError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.error,
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
                                    state.message,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () {
                                      context.read<HotelsBloc>().add(const HotelsLoadEvent());
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          } else if (state is HotelsLoaded) {
                            if (state.hotels.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No hotels found',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.onBackground,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Try adjusting your search or filters',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            if (_isGridView) {
                              return GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                                itemCount: state.hotels.length,
                                itemBuilder: (context, index) {
                                  final hotel = state.hotels[index];
                                  return HotelCard(
                                    hotel: hotel,
                                    isGridView: true,
                                    onTap: () => context.go('/home/hotel/${hotel.id}'),
                                  );
                                },
                              );
                            } else {
                              return ListView.separated(
                                itemCount: state.hotels.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final hotel = state.hotels[index];
                                  return HotelCard(
                                    hotel: hotel,
                                    isGridView: false,
                                    onTap: () => context.go('/home/hotel/${hotel.id}'),
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
      child: Container(
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
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected 
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}