import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/address_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';
import '../widgets/grace_app_bar.dart';
import '../widgets/grace_bottom_nav_bar.dart';
import '../widgets/grace_drawer.dart';

class DeliveryAddressScreen extends StatefulWidget {
  const DeliveryAddressScreen({super.key});

  @override
  State<DeliveryAddressScreen> createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<AddressModel> _addresses = [];
  dynamic _settingDefaultAddressId;
  dynamic _deletingAddressId;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _apiService.getUserAddresses();
      setState(() {
        _addresses = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSetDefaultAddress(dynamic addressId) async {
    if (_settingDefaultAddressId != null || _deletingAddressId != null) return;

    setState(() {
      _settingDefaultAddressId = addressId;
    });

    try {
      await _apiService.setDefaultAddress(addressId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Default address updated successfully!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppTheme.darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _fetchAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppTheme.deleteRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _settingDefaultAddressId = null;
        });
      }
    }
  }

  Future<void> _handleDeleteAddress(AddressModel address) async {
    if (_deletingAddressId != null || _settingDefaultAddressId != null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete Address',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this address? This action cannot be undone.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          actionsPadding:
              const EdgeInsets.only(left: 16, right: 16, bottom: 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF6B7280)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC02626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Delete',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _deletingAddressId = address.id;
    });

