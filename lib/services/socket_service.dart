import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../config/env_config.dart';
import '../views/maintenance_gate.dart';

class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  io.Socket? _socket;
  String? _currentUserId;
  Future<void> Function()? _onUserDeletedCallback;

  /// Initializes the global socket connection and registers app-level listeners
  /// such as `user-maintenance-notification`.
  void initialize() {
    _initSocket();
  }

  void _initSocket() {
    if (_socket != null && _socket!.connected) return;

    final serverUrl = EnvConfig.socketHost;

    try {
      if (_socket == null) {
        _socket = io.io(
          serverUrl,
          io.OptionBuilder()
              .setTransports(['websocket', 'polling'])
              .enableAutoConnect()
              .enableReconnection()
              .setReconnectionAttempts(999999)
              .setReconnectionDelay(1000)
              .build(),
        );

        _socket!.onConnect((_) {
          debugPrint('Socket connected to $serverUrl');
          _registerMaintenanceListener();
        });

        _socket!.on('reconnect', (_) {
          debugPrint('Socket reconnected to $serverUrl');
          _registerMaintenanceListener();
        });

        _socket!.onConnectError((err) {
          debugPrint('Socket connection error: $err');
        });

        _socket!.onError((err) {
          debugPrint('Socket error: $err');
        });

        _socket!.onDisconnect((_) {
          debugPrint('Socket disconnected from $serverUrl');
        });
      }

      // Always register the user-maintenance-notification listener
      _registerMaintenanceListener();

      if (!_socket!.connected) {
        _socket!.connect();
      }
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  /// Registers listener for `user-maintenance-notification` event.
  /// Removes any existing listener first to prevent duplicate event handling.
  void _registerMaintenanceListener() {
    if (_socket == null) return;

    // Clean up any previous listener to ensure single subscription
    _socket!.off('user-maintenance-notification');
    _socket!.off('maintenance-notification');

    _socket!.on('user-maintenance-notification', (data) {
      debugPrint(
        '🔔 [SocketService] Event received [user-maintenance-notification]: $data',
      );
      _handleMaintenanceNotification(data);
    });

    // Fallback listener in case backend emits without 'user-' prefix
    _socket!.on('maintenance-notification', (data) {
      debugPrint(
        '🔔 [SocketService] Fallback event received [maintenance-notification]: $data',
      );
      _handleMaintenanceNotification(data);
    });
  }

  /// Parses payload and validates maintenance status inside the socket event listener.
  /// If `maintenanceNotificationTitle` and `maintenanceNotificationDescription` values
  /// are null, empty, or contain only whitespace, immediately hides or closes the
  /// currently displayed maintenance notification popup.
  /// Otherwise, opens or updates the maintenance popup with the active content.
  void _handleMaintenanceNotification(dynamic data) {
    try {
      debugPrint(
        '🛠️ [SocketService] Processing maintenance notification payload: $data',
      );

      final payload = _extractMaintenancePayload(data);

      final bool isTitleBlank = _isNullOrEmptyOrWhitespace(payload.rawTitle);
      final bool isDescBlank = _isNullOrEmptyOrWhitespace(
        payload.rawDescription,
      );

      debugPrint(
        '🔍 [SocketService] Validating maintenance fields -> '
        'Title: "${payload.rawTitle}" (blank: $isTitleBlank), '
        'Description: "${payload.rawDescription}" (blank: $isDescBlank)',
      );

      // If maintenanceNotificationTitle and maintenanceNotificationDescription values
      // are null, empty, or contain only whitespace, immediately hide or close
      // the currently displayed maintenance notification popup.
      if (isTitleBlank || isDescBlank) {
        debugPrint(
          '🛑 [SocketService] Maintenance notification fields are null, empty, or whitespace. '
          'Immediately hiding/closing currently displayed maintenance popup.',
        );
        MaintenanceNotificationManager.close();
        return;
      }

      final title = payload.rawTitle.toString().trim();
      final desc = payload.rawDescription.toString().trim();

      debugPrint(
        '🛠️ [SocketService] Active maintenance detected. Opening/updating popup with '
        'title: "$title", desc: "$desc"',
      );

      MaintenanceNotificationManager.show(title: title, description: desc);
    } catch (e, stack) {
      debugPrint(
        '❌ [SocketService] Error handling user-maintenance-notification: $e\n$stack',
      );
    }
  }

  /// Visible for testing to verify maintenance validation on arbitrary event payloads.
  @visibleForTesting
  void handleMaintenanceNotificationForTesting(dynamic data) {
    _handleMaintenanceNotification(data);
  }

  /// Checks if a dynamic value is null, empty string, or contains only whitespace.
  bool _isNullOrEmptyOrWhitespace(dynamic value) {
    if (value == null) return true;
    final str = value.toString().trim();
    return str.isEmpty || str == 'null' || str == 'undefined';
  }

  /// Robustly extracts maintenance title and description from any data structure
  /// (Map, List of args, JSON string, or nested wrappers like 'data' / 'payload' / 'setting').
  _MaintenancePayload _extractMaintenancePayload(dynamic rawData) {
    if (rawData == null) {
      return const _MaintenancePayload(
        rawTitle: null,
        rawDescription: null,
        hasTitleKey: false,
        hasDescriptionKey: false,
      );
    }

    dynamic data = rawData;

    // Handle String (possibly JSON encoded or empty/whitespace string)
    if (data is String) {
      final trimmed = data.trim();
      if (trimmed.isEmpty || trimmed == 'null' || trimmed == 'undefined') {
        return const _MaintenancePayload(
          rawTitle: '',
          rawDescription: '',
          hasTitleKey: true,
          hasDescriptionKey: true,
        );
      }
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          data = jsonDecode(trimmed);
        } catch (_) {
          return const _MaintenancePayload(
            rawTitle: null,
            rawDescription: null,
          );
        }
      } else {
        return const _MaintenancePayload(rawTitle: null, rawDescription: null);
      }
    }

    // Handle List (e.g. Socket.io arguments list [ { ... } ])
    if (data is List) {
      if (data.isEmpty) {
        return const _MaintenancePayload(rawTitle: null, rawDescription: null);
      }
      for (final item in data) {
        final res = _extractMaintenancePayload(item);
        if (res.hasTitleKey || res.hasDescriptionKey) {
          return res;
        }
      }
      return const _MaintenancePayload(rawTitle: null, rawDescription: null);
    }

    if (data is Map) {
      dynamic foundTitle;
      bool hasTitle = false;
      dynamic foundDesc;
      bool hasDesc = false;

      // 1. Direct search with exact & normalized key: maintenanceNotificationTitle
      for (final entry in data.entries) {
        final normKey = entry.key.toString().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (normKey == 'maintenancenotificationtitle') {
          foundTitle = entry.value;
          hasTitle = true;
          break;
        }
      }

      // Direct search with exact & normalized key: maintenanceNotificationDescription
      for (final entry in data.entries) {
        final normKey = entry.key.toString().toLowerCase().replaceAll(
          RegExp(r'[^a-z0-9]'),
          '',
        );
        if (normKey == 'maintenancenotificationdescription') {
          foundDesc = entry.value;
          hasDesc = true;
          break;
        }
      }

      // 2. Fallback search for aliases if primary keys not found
      if (!hasTitle) {
        for (final entry in data.entries) {
          final normKey = entry.key.toString().toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          if (normKey == 'maintenancetitle' ||
              normKey == 'notificationtitle' ||
              normKey == 'title' ||
              normKey == 'heading') {
            foundTitle = entry.value;
            hasTitle = true;
            break;
          }
        }
      }

      if (!hasDesc) {
        for (final entry in data.entries) {
          final normKey = entry.key.toString().toLowerCase().replaceAll(
            RegExp(r'[^a-z0-9]'),
            '',
          );
          if (normKey == 'maintenancedescription' ||
              normKey == 'notificationdescription' ||
              normKey == 'description' ||
              normKey == 'message' ||
              normKey == 'msg' ||
              normKey == 'desc' ||
              normKey == 'content') {
            foundDesc = entry.value;
            hasDesc = true;
            break;
          }
        }
      }

      if (hasTitle || hasDesc) {
        return _MaintenancePayload(
          rawTitle: foundTitle,
          rawDescription: foundDesc,
          hasTitleKey: hasTitle,
          hasDescriptionKey: hasDesc,
        );
      }

      // 3. Search nested wrapper keys (e.g. data, payload, setting, notification)
      final candidateKeys = [
        'data',
        'payload',
        'setting',
        'notification',
        'body',
        'result',
        'item',
      ];
      for (final k in candidateKeys) {
        if (data.containsKey(k)) {
          final res = _extractMaintenancePayload(data[k]);
          if (res.hasTitleKey || res.hasDescriptionKey) {
            return res;
          }
        }
      }
    }

    return const _MaintenancePayload(
      rawTitle: null,
      rawDescription: null,
      hasTitleKey: false,
      hasDescriptionKey: false,
    );
  }

  /// Initializes socket connection and listens to `user-deleted-<USER_ID>` event.
  /// When a response is received on this socket, [onUserDeleted] is triggered.
  void initUserDeletedListener(
    String userId,
    Future<void> Function() onUserDeleted,
  ) {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) return;

    _onUserDeletedCallback = onUserDeleted;

    _initSocket();

    if (_currentUserId != null && _currentUserId != cleanUserId) {
      _socket?.off('user-deleted-$_currentUserId');
    }

    _currentUserId = cleanUserId;
    final eventName = 'user-deleted-$cleanUserId';

    // Remove any previous listener before registering to prevent duplicate handling
    _socket?.off(eventName);

    _socket?.on(eventName, (data) async {
      debugPrint('Socket response received on [$eventName]: $data');
      if (_onUserDeletedCallback != null) {
        await _onUserDeletedCallback!();
      }
    });

    // Fallback listener for literal pattern if needed
    if (eventName != 'user-deleted-$userId') {
      _socket?.off('user-deleted-$userId');
      _socket?.on('user-deleted-$userId', (data) async {
        debugPrint('Socket response received on [user-deleted-$userId]: $data');
        if (_onUserDeletedCallback != null) {
          await _onUserDeletedCallback!();
        }
      });
    }

    if (_socket != null && !_socket!.connected) {
      _socket!.connect();
    }
  }

  /// Ensures socket is connected or reconnects if connection was dropped in background.
  void ensureConnected(String userId, Future<void> Function() onUserDeleted) {
    _onUserDeletedCallback = onUserDeleted;
    if (_socket == null || !_socket!.connected) {
      initUserDeletedListener(userId, onUserDeleted);
      _socket?.connect();
    }
  }

  /// Stops listening to user-specific deletion events (e.g. on user logout).
  /// Preserves the global socket connection and `user-maintenance-notification` listener.
  void stopListening() {
    _onUserDeletedCallback = null;
    if (_socket != null &&
        _currentUserId != null &&
        _currentUserId!.isNotEmpty) {
      try {
        _socket!.off('user-deleted-$_currentUserId');
      } catch (e) {
        debugPrint('Error removing user-deleted listener: $e');
      }
      _currentUserId = null;
    }
  }

  /// Completely stops all listeners and tears down active socket connection.
  void dispose() {
    stopListening();
    if (_socket != null) {
      try {
        _socket!.off('user-maintenance-notification');
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        debugPrint('Error disconnecting socket: $e');
      }
      _socket = null;
    }
  }
}

/// Internal helper model holding extracted raw maintenance title and description values.
class _MaintenancePayload {
  final dynamic rawTitle;
  final dynamic rawDescription;
  final bool hasTitleKey;
  final bool hasDescriptionKey;

  const _MaintenancePayload({
    this.rawTitle,
    this.rawDescription,
    this.hasTitleKey = false,
    this.hasDescriptionKey = false,
  });
}
