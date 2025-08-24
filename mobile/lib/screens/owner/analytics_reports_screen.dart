import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import '../../utils/navigation_utils.dart';
import '../../services/api_service.dart';

class AnalyticsReportsScreen extends StatefulWidget {
  const AnalyticsReportsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsReportsScreen> createState() => _AnalyticsReportsScreenState();
}

class _AnalyticsReportsScreenState extends State<AnalyticsReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  bool _isLoading = false;
  
  // Real data from API
  Map<String, dynamic> _analyticsData = {};
  List<FlSpot> _revenueChartData = [];
  List<FlSpot> _bookingsChartData = [];
  List<double> _occupancyData = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);
    _error = null;
    
    try {
      final apiService = ApiService();
      
      // Get period parameter for API
      final periodParam = _selectedPeriod.toLowerCase().replaceAll(' ', '_');
      
      // Load overview data
      final overviewResponse = await apiService.get('/analytics/overview?period=$periodParam');
      
      // Load revenue trend
      final revenueResponse = await apiService.get('/analytics/revenue-trend?period=$periodParam');
      
      // Load bookings trend  
      final bookingsResponse = await apiService.get('/analytics/bookings-trend?period=$periodParam');
      
      // Load guest ratings
      final ratingsResponse = await apiService.get('/analytics/guest-ratings?period=$periodParam');
      
      // Load revenue breakdown
      final breakdownResponse = await apiService.get('/analytics/revenue-breakdown?period=$periodParam');
      
      if (mounted) {
        setState(() {
          _analyticsData = {
            'overview': overviewResponse,
            'revenue_trend': revenueResponse,
            'bookings_trend': bookingsResponse,
            'guest_ratings': ratingsResponse,
            'revenue_breakdown': breakdownResponse,
          };
          
          // Process chart data
          _processChartData();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }
  
  void _processChartData() {
    // Process revenue chart data
    if (_analyticsData['revenue_trend']?['chart_data'] != null) {
      _revenueChartData = (_analyticsData['revenue_trend']['chart_data'] as List)
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value['value'].toDouble()))
          .toList();
    } else {
      // Fallback data
      _revenueChartData = [
        FlSpot(0, 1200), FlSpot(1, 1350), FlSpot(2, 1100), 
        FlSpot(3, 1500), FlSpot(4, 1800), FlSpot(5, 1650), FlSpot(6, 1900),
      ];
    }
    
    // Process bookings chart data
    if (_analyticsData['bookings_trend']?['chart_data'] != null) {
      _bookingsChartData = (_analyticsData['bookings_trend']['chart_data'] as List)
          .asMap()
          .entries
          .map((entry) => FlSpot(entry.key.toDouble(), entry.value['value'].toDouble()))
          .toList();
    } else {
      // Fallback data
      _bookingsChartData = [
        FlSpot(0, 32), FlSpot(1, 28), FlSpot(2, 35), 
        FlSpot(3, 40), FlSpot(4, 45), FlSpot(5, 38), FlSpot(6, 42),
      ];
    }
    
    // Process occupancy data (simplified for bar chart)
    _occupancyData = [65, 70, 75, 80, 85, 78, 82];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Analytics & Reports',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: NavigationUtils.backButton(context),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'export_pdf':
                  _exportToPDF();
                  break;
                case 'export_excel':
                  _exportToExcel();
                  break;
                case 'share':
                  _shareReport();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    const Icon(Icons.picture_as_pdf, color: Colors.red),
                    const SizedBox(width: 8),
                    Text('Export PDF', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_excel',
                child: Row(
                  children: [
                    const Icon(Icons.table_chart, color: Colors.green),
                    const SizedBox(width: 8),
                    Text('Export Excel', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share),
                    const SizedBox(width: 8),
                    Text('Share Report', style: GoogleFonts.poppins()),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'Overview'),
            Tab(text: 'Revenue'),
            Tab(text: 'Bookings'),
            Tab(text: 'Guests'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Period Selector
          _buildPeriodSelector(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRevenueTab(),
                _buildBookingsTab(),
                _buildGuestsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Period:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _selectedPeriod,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: [
                'Today',
                'Yesterday',
                'This Week',
                'Last Week',
                'This Month',
                'Last Month',
                'This Year',
                'Last Year',
                'Custom Range',
              ].map((period) => DropdownMenuItem(
                value: period,
                child: Text(period, style: GoogleFonts.poppins()),
              )).toList(),
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
                _loadAnalyticsData();
              },
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _loadAnalyticsData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          _buildKPICards(),
          
          const SizedBox(height: 24),
          
          // Revenue Chart
          _buildSectionTitle('Revenue Trend'),
          const SizedBox(height: 16),
          _buildRevenueChart(),
          
          const SizedBox(height: 24),
          
          // Occupancy Rate
          _buildSectionTitle('Occupancy Rate'),
          const SizedBox(height: 16),
          _buildOccupancyChart(),
          
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildKPICards() {
    if (_isLoading) {
      return Container(
        height: 150,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Container(
        height: 150,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 8),
              Text('Failed to load analytics data', style: GoogleFonts.poppins()),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: _loadAnalyticsData,
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    final overview = _analyticsData['overview'];
    final metrics = overview?['metrics'] ?? {};
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          'Total Revenue',
          '\$${(metrics['revenue']?['total'] ?? 0.0).toStringAsFixed(2)}',
          '${(metrics['revenue']?['growth'] ?? 0.0) >= 0 ? '+' : ''}${(metrics['revenue']?['growth'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.attach_money,
          Colors.green,
        ),
        _buildKPICard(
          'Total Bookings',
          '${metrics['bookings']?['total'] ?? 0}',
          '${(metrics['bookings']?['growth'] ?? 0.0) >= 0 ? '+' : ''}${(metrics['bookings']?['growth'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.book_online,
          Colors.blue,
        ),
        _buildKPICard(
          'Occupancy Rate',
          '${(metrics['occupancy_rate']?['rate'] ?? 0.0).toStringAsFixed(1)}%',
          '${(metrics['occupancy_rate']?['growth'] ?? 0.0) >= 0 ? '+' : ''}${(metrics['occupancy_rate']?['growth'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.hotel,
          Colors.orange,
        ),
        _buildKPICard(
          'Total Guests',
          '${metrics['guests']?['total'] ?? 0}',
          '${(metrics['guests']?['growth'] ?? 0.0) >= 0 ? '+' : ''}${(metrics['guests']?['growth'] ?? 0.0).toStringAsFixed(1)}%',
          Icons.people,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, String growth, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  growth,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Revenue Analytics'),
          const SizedBox(height: 16),
          _buildRevenueChart(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Revenue Breakdown'),
          const SizedBox(height: 16),
          _buildRevenueBreakdown(),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Booking Trends'),
          const SizedBox(height: 16),
          _buildBookingsChart(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Booking Sources'),
          const SizedBox(height: 16),
          _buildBookingSourcesChart(),
        ],
      ),
    );
  }

  Widget _buildGuestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Guest Ratings'),
          const SizedBox(height: 16),
          _buildGuestRatingsChart(),
          
          const SizedBox(height: 24),
          
          _buildSectionTitle('Guest Demographics'),
          const SizedBox(height: 16),
          _buildGuestDemographics(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildRevenueChart() {
    if (_isLoading) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, 
            drawHorizontalLine: true, 
            drawVerticalLine: false,
            horizontalInterval: null,
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        days[value.toInt()], 
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  if (value < 1000) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '\$${value.toInt()}', 
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        '\$${(value/1000).toStringAsFixed(1)}k', 
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _revenueChartData,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Theme.of(context).colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
          minX: 0,
          maxX: 6,
          minY: 0,
          maxY: null, // Auto-calculate
        ),
      ),
    );
  }

  Widget _buildOccupancyChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: GoogleFonts.poppins(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('${value.toInt()}%', style: GoogleFonts.poppins(fontSize: 10));
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: _occupancyData
              .asMap()
              .entries
              .map<BarChartGroupData>((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: entry.value,
                  color: Theme.of(context).colorScheme.secondary,
                  width: 20,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final breakdown = _analyticsData['revenue_breakdown']?['breakdown'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: breakdown.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('No revenue data available', style: GoogleFonts.poppins()),
            ),
          )
        : Column(
            children: breakdown.map<Widget>((item) => 
              _buildRevenueItem(
                item['category'], 
                item['amount'].toDouble(), 
                item['percentage'].toDouble()
              )
            ).toList(),
          ),
    );
  }

  Widget _buildRevenueItem(String label, double amount, double percentage) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 60,
            child: Text(
              '${(percentage * 100).toStringAsFixed(0)}%',
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsChart() {
    if (_isLoading) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: GoogleFonts.poppins(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(value.toInt().toString(), style: GoogleFonts.poppins(fontSize: 10));
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _bookingsChartData,
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: Colors.blue,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSourcesChart() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(value: 45, color: Colors.blue, title: '45%', titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            PieChartSectionData(value: 30, color: Colors.green, title: '30%', titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            PieChartSectionData(value: 15, color: Colors.orange, title: '15%', titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            PieChartSectionData(value: 10, color: Colors.red, title: '10%', titleStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildGuestRatingsChart() {
    final ratingsData = _analyticsData['guest_ratings'];
    final ratings = ratingsData?['ratings_distribution'] ?? [];
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Average Rating',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  Text(
                    ' ${(ratingsData?['average_rating'] ?? 0.0).toStringAsFixed(1)}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ratings.isEmpty 
              ? Center(child: Text('No ratings yet', style: GoogleFonts.poppins()))
              : Column(
                  children: ratings
                      .map<Widget>((rating) => _buildRatingBar(rating['rating'], rating['count']))
                      .toList(),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int rating, int count) {
    final ratingsData = _analyticsData['guest_ratings'];
    final totalReviews = ratingsData?['total_reviews'] ?? 1;
    final percentage = totalReviews > 0 ? count / totalReviews : 0.0;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text('$rating ⭐', style: GoogleFonts.poppins(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              color: Colors.amber,
              minHeight: 8,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              '$count (${(percentage * 100).toStringAsFixed(0)}%)',
              style: GoogleFonts.poppins(fontSize: 12),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestDemographics() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDemographicItem('Business Travelers', '35%', Colors.blue),
          _buildDemographicItem('Leisure Travelers', '45%', Colors.green),
          _buildDemographicItem('Families', '15%', Colors.orange),
          _buildDemographicItem('Groups', '5%', Colors.red),
        ],
      ),
    );
  }

  Widget _buildDemographicItem(String label, String percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ),
          Text(
            percentage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    try {
      setState(() => _isLoading = true);

      final pdf = pw.Document();
      
      pdf.addPage(
        pw.MultiPage(
          build: (pw.Context context) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Analytics Report - $_selectedPeriod',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text('Revenue: \$${_analyticsData['revenue']['total'].toStringAsFixed(2)}'),
            pw.Text('Bookings: ${_analyticsData['bookings']['total']}'),
            pw.Text('Occupancy Rate: ${_analyticsData['occupancy']['rate']}%'),
            pw.Text('Total Guests: ${_analyticsData['guests']['total']}'),
            pw.SizedBox(height: 20),
            pw.Text('Generated on: ${DateTime.now().toString()}'),
          ],
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/analytics_report.pdf');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported successfully to ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting PDF: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportToExcel() async {
    try {
      setState(() => _isLoading = true);

      final excel = Excel.createExcel();
      final sheet = excel['Analytics Report'];

      // Add headers
      sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('Metric');
      sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('Value');
      sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Growth');

      // Add data
      sheet.cell(CellIndex.indexByString('A2')).value = TextCellValue('Revenue');
      sheet.cell(CellIndex.indexByString('B2')).value = DoubleCellValue(_analyticsData['revenue']['total']);
      sheet.cell(CellIndex.indexByString('C2')).value = TextCellValue('${_analyticsData['revenue']['growth']}%');

      sheet.cell(CellIndex.indexByString('A3')).value = TextCellValue('Bookings');
      sheet.cell(CellIndex.indexByString('B3')).value = IntCellValue(_analyticsData['bookings']['total']);
      sheet.cell(CellIndex.indexByString('C3')).value = TextCellValue('${_analyticsData['bookings']['growth']}%');

      sheet.cell(CellIndex.indexByString('A4')).value = TextCellValue('Occupancy Rate');
      sheet.cell(CellIndex.indexByString('B4')).value = DoubleCellValue(_analyticsData['occupancy']['rate']);
      sheet.cell(CellIndex.indexByString('C4')).value = TextCellValue('${_analyticsData['occupancy']['growth']}%');

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/analytics_report.xlsx');
      await file.writeAsBytes(excel.save()!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Excel exported successfully to ${file.path}'),
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => Share.shareXFiles([XFile(file.path)]),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting Excel: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareReport() async {
    final text = '''
Analytics Report - $_selectedPeriod

Revenue: \$${_analyticsData['revenue']['total'].toStringAsFixed(2)} (+${_analyticsData['revenue']['growth']}%)
Bookings: ${_analyticsData['bookings']['total']} (+${_analyticsData['bookings']['growth']}%)
Occupancy Rate: ${_analyticsData['occupancy']['rate']}% (+${_analyticsData['occupancy']['growth']}%)
Total Guests: ${_analyticsData['guests']['total']} (+${_analyticsData['guests']['growth']}%)

Generated by BookIt Analytics
    ''';
    
    await Share.share(text);
  }
}