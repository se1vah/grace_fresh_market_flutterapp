import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../config/env_config.dart';

class SocketService {
  SocketService._internal();
  static final SocketService instance = SocketService._internal();

  io.Socket? _socket;
  String? _currentUserId;
  Future<void> Function()? _onUserDeletedCallback;

  /// Initializes socket connection and listens to `user-deleted-<USER_ID>` event.
  /// When a response is received on this socket, [onUserDeleted] is triggered.
  void initUserDeletedListener(
    String userId,
    Future<void> Function() onUserDeleted,
  ) {
    final cleanUserId = userId.trim();
    if (cleanUserId.isEmpty) return;

    _onUserDeletedCallback = onUserDeleted;

    if (_socket != null && _currentUserId == cleanUserId && _socket!.connected) {
      return;
    }

    if (_socket != null && _currentUserId != cleanUserId) {
      stopListening();
    }

    _currentUserId = cleanUserId;
    _onUserDeletedCallback = onUserDeleted;
    final serverUrl = EnvConfig.socketHost;
    final eventName = 'user-deleted-$cleanUserId';

    try {
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
        debugPrint('Socket connected to $serverUrl for channel: $eventName');
      });

      _socket!.onConnectError((err) {
        debugPrint('Socket connection error: $err');
      });

      _socket!.onError((err) {
        debugPrint('Socket error: $err');
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket disconnected for channel: $eventName');
      });

      // Listen on user-deleted-<USER_ID> event
      _socket!.on(eventName, (data) async {
        debugPrint('Socket response received on [$eventName]: $data');
        if (_onUserDeletedCallback != null) {
          await _onUserDeletedCallback!();
        }
      });

      // Fallback listener for literal pattern if needed
      if (eventName != 'user-deleted-$userId') {
        _socket!.on('user-deleted-$userId', (data) async {
          debugPrint('Socket response received on [user-deleted-$userId]: $data');
          if (_onUserDeletedCallback != null) {
            await _onUserDeletedCallback!();
          }
        });
      }

      if (!_socket!.connected) {
        _socket!.connect();
      }
    } catch (e) {
      debugPrint('Error initializing socket for $eventName: $e');
    }
  }

  /// Ensures socket is connected or reconnects if connection was dropped in background
  void ensureConnected(String userId, Future<void> Function() onUserDeleted) {
    _onUserDeletedCallback = onUserDeleted;
    if (_socket == null || !_socket!.connected) {
      initUserDeletedListener(userId, onUserDeleted);
      _socket?.connect();
    }
  }

  /// Stops listening and closes active socket connection.
  void stopListening() {
    _onUserDeletedCallback = null;
    if (_socket != null) {
      try {
        if (_currentUserId != null && _currentUserId!.isNotEmpty) {
          _socket!.off('user-deleted-$_currentUserId');
        }
        _socket!.disconnect();
        _socket!.dispose();
      } catch (e) {
        debugPrint('Error disconnecting socket: $e');
      }
      _socket = null;
      _currentUserId = null;
    }
  }
}
