package com.example.mssql_conn

import android.os.StrictMode
import android.util.Log
import java.sql.Connection
import java.sql.DriverManager

class ConMsSql {
    private lateinit var con:Connection;

    fun conClass(conString: String):Connection{

        val ip: String = "52.172.9.25"
        val port: String = "1433"
        val db:String = "OS_PROD_QC"
        val userName:String = "OSQC"
        val password:String = "Pr0sarv1ce"

        val a:StrictMode.ThreadPolicy = StrictMode.ThreadPolicy.Builder().permitAll().build();
        StrictMode.setThreadPolicy(a);

        var connectUrl:String = "";
        // connectUrl = "jdbc:jtds:sqlserver://$ip;databasename=$db;user=$userName;password=$password;"

        try {
            Class.forName("net.sourceforge.jtds.jdbc.Driver")
            connectUrl = conString
            con = DriverManager.getConnection(connectUrl)
            Log.d("Sql:","Connected")
        }
        catch (e:Exception){
            Log.e("Error is", e.message.toString());
        }

        return con;


    }

}