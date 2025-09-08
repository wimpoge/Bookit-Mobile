import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiscountDialog extends StatefulWidget {
  final String hotelName;
  final double currentPrice;
  final double? currentDiscountPercentage;
  final Function(double discountPercentage) onApplyDiscount;
  final VoidCallback? onRemoveDiscount;

  const DiscountDialog({
    Key? key,
    required this.hotelName,
    required this.currentPrice,
    this.currentDiscountPercentage,
    required this.onApplyDiscount,
    this.onRemoveDiscount,
  }) : super(key: key);

  @override
  State<DiscountDialog> createState() => _DiscountDialogState();
}

class _DiscountDialogState extends State<DiscountDialog> {
  final TextEditingController _discountController = TextEditingController();
  double _discountPercentage = 0.0;
  double _discountedPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _discountPercentage = widget.currentDiscountPercentage ?? 0.0;
    _discountController.text = _discountPercentage > 0 ? _discountPercentage.toStringAsFixed(0) : '';
    _updateDiscountedPrice();
  }

  void _updateDiscountedPrice() {
    setState(() {
      _discountedPrice = widget.currentPrice * (1 - _discountPercentage / 100);
    });
  }

  void _onDiscountChanged(String value) {
    double? percentage = double.tryParse(value);
    if (percentage != null && percentage >= 0 && percentage <= 100) {
      setState(() {
        _discountPercentage = percentage;
      });
      _updateDiscountedPrice();
    } else {
      setState(() {
        _discountPercentage = 0.0;
      });
      _updateDiscountedPrice();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set Discount',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.hotelName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Discount Percentage',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _discountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter discount percentage (0-100)',
                suffixText: '%',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              onChanged: _onDiscountChanged,
            ),
            
            const SizedBox(height: 20),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Original Price:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      Text(
                        '\$${widget.currentPrice.toStringAsFixed(0)}/night',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          decoration: _discountPercentage > 0 ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ],
                  ),
                  
                  if (_discountPercentage > 0) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Discounted Price:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          '\$${_discountedPrice.toStringAsFixed(0)}/night',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'You Save:',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '\$${(widget.currentPrice - _discountedPrice).toStringAsFixed(0)}/night (${_discountPercentage.toStringAsFixed(0)}%)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                if (widget.currentDiscountPercentage != null && widget.currentDiscountPercentage! > 0 && widget.onRemoveDiscount != null)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        widget.onRemoveDiscount!();
                        Navigator.of(context).pop();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.red),
                      ),
                      child: Text(
                        'Remove Discount',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                
                if (widget.currentDiscountPercentage != null && widget.currentDiscountPercentage! > 0 && widget.onRemoveDiscount != null)
                  const SizedBox(width: 12),
                
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _discountPercentage >= 0 && _discountPercentage <= 100
                        ? () {
                            widget.onApplyDiscount(_discountPercentage);
                            Navigator.of(context).pop();
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Apply',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discountController.dispose();
    super.dispose();
  }
}