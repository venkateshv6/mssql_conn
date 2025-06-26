
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:mssql_conn/sql_result.dart';

import 'mssql_conn_platform_interface.dart';
import 'dart:io' show Platform;

class MssqlConn {

  String _dns = "";
  String _port = "";
  String _user = "";
  String _password = "";
  String _db = "";

  late MethodChannel channel;

  var connState = _MssqlConnState();
  static bool isResultReceived = false;
  //static SqlResult sqlResult = SqlResult();

  bool isInWaitingState = false;


  MssqlConn(String dns, String port, String user, String password, String db){
    _dns = dns;
    _port = port;
    _user = user;
    _password = password;
    _db = db;
    channel = MssqlConnPlatform.instance.getChannel();
    //channel.setMethodCallHandler((call) => _handleMethodCall(call));
  }

  /*static _handleMethodCall(MethodCall call) async {
    final args = call.arguments as Map;
    //print("From Flutter: $args");
    switch (call.method) {
      case "result":
        sqlResult.status = args["status"] as String;
        sqlResult.statusMsg = args["statusMsg"] as String;
        sqlResult.rowCount = args["rowCount"] as int;
        sqlResult.columnTypes = args["columnTypes"];
        sqlResult.columnNames = args["columnNames"];
        sqlResult.rowDatas = args["rowDatas"] ;
        sqlResult.affectedRowCount = args["affectedRowCount"] as int;
        isResultReceived = true;
        break;

    }
  }*/

