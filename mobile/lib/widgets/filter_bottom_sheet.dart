import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'custom_button.dart';
import 'custom_text_field.dart';

class FilterBottomSheet extends StatefulWidget {
  final Function(Map<String, dynamic>) onApplyFilters;

  const FilterBottomSheet({
    Key? key,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final _cityController = TextEditingController();
  RangeValues _priceRange = const RangeValues(50, 500);
  List<String> _selectedAmenities = [];
  bool _amenitiesMatchAll = false;

  final List<String> _availableAmenities = [
    'WiFi',
    'Pool',
    'Spa',
    'Bar',
    'Gym',
    'Parking',
    'Beach',
    'Restaurant',
    'Business Center',
    'Fireplace',
  ];

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'city': _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      'minPrice': _priceRange.start,
      'maxPrice': _priceRange.end,
      'amenities': _selectedAmenities.isEmpty ? null : _selectedAmenities,
      'amenitiesMatchAll': _amenitiesMatchAll,
    };

    widget.onApplyFilters(filters);
    Navigator.of(context).pop();
  }

  void _clearFilters() {
    setState(() {
      _cityController.clear();
      _priceRange = const RangeValues(50, 500);
      _selectedAmenities.clear();
      _amenitiesMatchAll = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Filter Hotels',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
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
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionTitle(title: 'Location'),
                  const SizedBox(height: 12),
                  CustomTextField(
                    controller: _cityController,
                    hintText: 'Enter city name',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle(title: 'Price Range'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '\$${_priceRange.start.round()}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            Text(
                              '\$${_priceRange.end.round()}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        RangeSlider(
                          values: _priceRange,
                          min: 0,
                          max: 1000,
                          divisions: 100,
                          activeColor: Theme.of(context).colorScheme.primary,
                          inactiveColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.3),
                          onChanged: (values) {
                            setState(() {
                              _priceRange = values;
                            });
                          },
                        ),
                        Text(
                          'per night',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _SectionTitle(title: 'Amenities'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _amenitiesMatchAll,
                          onChanged: (value) {
                            setState(() {
                              _amenitiesMatchAll = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Must have ALL selected amenities',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableAmenities.map((amenity) {
                      final isSelected = _selectedAmenities.contains(amenity);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedAmenities.remove(amenity);
                            } else {
                              _selectedAmenities.add(amenity);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            amenity,
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
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Reset',
                    onPressed: _clearFilters,
                    isOutlined: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Apply Filters',
                    onPressed: _applyFilters,
                    icon: Icons.search,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }
}
