#include "mssql_conn_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>


#include <nanodbc/nanodbc.h>
#include <exception>
#include <sql.h>
#include <sqlext.h>
#include <string>
#include <cmath>
#include <thread>
#include <future>

#pragma comment(lib, "odbc32.lib")

#include <memory>
#include <sstream>

#include <picojson/picojson.h>

using namespace std;
using namespace flutter;

namespace mssql_conn {

    double round_d(double var, int precision = 2)
    {
        // if precision = 3 then
        // 37.66666 * 10^3 =37666.66
        // 37666.66 + .5 =37667.1    for rounding off value
        // then type cast to <int> so value is 37667
        // then divided by 10^3 so the value converted into 37.667
        if (precision < 0) precision = 0;
        double value = (var >= 0) ? (int)(var * pow(10, precision) + .5) : (int)(var * pow(10, precision) - .5);
        return value / pow(10, precision);
    }


    double round_to(double value, double precision = 2.0)
    {
        return std::round(value / precision) * precision;
    }

    class Semaphore {
    public:
        Semaphore(int count_ = 0)
            : count(count_) {}

        inline void notify()
        {
            std::unique_lock<std::mutex> lock(mtx);
            count++;
            cv.notify_one();
        }

        inline void wait()
        {
            std::unique_lock<std::mutex> lock(mtx);

            while (count == 0) {
                cv.wait(lock);
            }
            count--;
        }

    private:
        std::mutex mtx;
        std::condition_variable cv;
        int count;
    };

    Semaphore sem(1);

    class SqlResult
    {
    public:
        string status = "Ok";
        string statusMsg = "Not_ok";
        int rowCount = 0;
        vector<EncodableValue> rowDatas = {};  //with inner vector
        vector<vector<string>> rowDatas1 = {};  //with inner vector
        vector<vector<EncodableValue>> rowDatas3 = {};  //with inner vector
        //vector<map<string, string>> rowDatas = {};
        vector<EncodableValue> columnNames = {};
        vector<EncodableValue> columnTypes = {};
        int affectedRowCount = 0;

        void clear() {
            status = "";
            statusMsg = "";
            rowCount = 0;
            rowDatas = {};
            rowDatas1 = {};
            columnNames = {};
            columnTypes = {};
            affectedRowCount = 0;
        }
       

    };

