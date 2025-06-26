import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:mssql_conn/mssql_conn.dart';
import 'package:mssql_conn/sql_result.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  var ip = "52.172.9.26"; //"52.172.9.26"
  var port = "0";
  var db = "OS_PROD_QC";
  var user = "OSQC";
  var password = "Pr0sarv1ce";

  late MssqlConn _mssqlConn;

  String status = "";
  String statusMsg = "";
  int rowCount = 0;



  @override
  void initState() {
    super.initState();
    initPlatformState();

    _mssqlConn = MssqlConn(ip, port, user, password, db);

    _mssqlConn.connState.addListener(() {
      print("DbConnectionState: ${_mssqlConn.connState.isConnected}");
    });

  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;

    if (!mounted) return;

  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body:  Center(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: (){connect();}, child: const Text("Connect")),
                  ElevatedButton(onPressed: (){read();}, child: const Text("SqlRead")),
                  ElevatedButton(onPressed: (){write();}, child: const Text("SqlWrite")),
                  ElevatedButton(onPressed: (){disconnect();}, child: const Text("Disconnect"))
                ],
              ),

              Text("Status: $status"),
              Text("StatusMsg: $statusMsg"),
              Text("RowCount: $rowCount"),


            ],
          ),
        ),
      ),
    );
  }

  Future<void> connect() async {
    SqlResult result = await _mssqlConn.connect(10);
    status = result.status;
    statusMsg = result.statusMsg;
    rowCount = result.rowCount;
    setState(() {});
  }

  Future<void> read() async {
    String sql = "SELECT * FROM model_records WHERE ManufacturerId LIKE '%ProPumps%'";
    SqlResult result = await _mssqlConn.readSql(sql, 20);
    status = result.status;
    statusMsg = result.statusMsg;
    rowCount = result.rowCount;

    print("TestMsg: ${result.rowDatas}");
    print("TestMsg: ${result.columnTypes}");
    print("TestMsg: ${result.columnNames}");
    print("length: ${result.rowDatas.length}");

    print("test: ${result.getData(1, 'MinVoltage')}");


    setState(() {});
  }

  Future<void> write() async {
    SqlResult result = await _mssqlConn.readSql("select * from model_records", 20);
    status = result.status;
    statusMsg = result.statusMsg;
    rowCount = result.rowCount;

    setState(() {});
  }

  Future<void> disconnect() async {
    SqlResult result = await _mssqlConn.disConnect();
    status = result.status;
    statusMsg = result.statusMsg;
    rowCount = result.rowCount;

    setState(() {});
  }

}
