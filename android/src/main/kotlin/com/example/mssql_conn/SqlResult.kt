package com.example.mssql_conn

object SqlResult {
    var status: String = "";
    var statusMsg: String = "";
    var rowCount: Int = 0;
    var rowDatas: MutableList<List<Any?>> = mutableListOf()
    // var rowDatas: MutableList<Map<String, Any?>> = mutableListOf()
    var columnNames: MutableList<String> = mutableListOf();
    var columnTypes: MutableList<String> = mutableListOf();
    var affectedRowCount:Int = 0;


    fun clear(){
        status = "";
        statusMsg = "";
        rowCount = 0;
        affectedRowCount = 0;
        if(rowDatas.isNotEmpty()) rowDatas.clear();
        if(columnNames.isNotEmpty()) columnNames.clear();
        if(columnTypes.isNotEmpty()) columnTypes.clear();
    }
}