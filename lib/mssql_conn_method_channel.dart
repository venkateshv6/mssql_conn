import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mssql_conn_platform_interface.dart';

/// An implementation of [MssqlConnPlatform] that uses method channels.
class MethodChannelMssqlConn extends MssqlConnPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mssql_conn');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  MethodChannel getChannel() {
    return methodChannel;
  }
}