    picojson::object r; //resultJson

   
    //inputs uses sem(1)
    string msg = "", sql = "", methodName = "", con_string = "";
    int timeout = 20;
    bool isExecuted = false;





  
    HANDLE hThread;
    DWORD WINAPI DoStuff(LPVOID lpParameter)
    {

        nanodbc::connection conn;
        
      
       

        while (1) {
            std::this_thread::sleep_for(std::chrono::milliseconds(50));
            //cout << "Test" << endl;

            sem.wait();
            //cout << "enters" << endl;
            string msg1 = msg;
            string sql1 = sql;
            int timeout1 = timeout;
            string method1 = methodName;
            //isExecuted = false;
            sem.notify();

          
            if (method1.length() > 0) {

                std::cout << "MethodName1: " << method1 << timeout1 << endl;


                
                r.clear();
                string status = "";
                string statusMsg = "";
                double rowCount = 0;
                double affectedRowCount = 0;

                picojson::array rowDatas;
                picojson::array columnNamesList;
                picojson::array columnTypesList;
                

               

                


                r["status"] = picojson::value(status);
                r["statusMsg"] = picojson::value(statusMsg);
                r["rowCount"] = picojson::value(rowCount);
                r["affectedRowCount"] = picojson::value(affectedRowCount);
                r["rowDatas"] = picojson::value(rowDatas);
                r["columnNames"] = picojson::value(columnNamesList);
                r["columnTypes"] = picojson::value(columnTypesList);
                



                if (method1.compare("SqlConnect") == 0) {
                   

                    try {
                        //"DRIVER={SQL Server};Server=52.172.9.26;Database=OS_PROD_QC;UID=OSQC;PWD=Pr0sarv1ce;"
                        // constr = "DRIVER={SQL Server};Server=52.172.9.25;Database=OS_PROD_QC;UID=OSQC;PWD=Pr0sarv1ce;";
                        auto const connstr = NANODBC_TEXT(con_string); // an ODBC connection string to your database

                       //auto const connstr = NANODBC_TEXT(constr); // an ODBC connection string to your database

                        //std::cerr << "Test14" << std::endl;

                        conn = nanodbc::connection(connstr, 5);
                        //nanodbc::connection conn1(connstr, 5);
                        //cout << "Connected with driver:  " << conn1.driver_name() << endl;

                        status = "success";
                        statusMsg = "connected";


                        // std::cerr << "Test1" << std::endl;

                         //PostMessage(hwnd1, 0xFF01, 0, 0);

                    }
                    catch (...) {
                        //std::cerr << e.what() << std::endl;
                        std::cout << "Connection error" << endl;
                        // sqlResult.status = "fail";
                        // sqlResult.statusMsg = string("Connection Error");
                    }

                    std::cerr << "Done" << std::endl;
                }

                if (method1.compare("SqlDisconnect") == 0) {
                    std::cout<< "Test line 189 " << endl;


                    try {

                        conn.disconnect();
                        if (conn.connected() == false) {
                            status = "success";
                            statusMsg = "dis_connected";
                        }
                        else {
                            status = "fail";
                            statusMsg = "not_dis_connected";
                        }

                    }
                    catch (std::runtime_error e) {
                        std::cerr << e.what() << std::endl;
                        status = "fail";
                        statusMsg = string(e.what());
                    }
                   
                }
               

               
                if (method1.compare("SqlRead") == 0) {
                    std::cout << "Test line 263 " << endl;


                    if (!conn.connected()) {
                        status = "fail";
                        statusMsg = "not_connected";
                    }

                    else {





                        try {

                            nanodbc::result set = nanodbc::execute(conn, NANODBC_TEXT(sql1), 1L, timeout);
                            //auto set = nanodbc::execute(conn, NANODBC_TEXT("SELECT * FROM model_records"));
                            //auto set = nanodbc::execute(conn, NANODBC_TEXT("UPDATE performance_records SET SelfPrimingTime = 6, Remarks = 'Test' WHERE Id = 17"));

                            //vector<EncodableValue> list = {};



                            while (set.next())
                            {


                                if (rowCount == 0) {
                                    for (int i = 0; i < set.columns(); i++) {
                                        string columnName = set.column_name((short)i);
                                        string dataTypeName = set.column_datatype_name(columnName);
                                        //cout << "Result: " << dataTypeName << endl;

                                        columnNamesList.push_back(picojson::value(columnName));
                                        columnTypesList.push_back(picojson::value(dataTypeName));

                                    }


                                }




                                picojson::array rowDataList;

                                for (short i = 0; i < set.columns(); i++) {

                                    string typeName = set.column_datatype_name(i);
                                    // cout << "TypeName: " << typeName << endl;



                                    if (typeName.compare("int identity") == 0) {
                                        auto data = set.get<int>(i, 0);
                                        std::cout << "data: " << data << endl;
                                        rowDataList.push_back(picojson::value((double)data));
                                    }
                                    else if (typeName.compare("int") == 0) {
                                        auto data = set.get<int>(i, 0);
                                        rowDataList.push_back(picojson::value((double)data));
                                    }
                                    //int identity
                                    else if (typeName.compare("real") == 0) {
                                        auto data = set.get<double>(i, 0.0);
                                        double roundedValue = round_d(data);
                                        rowDataList.push_back(picojson::value(roundedValue));
                                    }
                                    else if (typeName.compare("varchar") == 0) {

                                        auto data = set.get<string>(i, "null");
                                        rowDataList.push_back(picojson::value(data));
                                    }
                                    else if (typeName.compare("nvarchar") == 0) {
                                        auto data = set.get<string>(i, "null");
                                        rowDataList.push_back(picojson::value(data));
                                    }
                                    else if (typeName.compare("datetime") == 0) {
                                        auto data = set.get<string>(i, "null");
                                        rowDataList.push_back(picojson::value(data));
                                    }
                                    else if (typeName.compare("datetime2") == 0) {
                                        auto data = set.get<string>(i, "null");
                                        rowDataList.push_back(picojson::value(data));
                                    }
                                    else if (typeName.compare("tinyint") == 0) {
                                        auto data = set.get<int>(i, 0);
                                        rowDataList.push_back(picojson::value((double)data));
                                    }
                                    else {
                                        std::cout << "UnImplementedType \n" << endl;
                                    }






                                    //auto data = set.get<string>((short)i);

                                }



                                rowDatas.push_back(picojson::value(rowDataList));

                                // sqlResult.rowDatas.push_back(EncodableValue(list));

                                rowCount = rowCount + 1;

                            }






                            rowCount = rowCount;
                            status = "success";
                            statusMsg = "query_success";
                        }
                        catch (std::runtime_error e) {
                            std::cerr << e.what() << std::endl;
                            status = "fail";
                            statusMsg = string(e.what());
                        }



                    }
                }

                if (method1.compare("SqlWrite") == 0) {

                    if (!conn.connected()) {
                        status = "fail";
                        statusMsg = "not_connected";
                    }
                    else {
                        try {
                            auto set = nanodbc::execute(conn, NANODBC_TEXT(sql), 1L, timeout);

                            if (set.has_affected_rows()) {
                                affectedRowCount = (int)set.affected_rows();
                            }
                            else {
                                affectedRowCount = 0;
                            }

                            status = "success";
                            statusMsg = "query_success";
                        }
                        catch (std::runtime_error e) {
                            std::cerr << e.what() << std::endl;
                            status = "fail";
                            statusMsg = string(e.what());
                        }
                        

                    }
                }               
                
               
                


                r["status"] = picojson::value(status);
                r["statusMsg"] = picojson::value(statusMsg);
                r["rowCount"] = picojson::value(rowCount);
                r["affectedRowCount"] = picojson::value(affectedRowCount);
                r["rowDatas"] = picojson::value(rowDatas);
                r["columnNames"] = picojson::value(columnNamesList);
                r["columnTypes"] = picojson::value(columnTypesList);


                std::cout << "Test line 437 " << endl;

                //std::cout << picojson::value(r).serialize() << endl;

                sem.wait();
                method1 = "";
                methodName = "";
                isExecuted = true;
                sem.notify();
           
            }

 
        }
        return 0;

    }

// static
void MssqlConnPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "mssql_conn",
          &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<MssqlConnPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));

  hThread = CreateThread(
      NULL,    // Thread attributes
      0,       // Stack size (0 = use default)
      DoStuff, // Thread start address
      NULL,    // Parameter to pass to the thread
      0,       // Creation flags
      NULL);   // Thread id
  if (hThread == NULL)
  {
      // Thread creation failed.
      // More details can be retrieved by calling GetLastError()
      //return 1;
  }
}

