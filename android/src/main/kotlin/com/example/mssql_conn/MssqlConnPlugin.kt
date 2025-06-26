package com.example.mssql_conn

import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.math.RoundingMode
import java.sql.Connection
import java.sql.ResultSet
import java.text.DecimalFormat
import java.util.concurrent.Semaphore
import java.util.logging.Handler

/** MssqlConnPlugin */
class MssqlConnPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var connection: Connection;

  private val s = Semaphore(2)

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mssql_conn")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(call: MethodCall, result: Result) {

    var msg:String = "";
    var sql:String = "";
    var timeout:Int = 20;
    var conString:String = "";

    if(call.method != "GetResult"){
      val args = call.arguments as Map<*, *>
      if(args.containsKey("sql")){
        sql = args["sql"] as String;
      }
      if(args.containsKey("msg")){
        msg = args["msg"] as String;
      }
      if(args.containsKey("timeout")){
        timeout = args["timeout"] as Int;
      }
      if(args.containsKey("con_string")){
        conString = args["con_string"] as String;
      }
    }



    when (call.method) {
      "GetResult" ->{

        if(s.tryAcquire()){
          val st = SqlResult.status;
          s.release();

          if(st != ""){
            result.success(constructResult());
          }else{
            result.success("-");
          }
        }



      }
      "SqlConnect" -> {

        Thread{
          s.acquireUninterruptibly()
          SqlResult.clear();
          s.release();
          try {
            val con = ConMsSql();
            connection = con.conClass(conString);

            if(!connection.isClosed){
              s.acquireUninterruptibly()
              SqlResult.status = "success"
              SqlResult.statusMsg = "connected"
              s.release();
            }
            else{
              s.acquireUninterruptibly()
              SqlResult.status = "fail"
              SqlResult.statusMsg = "connection_failed"
              s.release();
            }

          }
          catch (e: Exception){
            s.acquireUninterruptibly()
            SqlResult.status = "fail"
            SqlResult.statusMsg = "${e.message}"
            s.release();
          }




        }.start();


        result.success("-");
      }
      "SqlRead" -> {

        s.acquireUninterruptibly()
        SqlResult.clear();
        s.release();

        if(connection.isClosed){
          Log.d("result:", "NotConnected")
          s.acquireUninterruptibly()
          SqlResult.status = "fail"
          SqlResult.statusMsg = "not_connected"
          s.release();
          return
        }

        Thread {
          try {
            val sqlStatement = sql
            val smt = connection.createStatement();
            smt.queryTimeout = timeout;
            val set: ResultSet = smt.executeQuery(sqlStatement);


            while (set.next()){

              s.acquireUninterruptibly()
              //Construct headerList
              if(SqlResult.rowCount == 0){
                for(i in 1..set.metaData.columnCount){
                  SqlResult.columnNames.add(set.metaData.getColumnName(i))
                  SqlResult.columnTypes.add(set.metaData.getColumnTypeName(i))
                  // Log.d("headers:", set.metaData.getColumnTypeName(i))
                }
                // Log.d("headers:", sqlResult.columnNames.toString())
              }


              //Construct rows
              //val map: MutableMap<String, Any?> = mutableMapOf();
              val rowDataList: MutableList<Any?> = mutableListOf();
              for(i in 1..set.metaData.columnCount){

                val type:String = set.metaData.getColumnTypeName(i);

                when(type){
                  "int" ->{rowDataList.add(set.getInt(i))}
                  "int identity" ->{rowDataList.add(set.getInt(i))}
                  "real" ->{ rowDataList.add(roundOffDecimal(set.getDouble(i)))}
                  "varchar" ->{rowDataList.add(set.getString(i))}
                  "nvarchar" ->{rowDataList.add(set.getString(i))}
                  "datetime" ->{rowDataList.add(set.getString(i))}
                  "datetime2" ->{rowDataList.add(set.getString(i))}
                  "tinyint" ->{rowDataList.add(set.getInt(i))}
                }


              }


              SqlResult.rowDatas.add(rowDataList.toList())


              SqlResult.rowCount++;

              s.release();
            }

            //Log.d("data", "Construction Success: ${sqlResult.rowDatas.toString().length}")
            //Log.d("data", "Construction Success: ${sqlResult.rowDatas.toString()}")

            s.acquireUninterruptibly()
            SqlResult.status = "success"
            SqlResult.statusMsg = "query_success"
            s.release();


          } catch (e: Exception) {
            Log.e("SqlError:", "${e.message}")
            s.acquireUninterruptibly()
            SqlResult.status = "fail"
            SqlResult.statusMsg = "${e.message}"
            s.release();
          }



        }.start();

        result.success("-");

      }
      "SqlWrite" -> {

        s.acquireUninterruptibly()
        SqlResult.clear();
        s.release();

        if(connection.isClosed){
          Log.d("result:", "NotConnected")
          s.acquireUninterruptibly()
          SqlResult.status = "fail"
          SqlResult.statusMsg = "not_connected"
          s.release();
          return
        }

        Thread{
          try {
            //Log.d("Sql:", "$sql");
            val sqlStatement = sql
            val smt = connection.createStatement()
            smt.queryTimeout = timeout;
            val state:Int = smt.executeUpdate(sqlStatement)


            if(state > 0){
              s.acquireUninterruptibly()
              SqlResult.status = "ok"
              SqlResult.statusMsg = "query_success"
              SqlResult.affectedRowCount = state;
              s.release();
            }else if(state == 0){
              s.acquireUninterruptibly()
              SqlResult.status = "fail"
              SqlResult.statusMsg = "query_failed"
              SqlResult.affectedRowCount = state;
              s.release();
            }


          }catch (e: Exception){
            Log.e("SqlError:", "${e.message}")
            s.acquireUninterruptibly()
            SqlResult.status = "fail"
            SqlResult.statusMsg = "${e.message}"
            s.release();
          }

          //sendResult();

        }.start();

        result.success("-");

      }
      "SqlDisconnect" -> {

        Thread{
          s.acquireUninterruptibly()
          SqlResult.clear();
          s.release();
          try{
            connection.close();
            if(connection.isClosed){
              s.acquireUninterruptibly()
              SqlResult.status = "success";
              SqlResult.statusMsg = "dis_connected";
              s.release();
            }else{
              s.acquireUninterruptibly()
              SqlResult.status = "fail";
              SqlResult.statusMsg = "not_dis_connected";
              s.release();
            }
          }
          catch (e: Exception){
            Log.e("SqlError:", "${e.message}")
            s.acquireUninterruptibly()
            SqlResult.status = "fail";
            SqlResult.statusMsg = "${e.message}";
            s.release();
          }
          //sendResult();
        }.start();


        result.success("-");

      }
      else -> {
        result.success("-");
      }
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  private fun roundOffDecimal(number: Double): Double {
    val df = DecimalFormat("#.###")
    df.roundingMode = RoundingMode.FLOOR
    return df.format(number).toDouble()
  }

  private fun constructResult(): HashMap<String, Any> {

    val map = hashMapOf<String, Any>(
      "status" to SqlResult.status,
      "statusMsg" to SqlResult.statusMsg,
      "rowCount" to SqlResult.rowCount,
      "rowDatas" to SqlResult.rowDatas,
      "columnNames" to SqlResult.columnNames,
      "columnTypes" to SqlResult.columnTypes,
      "affectedRowCount" to SqlResult.affectedRowCount,
    );

    //Log.e("Length:", "${map.toString().length}")


    return map;
  }

  private fun sendResult(){
    android.os.Handler(Looper.getMainLooper()).post {
      channel.invokeMethod("result", constructResult())
    };
  }

}
