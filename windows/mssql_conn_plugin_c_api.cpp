#include "include/mssql_conn/mssql_conn_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "mssql_conn_plugin.h"

void MssqlConnPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  mssql_conn::MssqlConnPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