MssqlConnPlugin::MssqlConnPlugin() {}

MssqlConnPlugin::~MssqlConnPlugin() {}

void MssqlConnPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {



    string sql1 = "", msg1 = "", methodName1 = "", con_string1 = "";
    int timeout1 = 20;

    methodName1 = method_call.method_name();

    if (methodName1.compare("GetResult") != 0) {
        timeout1 = 20;
        const auto* arguments = std::get_if<EncodableMap>(method_call.arguments());

        auto sql_it = arguments->find(EncodableValue("sql"));
        auto msg_it = arguments->find(EncodableValue("msg"));
        auto timeout_it = arguments->find(EncodableValue("timeout"));
        auto con_string_it = arguments->find(EncodableValue("con_string"));

        if (sql_it != arguments->end())
        {
            sql1 = std::get<std::string>(sql_it->second);
        }
        if (msg_it != arguments->end())
        {
            msg1 = std::get<std::string>(msg_it->second);
        }
        if (timeout_it != arguments->end())
        {
            timeout1 = std::get<int>(timeout_it->second);
        }
        if (con_string_it != arguments->end())
        {
            con_string1 = std::get<std::string>(con_string_it->second);
        }

        std::cout << "sql: " << sql1 << endl;
        std::cout << "msg: " << msg1 << endl;
        std::cout << "timeout: " << timeout1 << endl;
        std::cout << "method: " << methodName1 << endl;
        std::cout << "con_string1: " << con_string1 << endl;
    }
    
  
    


    

    if (methodName1.compare("GetResult") == 0) {

        sem.wait();
        if (isExecuted == true) {
            //result->Success(flutter::EncodableValue(constructResult(sqlResult)));
            result->Success(flutter::EncodableValue(picojson::value(r).serialize()));
            isExecuted = false;
        }
        else {
            result->Success(flutter::EncodableValue("-"));
        }

        sem.notify();

    }
    else {
        sem.wait();
        sql = sql1;
        msg = msg1;
        timeout = timeout1;
        methodName = methodName1;
        con_string = con_string1;
        isExecuted = false;
        sem.notify();

        result->Success(flutter::EncodableValue("-"));
    }



}

}  // namespace mssql_conn
