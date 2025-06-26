#ifndef FLUTTER_PLUGIN_MSSQL_CONN_PLUGIN_H_
#define FLUTTER_PLUGIN_MSSQL_CONN_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

using namespace std;

namespace mssql_conn {

class MssqlConnPlugin : public flutter::Plugin {
 public:

  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  MssqlConnPlugin();

  virtual ~MssqlConnPlugin();

  // Disallow copy and assign.
  MssqlConnPlugin(const MssqlConnPlugin&) = delete;
  MssqlConnPlugin& operator=(const MssqlConnPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace mssql_conn

#endif  // FLUTTER_PLUGIN_MSSQL_CONN_PLUGIN_H_
