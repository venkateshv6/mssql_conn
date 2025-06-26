

import 'dart:io';

class SqlResult {
  String status = "";
  String statusMsg = "";
  int rowCount = 0;
  var rowDatas = [];
  var columnNames = [];
  var columnTypes = [];
  int affectedRowCount = 0;

  dynamic getData(int rowIndex, String parameter){
    if(Platform.isAndroid){
      int? parameterIndex = columnNames.indexOf(parameter);
      var data = rowDatas[rowIndex][parameterIndex];
      return data;
    }
    else if(Platform.isWindows){
      int? parameterIndex = columnNames.indexOf(parameter);
      String? type = columnTypes[parameterIndex];
      if(type == "int identity"){

        if(rowDatas[rowIndex][parameterIndex].runtimeType == int){
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }else if(rowDatas[rowIndex][parameterIndex].runtimeType == double){
          var data = (rowDatas[rowIndex][parameterIndex]).toInt();
          return data;
        }
        else{
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }

      }
      else if(type == "int"){

        if(rowDatas[rowIndex][parameterIndex].runtimeType == int){
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }else if(rowDatas[rowIndex][parameterIndex].runtimeType == double){
          var data = (rowDatas[rowIndex][parameterIndex]).toInt();
          return data;
        }
        else{
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }

      }
      else if(type == "real"){

        if(rowDatas[rowIndex][parameterIndex].runtimeType == int){
          var data = (rowDatas[rowIndex][parameterIndex]).toDouble();
          return data;
        }else if(rowDatas[rowIndex][parameterIndex].runtimeType == double){
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }
        else{
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }

      }
      else if(type == "tinyint"){

        if(rowDatas[rowIndex][parameterIndex].runtimeType == int){
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }else if(rowDatas[rowIndex][parameterIndex].runtimeType == double){
          var data = (rowDatas[rowIndex][parameterIndex]).toInt();
          return data;
        }
        else{
          var data = rowDatas[rowIndex][parameterIndex];
          return data;
        }

      }
      else{
        var data = rowDatas[rowIndex][parameterIndex];
        return data;
      }
    }

  }

  void clear(){
    status = '';
    statusMsg = '';
    rowCount = 0;
    affectedRowCount = 0;
    if(rowDatas.isNotEmpty) rowDatas.clear();
    if(columnNames.isNotEmpty)columnNames.clear();
    if(columnTypes.isNotEmpty)columnTypes.clear();
  }

}