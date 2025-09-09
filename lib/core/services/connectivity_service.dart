import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

class ConnectivityService extends StateNotifier<ConnectivityState> {
  ConnectivityService() : super(const ConnectivityState.unknown()) {
    _startMonitoring();
  }

  final Logger _logger = Logger();
  Timer? _connectivityTimer;
  static const Duration _checkInterval = Duration(seconds: 10);
  static const Duration _timeoutDuration = Duration(seconds: 5);

  void _startMonitoring() {
    // Initial check
    _checkConnectivity();
    
    // Periodic checks
    _connectivityTimer = Timer.periodic(_checkInterval, (_) {
      _checkConnectivity();
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(_timeoutDuration);
      
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        if (state != const ConnectivityState.connected()) {
          _logger.i('Internet connection restored');
          state = const ConnectivityState.connected();
        }
      } else {
        if (state != const ConnectivityState.disconnected()) {
          _logger.w('Internet connection lost');
          state = const ConnectivityState.disconnected();
        }
      }
    } catch (e) {
      if (state != const ConnectivityState.disconnected()) {
        _logger.w('Internet connection check failed: $e');
        state = const ConnectivityState.disconnected();
      }
    }
  }

  /// Force a connectivity check
  Future<bool> checkConnection() async {
    await _checkConnectivity();
    return state == const ConnectivityState.connected();
  }

  /// Check if device is currently online
  bool get isOnline => state == const ConnectivityState.connected();

  /// Check if device is currently offline
  bool get isOffline => state == const ConnectivityState.disconnected();

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }
}

/// Connectivity state representation
class ConnectivityState {
  final ConnectivityStatus status;
  final DateTime? lastChecked;

  const ConnectivityState._(this.status, [this.lastChecked]);

  const ConnectivityState.connected() : this._(ConnectivityStatus.connected);
  const ConnectivityState.disconnected() : this._(ConnectivityStatus.disconnected);
  const ConnectivityState.unknown() : this._(ConnectivityStatus.unknown);

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    DateTime? lastChecked,
  }) {
    return ConnectivityState._(
      status ?? this.status,
      lastChecked ?? this.lastChecked ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectivityState && other.status == status;
  }

  @override
  int get hashCode => status.hashCode;

  @override
  String toString() => 'ConnectivityState(status: $status, lastChecked: $lastChecked)';
}

enum ConnectivityStatus {
  connected,
  disconnected,
  unknown,
}

/// Provider for ConnectivityService
final connectivityServiceProvider = StateNotifierProvider<ConnectivityService, ConnectivityState>((ref) {
  return ConnectivityService();
});

/// Provider for checking if device is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(connectivityServiceProvider);
  return connectivityState.status == ConnectivityStatus.connected;
});

/// Provider for checking if device is offline
final isOfflineProvider = Provider<bool>((ref) {
  final connectivityState = ref.watch(connectivityServiceProvider);
  return connectivityState.status == ConnectivityStatus.disconnected;
});