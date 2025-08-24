import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/review.dart';
import 'package:intl/intl.dart';

class OwnerReviewCard extends StatefulWidget {
  final Review review;
  final Function(int reviewId, String reply) onReply;

  const OwnerReviewCard({
    Key? key,
    required this.review,
    required this.onReply,
  }) : super(key: key);

  @override
  State<OwnerReviewCard> createState() => _OwnerReviewCardState();
}

class _OwnerReviewCardState extends State<OwnerReviewCard> {
  final TextEditingController _replyController = TextEditingController();
  bool _isReplyMode = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.review.ownerReply != null) {
      _replyController.text = widget.review.ownerReply!;
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  void _toggleReplyMode() {
    setState(() {
      _isReplyMode = !_isReplyMode;
      if (!_isReplyMode) {
        _replyController.text = widget.review.ownerReply ?? '';
      }
    });
  }

  void _submitReply() async {
    if (_replyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a reply'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onReply(widget.review.id, _replyController.text.trim());
      setState(() {
        _isReplyMode = false;
        _isSubmitting = false;
      });
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

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
            // Header with user info and hotel
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  backgroundImage: widget.review.user?.profileImage != null
                      ? NetworkImage(widget.review.user!.profileImage!)
                      : null,
                  child: widget.review.user?.profileImage == null
                      ? Text(
                          widget.review.user?.fullName?.substring(0, 1).toUpperCase() ?? 'G',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.review.user?.fullName ?? 'Guest',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (widget.review.needsReply == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Needs Reply',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[700],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Hotel name
                      if (widget.review.hotel != null) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.hotel,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.review.hotel!.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      
                      // Rating and date
                      Row(
                        children: [
                          _buildStarRating(widget.review.rating),
                          const SizedBox(width: 8),
                          Text(
                            widget.review.ratingText,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getRatingColor(widget.review.rating),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('MMM dd, yyyy').format(widget.review.createdAt),
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
            
            // Guest review
            if (widget.review.comment != null && widget.review.comment!.isNotEmpty) ...[
              const SizedBox(height: 16),
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
                      'Guest Review',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.review.comment!,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Owner reply section
            const SizedBox(height: 16),
            
            if (!_isReplyMode) ...[
              // Show existing reply or reply button
              if (widget.review.hasOwnerReply) ...[
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
                            'Your Reply',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue[600],
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: _toggleReplyMode,
                            child: Text(
                              'Edit',
                              style: GoogleFonts.poppins(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.review.ownerReply!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          height: 1.5,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Reply button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _toggleReplyMode,
                    icon: const Icon(Icons.reply),
                    label: const Text('Reply to Review'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Reply input mode
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
                    Text(
                      widget.review.hasOwnerReply ? 'Edit Your Reply' : 'Reply to Guest',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _replyController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Write your reply to the guest...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _isSubmitting ? null : _toggleReplyMode,
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitReply,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(widget.review.hasOwnerReply ? 'Update Reply' : 'Send Reply'),
                          ),
                        ),
                      ],
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