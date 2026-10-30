import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/env_config.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

/// Manager for opening and controlling the live maintenance popup across the app.
class MaintenanceNotificationManager {
  static bool _isPopupOpen = false;
  static bool get isPopupOpen => _isPopupOpen;

  static _MaintenancePopupDialogState? _activeDialogState;
  static int _presentationToken = 0;

  /// Opens the maintenance popup/screen immediately.
  /// Prevents duplicate popups if one is already open.
  static void show({
    required String title,
    required String description,
  }) {
    final cleanTitle = title.trim();
    final cleanDesc = description.trim();
    if (cleanTitle.isEmpty || cleanDesc.isEmpty) return;

    debugPrint('🔔 [MaintenanceNotificationManager] show requested: "$cleanTitle"');

    // 1. If dialog is already active and mounted on screen, update content without duplicate
    if (_activeDialogState != null && _activeDialogState!.mounted) {
      debugPrint(
        'Maintenance popup dialog is already active. Updating content without opening duplicate.',
      );
      _activeDialogState!.updateContent(cleanTitle, cleanDesc);
      if (MaintenanceGate.isMaintenanceActive) {
        MaintenanceGate.update(title: cleanTitle, description: cleanDesc);
      }
      return;
    }

    // 2. If MaintenanceGate is already displaying full-screen maintenance view (e.g. startup):
    if (MaintenanceGate.isMaintenanceActive) {
      debugPrint(
        'MaintenanceGate is already displaying maintenance view. Updating content.',
      );
      MaintenanceGate.update(title: cleanTitle, description: cleanDesc);
      return;
    }

    // Reset stale flag if no dialog is actually mounted
    _isPopupOpen = false;
    _activeDialogState = null;
    final token = ++_presentationToken;

    void present() {
      if (token != _presentationToken) return;

      final navState = NotificationService.navigatorKey.currentState;
      final context = navState?.overlay?.context ??
          NotificationService.navigatorKey.currentContext;

      if (context == null || !context.mounted) {
        debugPrint(
          'Navigator context not ready yet. Scheduling maintenance popup presentation...',
        );
        WidgetsBinding.instance.addPostFrameCallback((_) => present());
        WidgetsBinding.instance.ensureVisualUpdate();
        return;
      }

      // If in the meantime another dialog opened, update it
      if (_activeDialogState != null && _activeDialogState!.mounted) {
        _activeDialogState!.updateContent(cleanTitle, cleanDesc);
        return;
      }

      _isPopupOpen = true;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(140),
        useRootNavigator: true,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: MaintenancePopupDialog(
              initialTitle: cleanTitle,
              initialDescription: cleanDesc,
              onDismissed: () {
                _isPopupOpen = false;
                _activeDialogState = null;
              },
            ),
          );
        },
      ).then((_) {
        _isPopupOpen = false;
        _activeDialogState = null;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => present());
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Closes the active live maintenance popup if open.
  static void close() {
    _presentationToken++;
    if (_activeDialogState != null && _activeDialogState!.mounted) {
      try {
        final nav = Navigator.of(_activeDialogState!.context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
        }
      } catch (e) {
        debugPrint('Error closing maintenance dialog: $e');
      }
    } else if (_isPopupOpen) {
      try {
        final navState = NotificationService.navigatorKey.currentState;
        if (navState != null && navState.canPop()) {
          navState.pop();
        }
      } catch (e) {
        debugPrint('Error closing maintenance dialog via navigatorKey: $e');
      }
    }
    _isPopupOpen = false;
    _activeDialogState = null;
    MaintenanceGate.clear();
  }

  /// Immediately hides or closes the active live maintenance popup if open.
  static void hide() => close();
}

/// Dialog wrapper for the maintenance popup when triggered during live app usage.
class MaintenancePopupDialog extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  final VoidCallback? onDismissed;

  const MaintenancePopupDialog({
    super.key,
    required this.initialTitle,
    required this.initialDescription,
    this.onDismissed,
  });

  @override
  State<MaintenancePopupDialog> createState() => _MaintenancePopupDialogState();
}

class _MaintenancePopupDialogState extends State<MaintenancePopupDialog> {
  final ApiService _apiService = ApiService();

  late String _title;
  late String _description;
  bool _isRetrying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _title = widget.initialTitle;
    _description = widget.initialDescription;
    MaintenanceNotificationManager._activeDialogState = this;
  }

  @override
  void dispose() {
    if (MaintenanceNotificationManager._activeDialogState == this) {
      MaintenanceNotificationManager._activeDialogState = null;
    }
    widget.onDismissed?.call();
    super.dispose();
  }

  void updateContent(String newTitle, String newDescription) {
    if (!mounted) return;
    setState(() {
      _title = newTitle;
      _description = newDescription;
    });
  }

  Future<void> _handleTryAgain() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _errorMessage = null;
    });

    try {
      final info = await _apiService.checkMaintenanceNotification(
        rethrowOnError: true,
      );

      if (mounted) {
        if (info.isUnderMaintenance) {
          // Still under maintenance: update latest dynamic title and description, keep popup
          setState(() {
            _title = info.title;
            _description = info.description;
            _isRetrying = false;
          });
          MaintenanceGate.update(title: info.title, description: info.description);
        } else {
          // Maintenance cleared! Close popup and return to app
          _isRetrying = false;
          MaintenanceNotificationManager.close();
        }
      }
    } catch (e) {
      debugPrint('Live Try Again maintenance check error: $e');
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _errorMessage = 'Unable to verify server status. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: MaintenancePopupCard(
          title: _title,
          description: _description,
          isRetrying: _isRetrying,
          errorMessage: _errorMessage,
          onTryAgain: _handleTryAgain,
        ),
      ),
    );
  }
}

