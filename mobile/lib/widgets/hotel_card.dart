import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/hotel.dart';
import '../services/api_service.dart';

class HotelCard extends StatelessWidget {
  final Hotel hotel;
  final bool isGridView;
  final VoidCallback onTap;

  const HotelCard({
    Key? key,
    required this.hotel,
    required this.isGridView,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isGridView
              ? _buildGridCard(context, isTablet)
              : _buildListCard(context, isTablet),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context, bool isTablet) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardHeight = constraints.maxHeight;
        final imageHeight = cardHeight * 0.6; // 60% for image
        final contentHeight = cardHeight * 0.4; // 40% for content

        return Column(
          children: [
            // Image section
            SizedBox(
              height: imageHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Hotel image
                  if (hotel.images != null && hotel.images!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showImageZoom(context, hotel.images!, 0),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: double.infinity,
                              height: double.infinity,
                              child: Image.network(
                                _getFullImageUrl(hotel.images!.first),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  print('HotelCard: Image load error: $error');
                                  return _buildImagePlaceholder(context);
                                },
                              ),
                            ),
                          ),
                          // Zoom indicator
                          const Positioned(
                            top: 4,
                            left: 4,
                            child: Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    _buildImagePlaceholder(context),

                  // Rating badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: isTablet ? 14 : 12,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            hotel.rating.toString(),
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 12 : 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content section
            SizedBox(
              height: contentHeight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel name - constrained height
                    Expanded(
                      flex: 2,
                      child: Text(
                        hotel.name,
                        style: GoogleFonts.poppins(
                          fontSize: isTablet ? 16 : 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Location - constrained height
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: isTablet ? 14 : 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              '${hotel.city}, ${hotel.country}',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 12 : 10,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Price - fixed height
                    SizedBox(
                      height: isTablet ? 20 : 16,
                      child: Row(
                        children: [
                          Text(
                            '\$${hotel.pricePerNight}',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 16 : 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            '/night',
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 12 : 10,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListCard(BuildContext context, bool isTablet) {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Image section
          Container(
            width: isTablet ? 140 : 120,
            height: isTablet ? 140 : 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hotel image
                if (hotel.images != null && hotel.images!.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showImageZoom(context, hotel.images!, 0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            child: Image.network(
                              _getFullImageUrl(hotel.images!.first),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                print('HotelCard: Image load error (list): $error');
                                return _buildImagePlaceholder(context);
                              },
                            ),
                          ),
                        ),
                        // Zoom indicator
                        const Positioned(
                          top: 4,
                          left: 4,
                          child: Icon(
                            Icons.zoom_in,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  _buildImagePlaceholder(context),

                // Rating badge
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: isTablet ? 14 : 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          hotel.rating.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content section
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 16 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel name
                  Text(
                    hotel.name,
                    style: GoogleFonts.poppins(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 4),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isTablet ? 16 : 14,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${hotel.city}, ${hotel.country}',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 14 : 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Amenities
                  if (hotel.amenities != null && hotel.amenities!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: hotel.amenities!.take(3).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            amenity,
                            style: GoogleFonts.poppins(
                              fontSize: isTablet ? 11 : 10,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  const Spacer(),

                  // Price row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              '\$${hotel.pricePerNight}',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 20 : 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              '/night',
                              style: GoogleFonts.poppins(
                                fontSize: isTablet ? 14 : 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hotel.availableRooms != null &&
                          hotel.availableRooms! > 0)
                        Text(
                          '${hotel.availableRooms} rooms left',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 12 : 10,
                            fontWeight: FontWeight.w500,
                            color: hotel.availableRooms! <= 3
                                ? Colors.orange
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Center(
        child: Icon(
          Icons.hotel,
          size: 48,
          color:
              Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
        ),
      ),
    );
  }

  void _showImageZoom(BuildContext context, List<String> imageUrls, int initialIndex) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                PageView.builder(
                  controller: PageController(initialPage: initialIndex),
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    return Center(
                      child: InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: _getFullImageUrl(imageUrls[index]),
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          ),
                          errorWidget: (context, url, error) => const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 24,
                        ),
                        tooltip: 'Close',
                      ),
                    ),
                  ),
                ),
                if (imageUrls.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${initialIndex + 1} / ${imageUrls.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
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
      },
    );
  }

  String _getFullImageUrl(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return imageUrl; // Already a full URL
    }
    
    // Remove leading slash if present
    final cleanUrl = imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl;
    
    // Construct full URL using the base URL from ApiService
    final fullUrl = '${ApiService.baseUrl.replaceAll('/api', '')}/$cleanUrl';
    print('HotelCard: Converting image URL: $imageUrl → $fullUrl');
    return fullUrl;
  }
}
