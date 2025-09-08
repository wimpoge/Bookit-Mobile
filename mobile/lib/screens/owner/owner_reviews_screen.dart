import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/review.dart';
import '../../widgets/owner_review_card.dart';
import '../../utils/navigation_utils.dart';

class OwnerReviewsScreen extends StatefulWidget {
  const OwnerReviewsScreen({Key? key}) : super(key: key);

  @override
  State<OwnerReviewsScreen> createState() => _OwnerReviewsScreenState();
}

class _OwnerReviewsScreenState extends State<OwnerReviewsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  List<Review> _reviews = [];
  List<Map<String, dynamic>> _hotels = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  int _totalReviews = 0;
  int _totalUnreplied = 0;
  
  // Filters
  String? _selectedHotelId;
  int? _selectedRating;
  bool _showOnlyNeedsReply = false;
  String _sortBy = 'newest';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      String url = '/reviews/owner/my-hotels-reviews?page=$page&limit=10&sort_by=$_sortBy';
      
      if (_selectedHotelId != null) {
        url += '&hotel_id=$_selectedHotelId';
      }
      if (_selectedRating != null) {
        url += '&rating_filter=$_selectedRating';
      }
      if (_showOnlyNeedsReply) {
        url += '&needs_reply=true';
      }
      
      final response = await _apiService.get(url);
      
      if (response['reviews'] != null) {
        setState(() {
          _reviews = (response['reviews'] as List)
              .map((json) => Review.fromJson(json))
              .toList();
          _currentPage = response['pagination']['current_page'] ?? 1;
          _totalPages = response['pagination']['total_pages'] ?? 1;
          _hasNextPage = response['pagination']['has_next'] ?? false;
          _hasPrevPage = response['pagination']['has_prev'] ?? false;
          _totalReviews = response['pagination']['total_reviews'] ?? 0;
          _totalUnreplied = response['summary']['total_unreplied'] ?? 0;
          _hotels = List<Map<String, dynamic>>.from(response['hotels'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_hasNextPage) {
      _loadReviews(page: _currentPage + 1);
    }
  }

  void _prevPage() {
    if (_hasPrevPage) {
      _loadReviews(page: _currentPage - 1);
    }
  }

  void _applyFilters() {
    _loadReviews(page: 1);
  }

  void _clearFilters() {
    setState(() {
      _selectedHotelId = null;
      _selectedRating = null;
      _showOnlyNeedsReply = false;
      _sortBy = 'newest';
    });
    _loadReviews(page: 1);
  }

  Future<void> _replyToReview(String reviewId, String reply) async {
    try {
      await _apiService.put('/reviews/$reviewId/reply', {
        'owner_reply': reply,
      });
      _loadReviews(page: _currentPage);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send reply: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews Management',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: NavigationUtils.backButton(context),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading reviews',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadReviews(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Summary header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryItem('Total Reviews', _totalReviews.toString()),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildSummaryItem('Needs Reply', _totalUnreplied.toString(),
                  color: _totalUnreplied > 0 ? Colors.red : Colors.green),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey[300],
              ),
              _buildSummaryItem('Page', '$_currentPage of $_totalPages'),
            ],
          ),
        ),

        // Active filters
        if (_selectedHotelId != null ||
            _selectedRating != null ||
            _showOnlyNeedsReply ||
            _sortBy != 'newest')
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_selectedHotelId != null)
                  _buildFilterChip(
                    'Hotel: ${_hotels.firstWhere((h) => h['id'] == _selectedHotelId)['name']}',
                    () => setState(() {
                      _selectedHotelId = null;
                      _applyFilters();
                    }),
                  ),
                if (_selectedRating != null)
                  _buildFilterChip(
                    '$_selectedRating Star${_selectedRating! > 1 ? 's' : ''}',
                    () => setState(() {
                      _selectedRating = null;
                      _applyFilters();
                    }),
                  ),
                if (_showOnlyNeedsReply)
                  _buildFilterChip(
                    'Needs Reply',
                    () => setState(() {
                      _showOnlyNeedsReply = false;
                      _applyFilters();
                    }),
                  ),
                if (_sortBy != 'newest')
                  _buildFilterChip(
                    'Sort: ${_sortBy.replaceAll('_', ' ').split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ')}',
                    () => setState(() {
                      _sortBy = 'newest';
                      _applyFilters();
                    }),
                  ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ),

        if (_reviews.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.rate_review_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Reviews Found',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reviews from your hotel guests will appear here.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          )
        else ...[
          // Reviews list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: OwnerReviewCard(
                    review: _reviews[index],
                    onReply: _replyToReview,
                  ),
                );
              },
            ),
          ),

          // Pagination controls
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _hasPrevPage ? _prevPage : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasPrevPage ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  Text(
                    '$_currentPage / $_totalPages',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _hasNextPage ? _nextPage : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasNextPage ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.blue,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Chip(
      label: Text(label),
      onDeleted: onRemove,
      deleteIcon: const Icon(Icons.close, size: 16),
      backgroundColor: Colors.blue[100],
      labelStyle: GoogleFonts.poppins(fontSize: 12),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Reviews',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              
              // Hotel filter
              Text(
                'Hotel',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String?>(
                value: _selectedHotelId,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All Hotels',
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All Hotels'),
                  ),
                  ..._hotels.map((hotel) => DropdownMenuItem<String?>(
                        value: hotel['id'].toString(),
                        child: Text(hotel['name']),
                      )),
                ],
                onChanged: (value) => setModalState(() => _selectedHotelId = value),
              ),
              const SizedBox(height: 16),

              // Rating filter
              Text(
                'Rating',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<int?>(
                value: _selectedRating,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'All Ratings',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('All Ratings'),
                  ),
                  for (int i = 5; i >= 1; i--)
                    DropdownMenuItem<int?>(
                      value: i,
                      child: Row(
                        children: [
                          for (int j = 0; j < i; j++)
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 8),
                          Text('$i Star${i > 1 ? 's' : ''}'),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) => setModalState(() => _selectedRating = value),
              ),
              const SizedBox(height: 16),

              // Sort by
              Text(
                'Sort By',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _sortBy,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'newest', child: Text('Newest First')),
                  DropdownMenuItem(value: 'oldest', child: Text('Oldest First')),
                  DropdownMenuItem(value: 'rating_high', child: Text('Highest Rating')),
                  DropdownMenuItem(value: 'rating_low', child: Text('Lowest Rating')),
                ],
                onChanged: (value) => setModalState(() => _sortBy = value!),
              ),
              const SizedBox(height: 16),

              // Needs reply toggle
              SwitchListTile(
                title: Text(
                  'Show only reviews that need replies',
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
                value: _showOnlyNeedsReply,
                onChanged: (value) => setModalState(() => _showOnlyNeedsReply = value),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          _selectedHotelId = null;
                          _selectedRating = null;
                          _showOnlyNeedsReply = false;
                          _sortBy = 'newest';
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {}); // Update main state
                        Navigator.pop(context);
                        _applyFilters();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}