import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../models/review.dart';
import '../../widgets/review_card.dart';
import '../../utils/navigation_utils.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({Key? key}) : super(key: key);

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  
  List<Review> _reviews = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNextPage = false;
  bool _hasPrevPage = false;
  int _totalReviews = 0;

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
      final response = await _apiService.get('/reviews/user/my-reviews?page=$page&limit=5');
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Reviews',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: NavigationUtils.backButton(context),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
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

    if (_reviews.isEmpty) {
      return Center(
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
              'No Reviews Yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your reviews will appear here after you check out from bookings.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with count
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Reviews: $_totalReviews',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Page $_currentPage of $_totalPages',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        
        // Reviews list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ReviewCard(review: _reviews[index]),
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
    );
  }
}