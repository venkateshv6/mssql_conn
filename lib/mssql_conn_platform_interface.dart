import 'package:flutter/services.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mssql_conn_method_channel.dart';

abstract class MssqlConnPlatform extends PlatformInterface {
  /// Constructs a MssqlConnPlatform.
  MssqlConnPlatform() : super(token: _token);

  static final Object _token = Object();

  static MssqlConnPlatform _instance = MethodChannelMssqlConn();

  /// The default instance of [MssqlConnPlatform] to use.
  ///
  /// Defaults to [MethodChannelMssqlConn].
  static MssqlConnPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MssqlConnPlatform] when
  /// they register themselves.
  static set instance(MssqlConnPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  MethodChannel getChannel(){
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