/// Reusable maintenance popup card widget.
class MaintenancePopupCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isRetrying;
  final String? errorMessage;
  final VoidCallback onTryAgain;

  const MaintenancePopupCard({
    super.key,
    required this.title,
    required this.description,
    required this.isRetrying,
    this.errorMessage,
    required this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Highlighted Maintenance Icon Badge
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFEF3C7), // Warm amber tint
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Center(
              child: Icon(
                Icons.construction_rounded,
                size: 34,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Popup Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF111827),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Popup Description
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),

          // Error Message if Recheck Failed
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // "Try Again" Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isRetrying ? null : onTryAgain,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.darkGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.darkGreen.withAlpha(180),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isRetrying
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Checking...',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Try Again',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gatekeeper on app startup that checks `GET /api/shop/app-setting`.
///
/// If `maintenanceNotificationTitle` and `maintenanceNotificationDescription`
/// are both non-empty, displays a blocking maintenance popup.
/// When the user taps "Try Again", it re-checks the endpoint.
/// If maintenance is cleared or empty, allows normal access to [MainNavigationScreen].
class MaintenanceGate extends StatefulWidget {
  const MaintenanceGate({super.key});

  static _MaintenanceGateState? _activeGateState;

  static void activate({required String title, required String description}) {
    _activeGateState?.activateMaintenance(title, description);
  }

  static void update({required String title, required String description}) {
    _activeGateState?.updateContent(title, description);
  }

  static void clear() {
    _activeGateState?.clearMaintenance();
  }

  static bool get isMaintenanceActive =>
      _activeGateState != null &&
      _activeGateState!.mounted &&
      _activeGateState!._isMaintenanceActive;

  @override
  State<MaintenanceGate> createState() => _MaintenanceGateState();
}

class _MaintenanceGateState extends State<MaintenanceGate> {
  final ApiService _apiService = ApiService();

  bool _isChecking = true;
  bool _isMaintenanceActive = false;
  bool get isMaintenanceActive => _isMaintenanceActive;
  String _maintenanceTitle = '';
  String _maintenanceDescription = '';

  bool _isRetrying = false;
  String? _retryErrorMessage;

  @override
  void initState() {
    super.initState();
    MaintenanceGate._activeGateState = this;
    _performInitialCheck();
  }

  @override
  void dispose() {
    if (MaintenanceGate._activeGateState == this) {
      MaintenanceGate._activeGateState = null;
    }
    super.dispose();
  }

  void activateMaintenance(String title, String description) {
    if (!mounted) return;
    setState(() {
      _maintenanceTitle = title;
      _maintenanceDescription = description;
      _isMaintenanceActive = true;
      _isChecking = false;
    });
  }

  void updateContent(String title, String description) {
    if (!mounted) return;
    setState(() {
      _maintenanceTitle = title;
      _maintenanceDescription = description;
    });
  }

  void clearMaintenance() {
    if (!mounted) return;
    setState(() {
      _isMaintenanceActive = false;
      _isChecking = false;
    });
  }

  Future<void> _performInitialCheck() async {
    try {
      final info = await _apiService.checkMaintenanceNotification(
        rethrowOnError: false,
      );
      if (mounted) {
        if (info.isUnderMaintenance) {
          setState(() {
            _maintenanceTitle = info.title;
            _maintenanceDescription = info.description;
            _isMaintenanceActive = true;
            _isChecking = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Startup maintenance check error: $e');
    }

    if (mounted) {
      setState(() {
        _isMaintenanceActive = false;
        _isChecking = false;
      });
    }
  }

  Future<void> _handleTryAgain() async {
    if (_isRetrying) return;

    setState(() {
      _isRetrying = true;
      _retryErrorMessage = null;
    });

    try {
      final info = await _apiService.checkMaintenanceNotification(
        rethrowOnError: true,
      );

      if (mounted) {
        if (info.isUnderMaintenance) {
          // Still under maintenance: update latest dynamic title and description, keep popup
          setState(() {
            _maintenanceTitle = info.title;
            _maintenanceDescription = info.description;
            _isMaintenanceActive = true;
            _isRetrying = false;
          });
        } else {
          // Maintenance cleared! Close popup and enter main screen
          setState(() {
            _isMaintenanceActive = false;
            _isRetrying = false;
          });
          MaintenanceNotificationManager.close();
        }
      }
    } catch (e) {
      debugPrint('Try Again maintenance check error: $e');
      if (mounted) {
        setState(() {
          _isRetrying = false;
          _retryErrorMessage =
              'Unable to verify server status. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return _buildSplashView();
    }

    if (_isMaintenanceActive) {
      return _buildMaintenanceView();
    }

    return const MainNavigationScreen();
  }

  Widget _buildSplashView() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/icon/app_icon.png',
                width: 76,
                height: 76,
                errorBuilder:
                    (context, error, stackTrace) => const Icon(
                      Icons.shopping_bag_rounded,
                      size: 64,
                      color: AppTheme.darkGreen,
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              EnvConfig.appName,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkGreen,
              ),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.darkGreen),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceView() {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: PopScope(
        canPop: false,
        child: Stack(
          children: [
            // Underneath backdrop view
            _buildSplashView(),

            // Modal Dim Barrier
            Container(color: Colors.black.withAlpha(140)),

            // Centered Modal Popup Card
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 32.0,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: MaintenancePopupCard(
                    title: _maintenanceTitle,
                    description: _maintenanceDescription,
                    isRetrying: _isRetrying,
                    errorMessage: _retryErrorMessage,
                    onTryAgain: _handleTryAgain,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
