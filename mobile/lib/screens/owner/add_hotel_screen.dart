import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// Conditional import for dart:io
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../blocs/hotels/hotels_bloc.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/location_picker.dart';
import '../../utils/navigation_utils.dart';
import '../../services/api_service.dart';

class AddHotelScreen extends StatefulWidget {
  const AddHotelScreen({Key? key}) : super(key: key);

  @override
  State<AddHotelScreen> createState() => _AddHotelScreenState();
}

class _AddHotelScreenState extends State<AddHotelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _priceController = TextEditingController();
  final _totalRoomsController = TextEditingController();

  // GlobalKeys for scrolling to validation errors
  final _nameFieldKey = GlobalKey();
  final _addressFieldKey = GlobalKey();
  final _cityFieldKey = GlobalKey();
  final _countryFieldKey = GlobalKey();
  final _priceFieldKey = GlobalKey();
  final _totalRoomsFieldKey = GlobalKey();
  final _locationFieldKey = GlobalKey();

  List<String> _selectedAmenities = [];
  List<XFile> _selectedImageFiles = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;
  
  // Location data
  double? _selectedLatitude;
  double? _selectedLongitude;
  String _selectedAddress = '';

  final List<String> _availableAmenities = [
    'WiFi',
    'Pool',
    'Spa',
    'Restaurant',
    'Bar',
    'Gym',
    'Parking',
    'Beach',
    'Business Center',
    'Fireplace',
    'Pet Friendly',
    'Room Service',
    'Laundry',
    'Airport Shuttle',
    'Breakfast',
  ];

  void _scrollToFirstError() {
    // Find the first field with an error and scroll to it
    if (_nameController.text.trim().isEmpty) {
      _scrollToWidget(_nameFieldKey);
    } else if (_addressController.text.trim().isEmpty) {
      _scrollToWidget(_addressFieldKey);
    } else if (_cityController.text.trim().isEmpty) {
      _scrollToWidget(_cityFieldKey);
    } else if (_countryController.text.trim().isEmpty) {
      _scrollToWidget(_countryFieldKey);
    } else if (_priceController.text.trim().isEmpty) {
      _scrollToWidget(_priceFieldKey);
    } else if (_totalRoomsController.text.trim().isEmpty) {
      _scrollToWidget(_totalRoomsFieldKey);
    } else if (_selectedLatitude == null || _selectedLongitude == null) {
      _scrollToWidget(_locationFieldKey);
    }
  }

  void _scrollToWidget(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Show the field near the top
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _priceController.dispose();
    _totalRoomsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Hotel',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: NavigationUtils.backButton(context),
      ),
      body: BlocConsumer<HotelsBloc, HotelsState>(
        listener: (context, state) {
          if (state is HotelActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
            context.pop();
          } else if (state is HotelsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel Images Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle('Hotel Images'),
                      Text(
                        '${_selectedImageFiles.length}/10',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _selectedImageFiles.length >= 10 
                              ? Colors.red 
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload up to 10 high-quality photos of your hotel',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildImageUploadSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Basic Information
                  _buildSectionTitle('Basic Information'),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _nameController,
                    label: 'Hotel Name',
                    hint: 'Enter hotel name',
                    icon: Icons.hotel,
                    isRequired: true,
                    fieldKey: _nameFieldKey,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Describe your hotel...',
                    icon: Icons.description,
                    maxLines: 4,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Location Information
                  _buildSectionTitle('Location'),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Street address',
                    icon: Icons.location_on,
                    isRequired: true,
                    fieldKey: _addressFieldKey,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _cityController,
                          label: 'City',
                          hint: 'City name',
                          icon: Icons.location_city,
                          isRequired: true,
                          fieldKey: _cityFieldKey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _countryController,
                          label: 'Country',
                          hint: 'Country name',
                          icon: Icons.flag,
                          isRequired: true,
                          fieldKey: _countryFieldKey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // GPS Location Section
                  _buildLocationSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Pricing & Capacity
                  _buildSectionTitle('Pricing & Capacity'),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Price per Night (\$)',
                          hint: '0.00',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          fieldKey: _priceFieldKey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _totalRoomsController,
                          label: 'Total Rooms',
                          hint: '0',
                          icon: Icons.meeting_room,
                          keyboardType: TextInputType.number,
                          isRequired: true,
                          fieldKey: _totalRoomsFieldKey,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Amenities
                  _buildSectionTitle('Amenities'),
                  const SizedBox(height: 12),
                  Text(
                    'Select all amenities available at your hotel',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAmenitiesSection(),
                  
                  const SizedBox(height: 48),
                  
                  // Submit Button
                  BlocBuilder<HotelsBloc, HotelsState>(
                    builder: (context, state) {
                      return CustomButton(
                        text: _isUploadingImages ? 'Uploading Images...' : 'Add Hotel',
                        onPressed: _submitHotel,
                        isLoading: state is HotelActionLoading || _isUploadingImages,
                        icon: Icons.add,
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onBackground,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool isRequired = false,
    GlobalKey? fieldKey,
  }) {
    return Column(
      key: fieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        CustomTextField(
          controller: controller,
          hintText: hint,
          prefixIcon: Icon(icon),
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: isRequired
              ? (value) {
                  if (value?.isEmpty ?? true) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          if (_selectedImageFiles.isEmpty) ...[
            Icon(
              Icons.add_photo_alternate,
              size: 48,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Add Hotel Photos',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload high-quality photos of your hotel',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0, // Ensure square aspect ratio
              ),
              itemCount: _selectedImageFiles.length + 1,
              itemBuilder: (context, index) {
                if (index == _selectedImageFiles.length) {
                  return _buildAddImageButton();
                }
                return AspectRatio(
                  aspectRatio: 1.0,
                  child: _buildImageItem(_selectedImageFiles[index], index),
                );
              },
            ),
          ],
          
          if (_selectedImageFiles.isEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Choose Photos'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAddImageButton() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildImageItem(XFile imageFile, int index) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[300],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: GestureDetector(
              onTap: () => _showImageZoom(imageFile),
              child: SizedBox.expand(
                child: _buildSafeImageWidget(imageFile),
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
          // Remove button
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedImageFiles.removeAt(index);
                });
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeImageWidget(XFile imageFile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ensure we have valid constraints
        if (constraints.maxWidth == double.infinity || constraints.maxHeight == double.infinity) {
          return Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 32, color: Colors.grey),
          );
        }
        
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: kIsWeb 
              ? Image.network(
                  imageFile.path,
                  fit: BoxFit.cover,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error, size: 32, color: Colors.grey),
                      ),
                    );
                  },
                )
              : FutureBuilder<Uint8List>(
                  future: imageFile.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }
                    
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Icon(Icons.error, size: 32, color: Colors.grey),
                      );
                    }
                    
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 32, color: Colors.grey),
                          ),
                        );
                      },
                    );
                  },
                ),
          ),
        );
      },
    );
  }

  Widget _buildLocationSection() {
    return Column(
      key: _locationFieldKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'GPS Location',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            Text(
              ' (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedAddress.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAddress,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Lat: ${_selectedLatitude?.toStringAsFixed(6) ?? 'N/A'}, '
                  'Lng: ${_selectedLongitude?.toStringAsFixed(6) ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectLocation,
                      icon: const Icon(Icons.map, size: 18),
                      label: Text(
                        _selectedAddress.isEmpty ? 'Select Location' : 'Change Location',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  if (_selectedAddress.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _clearLocation,
                      icon: const Icon(Icons.clear, size: 16),
                      label: Text(
                        'Clear',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Wrap(
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
    );
  }

  void _pickImages() async {
    try {
      // Check if we're at the limit
      if (_selectedImageFiles.length >= 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum 10 images allowed'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        // Check total count after adding new images
        int totalAfterAdd = _selectedImageFiles.length + images.length;
        List<XFile> imagesToAdd = images;
        
        if (totalAfterAdd > 10) {
          int allowedCount = 10 - _selectedImageFiles.length;
          imagesToAdd = images.take(allowedCount).toList();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Only $allowedCount images added (maximum 10 total)'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        
        setState(() {
          _selectedImageFiles.addAll(imagesToAdd);
        });
        
        if (totalAfterAdd <= 10) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${imagesToAdd.length} image(s) selected'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _selectLocation() async {
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LocationPicker(
            initialLatitude: _selectedLatitude,
            initialLongitude: _selectedLongitude,
            initialAddress: _selectedAddress,
            onLocationSelected: (latitude, longitude, address, street, city, country) {
              setState(() {
                _selectedLatitude = latitude;
                _selectedLongitude = longitude;
                _selectedAddress = address;
                
                // Auto-fill the text controllers with parsed address components
                if (street.isNotEmpty) {
                  _addressController.text = street;
                }
                if (city.isNotEmpty) {
                  _cityController.text = city;
                }
                if (country.isNotEmpty) {
                  _countryController.text = country;
                }
              });
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening location picker: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearLocation() {
    setState(() {
      _selectedLatitude = null;
      _selectedLongitude = null;
      _selectedAddress = '';
    });
  }

  void _showImageZoom(XFile imageFile) {
    final TransformationController transformationController = TransformationController();
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    transformationController: transformationController,
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.1,
                    maxScale: 5.0,
                    scaleEnabled: true,
                    child: kIsWeb 
                      ? Image.network(
                          imageFile.path,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 64,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : FutureBuilder<Uint8List>(
                          future: imageFile.readAsBytes(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              );
                            }
                            
                            if (snapshot.hasError || !snapshot.hasData) {
                              return const Center(
                                child: Icon(
                                  Icons.error,
                                  size: 64,
                                  color: Colors.white,
                                ),
                              );
                            }
                            
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                  ),
                ),
                // Zoom controls
                Positioned(
                  bottom: 100,
                  right: 16,
                  child: Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () {
                              final Matrix4 matrix = Matrix4.copy(transformationController.value);
                              matrix.scale(1.2);
                              transformationController.value = matrix;
                            },
                            icon: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Zoom In',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () {
                              final Matrix4 matrix = Matrix4.copy(transformationController.value);
                              matrix.scale(0.8);
                              transformationController.value = matrix;
                            },
                            icon: const Icon(
                              Icons.zoom_out,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Zoom Out',
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: IconButton(
                            onPressed: () {
                              transformationController.value = Matrix4.identity();
                            },
                            icon: const Icon(
                              Icons.center_focus_strong,
                              color: Colors.white,
                              size: 24,
                            ),
                            tooltip: 'Reset Zoom',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Close button
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
              ],
            ),
          ),
        );
      },
    );
  }

  void _submitHotel() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isUploadingImages = true;
      });
      
      try {
        // Upload images first if any are selected
        List<String> imageUrls = [];
        if (_selectedImageFiles.isNotEmpty) {
          final apiService = ApiService.instance;
          
          // Convert File objects to the new format expected by the API
          List<Map<String, dynamic>> imageData = [];
          for (int i = 0; i < _selectedImageFiles.length; i++) {
            final file = _selectedImageFiles[i];
            final bytes = await file.readAsBytes();
            final fileName = file.name;
            imageData.add({
              'name': fileName,
              'bytes': bytes,
            });
          }
          
          imageUrls = await apiService.uploadHotelImages(imageData, hotelName: _nameController.text.trim());
          
          setState(() {
            _uploadedImageUrls = imageUrls;
          });
        }
        
        final hotelData = {
          'name': _nameController.text.trim(),
          'description': _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          'address': _addressController.text.trim(),
          'city': _cityController.text.trim(),
          'country': _countryController.text.trim(),
          'price_per_night': double.parse(_priceController.text),
          'amenities': _selectedAmenities,
          'total_rooms': int.parse(_totalRoomsController.text),
          'latitude': _selectedLatitude,
          'longitude': _selectedLongitude,
          'images': imageUrls,
        };
        
        context.read<HotelsBloc>().add(HotelCreateEvent(hotelData: hotelData));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isUploadingImages = false;
        });
      }
    } else {
      // Validation failed, scroll to first error
      _scrollToFirstError();
    }
  }
}