import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/review.dart';
import 'package:intl/intl.dart';

class ReviewCard extends StatelessWidget {
  final Review review;
  final bool showHotel;

  const ReviewCard({
    Key? key,
    required this.review,
    this.showHotel = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with hotel info and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hotel image
                if (showHotel && review.hotel != null)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[200],
                    ),
                    child: review.hotel!.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              review.hotel!.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.hotel,
                                  color: Colors.grey,
                                  size: 30,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.hotel,
                            color: Colors.grey,
                            size: 30,
                          ),
                  ),
                
                if (showHotel && review.hotel != null)
                  const SizedBox(width: 12),

                // Hotel info and rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (showHotel && review.hotel != null) ...[
                        Text(
                          review.hotel!.name,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          review.hotel!.location,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Rating and date
                      Row(
                        children: [
                          _buildStarRating(review.rating),
                          const SizedBox(width: 8),
                          Text(
                            review.ratingText,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _getRatingColor(review.rating),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd, yyyy').format(review.createdAt),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Review',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.comment!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Owner reply
            if (review.hasOwnerReply) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue[200]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.reply,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Hotel Owner Reply',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      review.ownerReply!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.blue[900],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.orange;
    return Colors.red;
  }
}