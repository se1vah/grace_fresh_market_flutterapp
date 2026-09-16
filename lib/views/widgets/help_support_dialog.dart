// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Reusable Help & Support Modal Popup Dialog
class HelpSupportDialog extends StatelessWidget {
  const HelpSupportDialog({super.key});

  /// Helper static method to open the Help & Support popup dialog cleanly
  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const HelpSupportDialog();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxModalHeight = screenSize.height * 0.85;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenSize.width < 600 ? screenSize.width * 0.92 : 600,
          constraints: BoxConstraints(
            maxHeight: maxModalHeight,
            minHeight: 300,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF9FAF8),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGreenBadge,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.help_outline,
                        color: AppTheme.darkGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Help & Support',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.black87),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.lightGreenBadge.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.accentGreen.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to Grace Fresh Market Help & Support.',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'We are here to help you with your orders, delivery, products, and other questions related to the Grace Fresh Market app.',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: AppTheme.textDark,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Section Title
                      Text(
                        'How Can We Help You?',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // FAQs 1 to 9
                      _buildFaqItem(
                        number: '1',
                        question: 'How do I place an order?',
                        answerParagraphs: [
                          'Open the Grace Fresh Market app and browse the available vegetables and fruits.',
                          'Select the products and quantities you need, add them to your cart, check your order details, provide your delivery address, and place your order.',
                          'Currently, all orders are available with Cash on Delivery (COD).',
                        ],
                      ),
                      _buildFaqItem(
                        number: '2',
                        question: 'Where does Grace Fresh Market deliver?',
                        answerParagraphs: [
                          'Grace Fresh Market currently provides delivery only within the Thangachimadam area.',
                          'Orders outside the Thangachimadam service area cannot currently be delivered.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '3',
                        question: 'How do I pay for my order?',
                        answerParagraphs: [
                          'We currently accept Cash on Delivery (COD).',
                          'Please keep the required amount ready when your order is delivered.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '4',
                        question: 'Can I cancel my order?',
                        answerParagraphs: [
                          'Order cancellation is currently not available.',
                          'Please carefully check your products, quantities, delivery address, and order details before placing your order.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '5',
                        question: 'I received a wrong or damaged product. What should I do?',
                        answerParagraphs: [
                          'If you receive a wrong, damaged, or significantly unsuitable product, please contact us as soon as possible after delivery.',
                          'Please provide your order details and explain the issue clearly. If applicable, you may also provide photographs of the product to help us review the issue.',
                          'Our team will review your complaint and provide an appropriate resolution where applicable.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '6',
                        question: 'My order has not been delivered. What should I do?',
                        answerParagraphs: [
                          'If your order has not arrived within the expected delivery time, please contact our support team using the phone number or email address below.',
                          'Please keep your order details available so that we can assist you quickly.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '7',
                        question: 'Can I change my delivery address after placing an order?',
                        answerParagraphs: [
                          'Please contact our support team as soon as possible if you need to report an issue with your delivery address.',
                          'Changes may not always be possible after an order has been placed or prepared for delivery.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '8',
                        question: 'A product I want is not available. What can I do?',
                        answerParagraphs: [
                          'Product availability may change depending on stock.',
                          'If a product is unavailable, you can check the app again later or contact our support team for assistance.',
                        ],
                      ),
                      _buildFaqItem(
                        number: '9',
                        question: 'I am having a problem with the app. What should I do?',
                        answerParagraphs: [
                          'If you experience technical problems such as the app not opening, products not loading, or difficulty placing an order, please try closing and reopening the app and checking your internet connection.',
                          'If the problem continues, contact our support team.',
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Contact Us Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8F4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2EFE2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.headset_mic,
                                  color: AppTheme.darkGreen,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Contact Us',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'For any questions, complaints, order-related issues, or technical support, please contact us:',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: AppTheme.textDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'Grace Fresh Market',
                              style: GoogleFonts.outfit(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _buildContactRow(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: '8015413414',
                            ),
                            const SizedBox(height: 8),
                            _buildContactRow(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: 'gracefreshmarket@gmail.com',
                            ),
                            const SizedBox(height: 8),
                            _buildContactRow(
                              icon: Icons.location_on_outlined,
                              label: 'Service Area',
                              value: 'Thangachimadam Area Only',
                            ),
                            const SizedBox(height: 14),
                            Text(
                              'We will do our best to assist you and provide a convenient shopping experience.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Before Contacting Support Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.checklist_rtl,
                                  color: AppTheme.darkGreen,
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Before Contacting Support',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.darkGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'To help us resolve your issue quickly, please keep the following information ready when applicable:',
                              style: GoogleFonts.outfit(
                                fontSize: 13.5,
                                color: AppTheme.textDark,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildChecklistItem('Your name'),
                            _buildChecklistItem('Registered mobile number'),
                            _buildChecklistItem('Order details or order number'),
                            _buildChecklistItem('Delivery address'),
                            _buildChecklistItem('Description of the issue'),
                            _buildChecklistItem(
                              'Photos of the product, if the issue concerns a damaged or incorrect product',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({
    required String number,
    required String question,
    required List<String> answerParagraphs,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$number. ',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                Expanded(
                  child: Text(
                    question,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...answerParagraphs.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Text(
                  p,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                    height: 1.45,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppTheme.darkGreen,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2.0, right: 8.0),
            child: Icon(
              Icons.check_circle_outline,
              size: 16,
              color: AppTheme.primaryGreen,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: AppTheme.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