  Future<SqlResult> connect( int timeout) async {
    var sqlResult = SqlResult();
    if(isInWaitingState){
      int t = 0; int t2 = 25;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        print("waiting");
        if(!isInWaitingState || t == t2){
          return false;
        }
        t++;
        return true;
      });
    }

    if(isInWaitingState){

      sqlResult.status = "fail";
      sqlResult.statusMsg = "AlreadyInWaitingState";
      return sqlResult;
    }

    isInWaitingState = true;

    String conString = "";
    if(Platform.isAndroid){
      if(_port == "0"){
        conString = "jdbc:jtds:sqlserver://$_dns;databasename=$_db;user=$_user;password=$_password;";
      }else{
        conString = "jdbc:jtds:sqlserver://$_dns:$_port;databasename=$_db;user=$_user;password=$_password;";
      }

    }
    else if(Platform.isWindows){
      if(_port == "0"){
        conString = "DRIVER={SQL Server};Server=$_dns;Database=$_db;UID=$_user;PWD=$_password;";
      }else{
        conString = "DRIVER={SQL Server};Server=$_dns:$_port;Database=$_db;UID=$_user;PWD=$_password;";
      }
    }

    int timeout = 10;
    //clearResult();
    await channel.invokeMethod("SqlConnect", {"con_string": conString,"timeout": timeout}).timeout(const Duration(seconds: 3), onTimeout: (){});


    int t = 0; int t2 = timeout*5;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));

      var result = await channel.invokeMethod("GetResult", {"-": 0}).timeout(const Duration(seconds: 2), onTimeout: (){});

      if(result != "-" && result != null){
        sqlResult.status = "success";
        sqlResult.statusMsg = "connected";
        return false;
      }
      else if(t == t2){
        sqlResult.status = "fail";
        sqlResult.statusMsg = "Flutter TimeOut";
        return false;
      }
      t++;

      return true;
    });


    if(sqlResult.status == "success"){
      connState.set(true);
    }
    else if(sqlResult.status == "fail"){
      connState.set(false);
    }

    isInWaitingState = false;

    return sqlResult;
  }

  Future<SqlResult> disConnect() async {
    var sqlResult = SqlResult();
    if(isInWaitingState){
      int t = 0; int t2 = 25;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        print("waiting");
        if(!isInWaitingState || t == t2){
          return false;
        }
        t++;
        return true;
      });
    }

    if(isInWaitingState){

      sqlResult.status = "fail";
      sqlResult.statusMsg = "AlreadyInWaitingState";
      return sqlResult;
    }

    isInWaitingState = true;
    int timeout = 3;
    //clearResult();
    await channel.invokeMethod("SqlDisconnect", {"msg": "-"}).timeout(const Duration(seconds: 5), onTimeout: (){});

    int t = 0; int t2 = timeout*5;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));

      var result = await channel.invokeMethod("GetResult", {"-": 0}).timeout(const Duration(seconds: 2), onTimeout: (){});

      if(result != "-" && result != null){
        sqlResult.status = "success";
        sqlResult.statusMsg = "disconnected";
        return false;
      }else if(t == t2){
        sqlResult.status = "fail";
        sqlResult.statusMsg = "Flutter TimeOut";
        return false;
      }
      t++;

      return true;
    });

    if(sqlResult.status == "success"){
      connState.set(false);
    }
    else if(sqlResult.status == "fail"){
      connState.set(true);
    }

    isInWaitingState = false;
    return sqlResult;
  }

  Future<SqlResult> readSql(String sqlMsg, int timeout) async {

    var sqlResult = SqlResult();
    if(isInWaitingState){
      int t = 0; int t2 = 25;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        print("waiting");
        if(!isInWaitingState || t == t2){
          return false;
        }
        t++;
        return true;
      });
    }

    if(isInWaitingState){
      sqlResult.status = "fail";
      sqlResult.statusMsg = "AlreadyInWaitingState";
      return sqlResult;
    }

    if(connState.get() == false){
      await connect(5);
    }

    isInWaitingState = true;
    sqlResult.clear();

    await channel.invokeMethod("SqlRead", {"sql": sqlMsg, "timeout": timeout}).timeout(const Duration(seconds: 3), onTimeout: (){});


    int t = 0; int t2 = timeout*5;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));

      var result = await channel.invokeMethod("GetResult", {"-": 0}).timeout(const Duration(seconds: 2), onTimeout: (){});


      if(result != "-" && result != null){

        if(Platform.isAndroid){

          sqlResult.status = "success";
          sqlResult.statusMsg = "got result";
          sqlResult.rowCount = result["rowCount"];
          sqlResult.columnTypes.addAll(result["columnTypes"]);
          sqlResult.columnNames.addAll(result["columnNames"]);
          sqlResult.rowDatas.addAll(result["rowDatas"]);
          sqlResult.affectedRowCount = result["affectedRowCount"];

        }
        else if(Platform.isWindows){
          var result1 = jsonDecode(result);



          sqlResult.status = "success";
          sqlResult.statusMsg = "got result";
          sqlResult.rowCount = result1["rowCount"];
          sqlResult.columnTypes.addAll(result1["columnTypes"]);
          sqlResult.columnNames.addAll(result1["columnNames"]);
          sqlResult.rowDatas.addAll(result1["rowDatas"]);
          sqlResult.affectedRowCount = result1["affectedRowCount"];


        }


        return false;
      }
      else if(t == t2){
        sqlResult.status = "fail";
        sqlResult.statusMsg = "Flutter TimeOut";
        return false;
      }
      t++;

      return true;
    });


    isInWaitingState = false;

    return sqlResult;
  }

  Future<SqlResult> writeSql(String sqlMsg, int timeout) async {
    var sqlResult = SqlResult();
    sqlResult.clear();
    if(isInWaitingState){
      int t = 0; int t2 = 25;
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 200));
        print("waiting");
        if(!isInWaitingState || t == t2){
          return false;
        }
        t++;
        return true;
      });
    }

    if(isInWaitingState){
      sqlResult.status = "fail";
      sqlResult.statusMsg = "AlreadyInWaitingState";
      return sqlResult;
    }

    if(connState.get() == false){
      await connect(5);
    }

    isInWaitingState = true;

    sqlResult.clear();
    await channel.invokeMethod("SqlWrite", {"sql": sqlMsg, "timeout": timeout}).timeout(const Duration(seconds: 3), onTimeout: (){});

    int t = 0; int t2 = timeout*5;
    await Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 200));

      var result = await channel.invokeMethod("GetResult", {"-": 0}).timeout(const Duration(seconds: 2), onTimeout: (){});

      if(result != "-" && result != null){
        if(Platform.isAndroid){

          sqlResult.status = "success";
          sqlResult.statusMsg = "got result";
          sqlResult.rowCount = result["rowCount"];
          sqlResult.columnTypes.addAll(result["columnTypes"]);
          sqlResult.columnNames.addAll(result["columnNames"]);
          sqlResult.rowDatas.addAll(result["rowDatas"]);
          sqlResult.affectedRowCount = result["affectedRowCount"];

        }
        else if(Platform.isWindows){
          var result1 = jsonDecode(result);

          sqlResult.status = "success";
          sqlResult.statusMsg = "got result";
          sqlResult.rowCount = result1["rowCount"];
          sqlResult.columnTypes.addAll(result1["columnTypes"]);
          sqlResult.columnNames.addAll(result1["columnNames"]);
          sqlResult.rowDatas.addAll(result1["rowDatas"]);
          sqlResult.affectedRowCount = result1["affectedRowCount"];
        }
        return false;
      }
      else if(t == t2){
        sqlResult.status = "fail";
        sqlResult.statusMsg = "Flutter TimeOut";
        return false;
      }
      t++;

      return true;
    });

    isInWaitingState = false;
    return sqlResult;
  }

   /*  static void clearResult(){
    sqlResult.status = '';
    sqlResult.statusMsg = '';
    sqlResult.rowCount = 0;
    sqlResult.affectedRowCount = 0;
    if(sqlResult.rowDatas.isNotEmpty) sqlResult.rowDatas.clear();
    if(sqlResult.columnNames.isNotEmpty)sqlResult.columnNames.clear();
    if(sqlResult.columnTypes.isNotEmpty)sqlResult.columnTypes.clear();
    isResultReceived = false;
  }*/

  /*void decodeResult(dynamic result){
    sqlResult.status = result["status"] as String;
    sqlResult.statusMsg = result["statusMsg"] as String;
    sqlResult.rowCount = result["rowCount"] as int;
    sqlResult.columnTypes.addAll(result["columnTypes"]);
    sqlResult.columnNames.addAll(result["columnNames"]);
    sqlResult.rowDatas.addAll(result["rowDatas"]);
    sqlResult.affectedRowCount = result["affectedRowCount"] as int;
  }*/

  Future<String?> getPlatformVersion() {
    return MssqlConnPlatform.instance.getPlatformVersion();
  }

}

class _MssqlConnState with ChangeNotifier {
  bool isConnected = false;

  void set(bool conState) {
    isConnected = conState;
    notifyListeners();
  }

  bool get(){
    return isConnected;
  }
}



