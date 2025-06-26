import 'package:flutter/src/services/platform_channel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mssql_conn/mssql_conn.dart';
import 'package:mssql_conn/mssql_conn_platform_interface.dart';
import 'package:mssql_conn/mssql_conn_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockMssqlConnPlatform
    with MockPlatformInterfaceMixin
    implements MssqlConnPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  MethodChannel getChannel() {
    // TODO: implement getChannel
    throw UnimplementedError();
  }
}

void main() {
  final MssqlConnPlatform initialPlatform = MssqlConnPlatform.instance;

  test('$MethodChannelMssqlConn is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelMssqlConn>());
  });

  test('getPlatformVersion', () async {
    MssqlConn mssqlConnPlugin = MssqlConn("", "", "", "", "");
    MockMssqlConnPlatform fakePlatform = MockMssqlConnPlatform();
    MssqlConnPlatform.instance = fakePlatform;

    expect(await mssqlConnPlugin.getPlatformVersion(), '42');
  });
}