    try {
      await _apiService.deleteAddress(address.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Address deleted successfully!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppTheme.darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _fetchAddresses();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppTheme.deleteRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deletingAddressId = null;
        });
      }
    }
  }

  void _openAddressFormBottomSheet([AddressModel? addressToEdit]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddressFormBottomSheet(
        addressToEdit: addressToEdit,
        onAddressSaved: _fetchAddresses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: const GraceAppBar(),
      drawer: const GraceDrawer(currentRoute: 'addresses'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Titles with Back Button
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AppTheme.darkGreen,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Addresses',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.darkGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Where should we deliver your fresh produce?',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Content according to state
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.darkGreen,
                      ),
                    ),
                  )
                else if (_errorMessage != null)
                  _buildErrorView()
                else if (_addresses.isEmpty)
                  _buildEmptyView()
                else
                  ..._addresses.map((addr) => _buildAddressCard(addr)),

                const SizedBox(height: 16),

                // Add New Address Button
                if (!_isLoading && _errorMessage == null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openAddressFormBottomSheet(),
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 22,
                      ),
                      label: Text(
                        'Add New Address',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.darkGreen,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: GraceBottomNavBar(
        currentIndex: 3,
        onTap: (index) {
          if (MainNavigationScreen.isInsideMainNavigation(context)) {
            Navigator.of(context).pop();
            MainNavigationScreen.navigateToTab(context, index);
          } else {
            MainNavigationScreen.navigateToTab(context, index);
          }
        },
      ),
    );
  }

  Widget _buildAddressCard(AddressModel address) {
    IconData typeIcon;
    final typeLower = address.addressType.toLowerCase();
    if (typeLower == 'home') {
      typeIcon = Icons.home;
    } else if (typeLower == 'office' || typeLower == 'work') {
      typeIcon = Icons.work;
    } else {
      typeIcon = Icons.location_on;
    }

    final cityStatePin = [
      if (address.city.isNotEmpty) address.city,
      if (address.state.isNotEmpty) address.state,
      if (address.pincode.isNotEmpty) address.pincode,
    ].join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row inside Card: Type Icon + Type Name & Default Badge/Set Default
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(typeIcon, color: AppTheme.darkGreen, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    address.addressType.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB5ED66),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    'Default',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                )
              else if (_settingDefaultAddressId?.toString() ==
                  address.id.toString())
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                )
              else
                InkWell(
                  onTap: (_settingDefaultAddressId != null ||
                          _deletingAddressId != null)
                      ? null
                      : () => _handleSetDefaultAddress(address.id),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      'Set as Default',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: (_settingDefaultAddressId != null ||
                                _deletingAddressId != null)
                            ? AppTheme.textSecondary
                            : AppTheme.darkGreen,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // Address Details Lines
          if (address.buildingName.isNotEmpty)
            Text(
              address.buildingName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
          if (address.streetName.isNotEmpty)
            Text(
              address.streetName,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),
          if (cityStatePin.isNotEmpty)
            Text(
              cityStatePin,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.textDark,
                height: 1.3,
              ),
            ),

          const SizedBox(height: 18),

          // Action Buttons: Edit & Delete
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: (_settingDefaultAddressId != null ||
                            _deletingAddressId != null)
                        ? null
                        : () => _openAddressFormBottomSheet(address),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.darkGreen,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      'Edit',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: (_deletingAddressId != null ||
                            _settingDefaultAddressId != null)
                        ? null
                        : () => _handleDeleteAddress(address),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFFC02626),
                        width: 1.5,
                      ),
                      backgroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _deletingAddressId?.toString() ==
                            address.id.toString()
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFC02626),
                            ),
                          )
                        : Text(
                            'Delete',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC02626),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.location_off_outlined,
            size: 64,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No Saved Addresses',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have not added any delivery addresses yet.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 56, color: AppTheme.deleteRed),
          const SizedBox(height: 12),
          Text(
            'Failed to Load Addresses',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _fetchAddresses,
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: Text(
              'Retry',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.darkGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressFormBottomSheet extends StatefulWidget {
  final AddressModel? addressToEdit;
  final VoidCallback onAddressSaved;

  const _AddressFormBottomSheet({
    this.addressToEdit,
    required this.onAddressSaved,
  });

  @override
  State<_AddressFormBottomSheet> createState() =>
      _AddressFormBottomSheetState();
}

class _AddressFormBottomSheetState extends State<_AddressFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  late final TextEditingController _buildingNameController;
  late final TextEditingController _streetNameController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;

  late String _selectedAddressType;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.addressToEdit != null;

  @override
  void initState() {
    super.initState();
    final addr = widget.addressToEdit;

    _buildingNameController =
        TextEditingController(text: addr?.buildingName ?? '');
    _streetNameController =
        TextEditingController(text: addr?.streetName ?? '');
    _cityController = TextEditingController(
      text: addr != null && addr.city.isNotEmpty
          ? addr.city
          : 'Thangachimadam',
    );
    _stateController = TextEditingController(
      text: addr != null && addr.state.isNotEmpty
          ? addr.state
          : 'Tamilnadu',
    );
    _pincodeController = TextEditingController(
      text: addr != null && addr.pincode.isNotEmpty
          ? addr.pincode
          : '623529',
    );

    if (addr != null && addr.addressType.isNotEmpty) {
      final typeLower = addr.addressType.trim().toLowerCase();
      if (typeLower == 'home') {
        _selectedAddressType = 'Home';
      } else if (typeLower == 'work' || typeLower == 'office') {
        _selectedAddressType = 'Work';
      } else {
        _selectedAddressType = 'Other';
      }
    } else {
      _selectedAddressType = 'Home';
    }
  }

  @override
  void dispose() {
    _buildingNameController.dispose();
    _streetNameController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isEditMode) {
        await _apiService.updateAddress(
          id: widget.addressToEdit!.id,
          buildingName: _buildingNameController.text.trim(),
          streetName: _streetNameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          addressType: _selectedAddressType,
        );
      } else {
        await _apiService.createAddress(
          buildingName: _buildingNameController.text.trim(),
          streetName: _streetNameController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          pincode: _pincodeController.text.trim(),
          addressType: _selectedAddressType,
          isDefault: true,
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop();
      widget.onAddressSaved();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Address updated successfully!'
                : 'Address added successfully!',
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppTheme.darkGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll('Exception: ', ''),
            style: GoogleFonts.outfit(color: Colors.white),
          ),
          backgroundColor: AppTheme.deleteRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0, left: 2.0),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF5F6F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.darkGreen, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.deleteRed, width: 1.0),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.deleteRed, width: 1.5),
      ),
      errorStyle: GoogleFonts.outfit(color: AppTheme.deleteRed, fontSize: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: Title & Close Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isEditMode ? 'Edit Address' : 'Add New Address',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        IconButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.of(context).pop(),
                          icon: const Icon(
                            Icons.close,
                            color: AppTheme.textDark,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ADDRESS Type Dropdown
                    _buildFieldLabel('ADDRESS Type'),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAddressType,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppTheme.textSecondary,
                      ),
                      decoration: _buildInputDecoration(),
                      dropdownColor: Colors.white,
                      items: ['Home', 'Work', 'Other'].map((type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(
                            type,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textDark,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedAddressType = val;
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Building Name
                    _buildFieldLabel('Building Name'),
                    TextFormField(
                      controller: _buildingNameController,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.next,
                      decoration: _buildInputDecoration(),
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Building Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Row: STREET ADDRESS & CITY
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('STREET ADDRESS'),
                              TextFormField(
                                controller: _streetNameController,
                                enabled: !_isSubmitting,
                                textInputAction: TextInputAction.next,
                                decoration: _buildInputDecoration(),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Street Name is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('CITY'),
                              TextFormField(
                                controller: _cityController,
                                enabled: !_isSubmitting,
                                textInputAction: TextInputAction.next,
                                decoration: _buildInputDecoration(),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'City is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Row: STATE & Pincode
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('STATE'),
                              TextFormField(
                                controller: _stateController,
                                enabled: !_isSubmitting,
                                textInputAction: TextInputAction.next,
                                decoration: _buildInputDecoration(),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'State is required';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFieldLabel('Pincode'),
                              TextFormField(
                                controller: _pincodeController,
                                enabled: !_isSubmitting,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.done,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: _buildInputDecoration(),
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Pincode is required';
                                  }
                                  if (!RegExp(r'^\d+$').hasMatch(val.trim())) {
                                    return 'Enter valid numeric pincode';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Bottom Buttons: Save Changes & Cancel
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.darkGreen,
                                disabledBackgroundColor: AppTheme.darkGreen
                                    .withAlpha(128),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      'Save Changes',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                  color: Color(0xFF4B5563),
                                  width: 1.5,
                                ),
                                backgroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
