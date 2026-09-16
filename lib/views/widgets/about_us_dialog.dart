// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_theme.dart';

/// Reusable About Us, About App, Terms & Conditions & Privacy Policy Modal Popup Dialog
class AboutUsDialog extends StatefulWidget {
  final int initialIndex;

  const AboutUsDialog({super.key, this.initialIndex = 0});

  /// Helper static method to open the About Us popup dialog cleanly
  static Future<void> show(
    BuildContext context, {
    int initialIndex = 0,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.6),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AboutUsDialog(initialIndex: initialIndex);
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
  State<AboutUsDialog> createState() => _AboutUsDialogState();
}

class _AboutUsDialogState extends State<AboutUsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final maxModalHeight = screenSize.height * 0.88;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenSize.width < 640 ? screenSize.width * 0.92 : 620,
          constraints: BoxConstraints(
            maxHeight: maxModalHeight,
            minHeight: 320,
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
              // Modal Header with Icon, Title & Close Button
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
                        Icons.info_outline,
                        color: AppTheme.darkGreen,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About Us',
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          Text(
                            'Grace Fresh Market',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
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

              // Navigation Tab Bar
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1.0),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: AppTheme.darkGreen,
                  unselectedLabelColor: AppTheme.textSecondary,
                  indicatorColor: AppTheme.darkGreen,
                  indicatorWeight: 3,
                  labelStyle: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  tabs: const [
                    Tab(text: 'About Us'),
                    Tab(text: 'About App'),
                    Tab(text: 'Terms'),
                    Tab(text: 'Privacy Policy'),
                  ],
                ),
              ),

              // Scrollable Tab View Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAboutUsTab(),
                    _buildAboutAppTab(),
                    _buildTermsTab(),
                    _buildPrivacyTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 1. About Us Tab
  Widget _buildAboutUsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitle('Grace Fresh Market — About Us'),
          const SizedBox(height: 12),
          _buildParagraph(
            'Welcome to Grace Fresh Market, your local online destination for fresh vegetables and fruits in Thangachimadam.',
          ),
          _buildParagraph(
            'Grace Fresh Market is a locally focused vegetable and fruit delivery service created to make everyday shopping easier and more convenient for the people of Thangachimadam.',
          ),
          _buildParagraph(
            'Through our app, customers can browse available vegetables and fruits, select the products they need, place an order, and receive their order conveniently at their doorstep.',
          ),
          _buildParagraph(
            'Our mission is to provide fresh products, a simple ordering experience, and reliable local delivery to the people of Thangachimadam.',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Our Commitment'),
          const SizedBox(height: 10),
          _buildChecklistItem(
            'Providing fresh and quality vegetables and fruits.',
          ),
          _buildChecklistItem(
            'Making daily grocery shopping simple and convenient.',
          ),
          _buildChecklistItem(
            'Providing doorstep delivery within Thangachimadam.',
          ),
          _buildChecklistItem('Offering a user-friendly ordering experience.'),
          _buildChecklistItem(
            'Continuously improving our service based on customer feedback.',
          ),
          const SizedBox(height: 16),
          _buildParagraph(
            'Thank you for choosing Grace Fresh Market and supporting our local service.',
          ),
          const SizedBox(height: 20),
          _buildContactCard(),
        ],
      ),
    );
  }

  // 2. About the App Tab
  Widget _buildAboutAppTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitle('Grace Fresh Market — About the App'),
          const SizedBox(height: 12),
          _buildParagraph(
            'Grace Fresh Market is a local vegetables and fruits ordering and delivery app designed exclusively for customers in the Thangachimadam area.',
          ),
          _buildParagraph(
            'With Grace Fresh Market, you can conveniently order the vegetables and fruits you need from your mobile phone and have them delivered to your doorstep.',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('What You Can Do With Our App'),
          const SizedBox(height: 10),
          _buildChecklistItem('Browse available vegetables and fruits.'),
          _buildChecklistItem(
            'View product names, prices, and available quantities.',
          ),
          _buildChecklistItem('Select the products you need.'),
          _buildChecklistItem('Add products to your shopping cart.'),
          _buildChecklistItem('Review your order before placing it.'),
          _buildChecklistItem(
            'Provide your delivery address and contact details.',
          ),
          _buildChecklistItem('Place your order easily through the app.'),
          _buildChecklistItem(
            'Pay conveniently through Cash on Delivery (COD).',
          ),
          _buildChecklistItem(
            'Receive your order at your doorstep within the service area.',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('How It Works'),
          const SizedBox(height: 12),
          _buildStepCard(
            stepNumber: '1',
            title: 'Download the App',
            description:
                'Download and install Grace Fresh Market from the Google Play Store.',
          ),
          _buildStepCard(
            stepNumber: '2',
            title: 'Browse Products',
            description:
                'Explore the vegetables and fruits currently available in the app.',
          ),
          _buildStepCard(
            stepNumber: '3',
            title: 'Add to Cart',
            description:
                'Select the products and quantities you need and add them to your cart.',
          ),
          _buildStepCard(
            stepNumber: '4',
            title: 'Place Your Order',
            description:
                'Review your selected products and delivery details, then place your order.',
          ),
          _buildStepCard(
            stepNumber: '5',
            title: 'Cash on Delivery',
            description:
                'Pay for your order in cash when your order is delivered.',
          ),
          _buildStepCard(
            stepNumber: '6',
            title: 'Get Your Delivery',
            description:
                'Our delivery team will deliver your order to the address you provided within the Thangachimadam service area.',
          ),
          const SizedBox(height: 20),
          _buildSectionHeader('Our Service Area'),
          const SizedBox(height: 10),
          _buildParagraph(
            'Grace Fresh Market currently provides delivery services only within the Thangachimadam area.',
          ),
          _buildParagraph(
            'Orders placed outside our service area cannot currently be accepted or delivered.',
          ),
        ],
      ),
    );
  }

  // 3. Terms and Conditions Tab
  Widget _buildTermsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitle('Grace Fresh Market — Terms and Conditions'),
          const SizedBox(height: 4),
          Text(
            'Last Updated: September 10, 2026',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildParagraph(
            'Welcome to Grace Fresh Market. By downloading, installing, accessing, or using the Grace Fresh Market application, you agree to comply with and be bound by these Terms and Conditions.',
          ),
          _buildParagraph(
            'Please read these terms carefully before using our application.',
          ),
          const SizedBox(height: 16),
          _buildNumberedSection(
            number: '1',
            title: 'About Our Service',
            content:
                'Grace Fresh Market is a local online ordering and delivery service that allows customers to purchase vegetables and fruits through our mobile application.\n\nOur delivery service is currently available only within the Thangachimadam area.',
          ),
          _buildNumberedSection(
            number: '2',
            title: 'User Information',
            content:
                'To place an order, customers may be required to provide information such as their name, mobile number, delivery address, and other necessary details.\n\nCustomers are responsible for providing accurate and up-to-date information.',
          ),
          _buildNumberedSection(
            number: '3',
            title: 'Placing an Order',
            content:
                'Customers can browse available products, select quantities, add products to their cart, and place an order through the app.\n\nAn order is considered successfully placed once the order confirmation is displayed or communicated through the app.\n\nProduct availability may change from time to time. If a selected product is unavailable, Grace Fresh Market may contact the customer regarding the availability of the product or an appropriate alternative.',
          ),
          _buildNumberedSection(
            number: '4',
            title: 'Product Information',
            content:
                'We make reasonable efforts to provide accurate product names, prices, quantities, and images.\n\nVegetables and fruits are natural products, so their size, colour, appearance, weight, and other characteristics may naturally vary.',
          ),
          _buildNumberedSection(
            number: '5',
            title: 'Prices',
            content:
                'The prices displayed in the app may change from time to time.\n\nThe applicable product price at the time the order is placed will generally apply to that order, subject to any technical errors or clearly communicated changes.',
          ),
          _buildNumberedSection(
            number: '6',
            title: 'Payment',
            content:
                'Grace Fresh Market currently accepts Cash on Delivery (COD).\n\nCustomers are required to make the applicable payment in cash when the order is delivered.',
          ),
          _buildNumberedSection(
            number: '7',
            title: 'Delivery',
            content:
                'Grace Fresh Market provides delivery only within the Thangachimadam area.\n\nDelivery time may vary depending on order volume, product availability, weather, traffic, operational conditions, and other circumstances.\n\nCustomers are responsible for providing a correct and complete delivery address and being available to receive the order.',
          ),
          _buildNumberedSection(
            number: '8',
            title: 'Order Cancellation',
            content:
                'Order cancellation is currently not available through the Grace Fresh Market app.\n\nOnce an order has been successfully placed, customers cannot cancel the order through the app.\n\nPlease review your selected products, quantities, delivery address, and order details carefully before placing an order.',
          ),
          _buildNumberedSection(
            number: '9',
            title: 'Refunds and Returns',
            content:
                'Since vegetables and fruits are perishable products, refunds and returns are subject to the circumstances of each order.\n\nIf you receive a wrong, damaged, or significantly unsuitable product, please contact Grace Fresh Market as soon as possible after delivery with your order details.\n\nWe will review the issue and, where appropriate, provide a suitable resolution.',
          ),
          _buildNumberedSection(
            number: '10',
            title: 'User Responsibilities',
            content: 'Users agree not to:',
            bullets: [
              'Use the app for unlawful purposes.',
              'Provide false or misleading information.',
              'Place fraudulent or intentionally misleading orders.',
              'Misuse the ordering or delivery service.',
              'Attempt to interfere with the operation or security of the application.',
              'Attempt to gain unauthorized access to the application or its systems.',
            ],
          ),
          _buildNumberedSection(
            number: '11',
            title: 'Service Availability',
            content:
                'Grace Fresh Market may temporarily suspend or modify the application or delivery service due to maintenance, technical issues, product availability, weather conditions, operational issues, or circumstances beyond our reasonable control.',
          ),
          _buildNumberedSection(
            number: '12',
            title: 'Intellectual Property',
            content:
                'The Grace Fresh Market name, logo, application design, text, graphics, images, and other content associated with the application are owned by Grace Fresh Market or their respective owners.\n\nThey may not be copied, reproduced, modified, or distributed without appropriate permission.',
          ),
          _buildNumberedSection(
            number: '13',
            title: 'Changes to These Terms',
            content:
                'Grace Fresh Market may update these Terms and Conditions from time to time.\n\nAny updated terms may be made available through the application.',
          ),
          _buildNumberedSection(
            number: '14',
            title: 'Contact Us',
            content:
                'For questions, complaints, or concerns regarding these Terms and Conditions, please contact us:\n\nGrace Fresh Market\nPhone: 8015413414\nEmail: gracefreshmarket@gmail.com\nService Area: Thangachimadam Area Only',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightGreenBadge.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'By using the Grace Fresh Market application, you acknowledge that you have read, understood, and agreed to these Terms and Conditions.',
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkGreen,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. Privacy Policy Tab
  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSubtitle('Grace Fresh Market — Privacy Policy'),
          const SizedBox(height: 4),
          Text(
            'Last Updated: September 10, 2026',
            style: GoogleFonts.outfit(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          _buildParagraph(
            'At Grace Fresh Market, we respect your privacy and are committed to protecting the personal information you provide while using our application.',
          ),
          _buildParagraph(
            'This Privacy Policy explains what information we may collect, how we use it, and how we protect it when you use the Grace Fresh Market app.',
          ),
          const SizedBox(height: 16),
          _buildNumberedSection(
            number: '1',
            title: 'Information We May Collect',
            content:
                'Depending on how you use the application, we may collect information such as:',
            bullets: [
              'Name',
              'Mobile phone number',
              'Delivery address',
              'Order and purchase details',
              'Information provided when contacting customer support',
              'Device and application-related information where necessary for the operation and security of the app',
            ],
            footerText:
                'We collect information that is reasonably necessary to provide our services and process your orders.',
          ),
          _buildNumberedSection(
            number: '2',
            title: 'How We Use Your Information',
            content: 'We may use your information to:',
            bullets: [
              'Create and manage your account.',
              'Process and deliver your orders.',
              'Contact you regarding your order.',
              'Provide customer support.',
              'Confirm delivery details.',
              'Improve our application and services.',
              'Prevent fraud, misuse, and unauthorized activities.',
              'Comply with applicable legal requirements.',
            ],
          ),
          _buildNumberedSection(
            number: '3',
            title: 'Location Information',
            content:
                'Grace Fresh Market may use location-related information if it is necessary for delivery-related functionality or to help identify the delivery location.\n\nAny location permission requested by the app will be used only for purposes related to the functionality of the service.\n\nYou can manage location permissions through your device settings.',
          ),
          _buildNumberedSection(
            number: '4',
            title: 'Payment Information',
            content:
                'Grace Fresh Market currently provides Cash on Delivery (COD).\n\nWe do not collect or store your debit card, credit card, UPI, or online banking credentials because online payment is currently not available through the app.',
          ),
          _buildNumberedSection(
            number: '5',
            title: 'How We Share Your Information',
            content:
                'We may share necessary customer information only when required to provide our services, such as with delivery personnel for fulfilling your order.\n\nWe may also disclose information when required by applicable law, legal process, or government authorities.\n\nWe do not sell your personal information to third parties for their own unrelated purposes.',
          ),
          _buildNumberedSection(
            number: '6',
            title: 'Data Security',
            content:
                'We take reasonable measures to protect the personal information we handle from unauthorized access, misuse, loss, alteration, or disclosure.\n\nHowever, no internet-based application or electronic transmission can be guaranteed to be completely secure.',
          ),
          _buildNumberedSection(
            number: '7',
            title: 'Data Retention',
            content:
                'We may retain customer information for as long as reasonably necessary to provide our services, maintain order records, resolve customer issues, prevent fraud, and comply with applicable legal requirements.',
          ),
          _buildNumberedSection(
            number: '8',
            title: "Children's Privacy",
            content:
                'Grace Fresh Market is not specifically intended for children.\n\nWe do not knowingly collect personal information from children in violation of applicable laws.',
          ),
          _buildNumberedSection(
            number: '9',
            title: 'Third-Party Services',
            content:
                'The application may use third-party technology or service providers where necessary for hosting, application functionality, notifications, analytics, security, or other operational purposes.\n\nSuch third-party providers may process information according to their own applicable terms and privacy policies.',
          ),
          _buildNumberedSection(
            number: '10',
            title: 'Your Choices',
            content:
                'You may manage certain app permissions, such as location and notifications, through your device settings.\n\nIf you have questions about the personal information associated with your account or wish to raise a privacy-related concern, you can contact us using the details below.',
          ),
          _buildNumberedSection(
            number: '11',
            title: 'Changes to This Privacy Policy',
            content:
                'We may update this Privacy Policy from time to time.\n\nAny changes will be made available through the application or other appropriate channels.',
          ),
          _buildNumberedSection(
            number: '12',
            title: 'Contact Us',
            content:
                'If you have any questions or concerns regarding this Privacy Policy or our handling of your information, please contact us:\n\nGrace Fresh Market\nPhone: 8015413414\nEmail: gracefreshmarket@gmail.com\nService Area: Thangachimadam Area Only',
          ),
        ],
      ),
    );
  }

  // Reusable Helper Widgets
  Widget _buildSubtitle(String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.lightGreenBadge.withOpacity(0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        subtitle,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppTheme.darkGreen,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkGreen,
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: AppTheme.textDark,
          height: 1.45,
        ),
      ),
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

  Widget _buildStepCard({
    required String stepNumber,
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppTheme.darkGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              stepNumber,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.outfit(
                    fontSize: 13.5,
                    color: AppTheme.textDark,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedSection({
    required String number,
    required String title,
    required String content,
    List<String>? bullets,
    String? footerText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFECECEC)),
      ),
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
                  title,
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
          Text(
            content,
            style: GoogleFonts.outfit(
              fontSize: 13.5,
              color: AppTheme.textDark,
              height: 1.45,
            ),
          ),
          if (bullets != null && bullets.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...bullets.map((b) => _buildChecklistItem(b)),
          ],
          if (footerText != null) ...[
            const SizedBox(height: 8),
            Text(
              footerText,
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                color: AppTheme.textDark,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EFE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Grace Fresh Market',
            style: GoogleFonts.outfit(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          _buildContactRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: '8015413414',
          ),
          const SizedBox(height: 6),
          _buildContactRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: 'gracefreshmarket@gmail.com',
          ),
          const SizedBox(height: 6),
          _buildContactRow(
            icon: Icons.location_on_outlined,
            label: 'Service Area',
            value: 'Thangachimadam Area Only',
          ),
        ],
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
        Icon(icon, size: 16, color: AppTheme.primaryGreen),
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
}
