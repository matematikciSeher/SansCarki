import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let performanceChannel = FlutterMethodChannel(name: "performance_detector",
                                                  binaryMessenger: controller.binaryMessenger)
    performanceChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getDeviceInfo" {
        self.getDeviceInfo(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  private func getDeviceInfo(result: FlutterResult) {
    let deviceModel = UIDevice.current.model
    let systemVersion = UIDevice.current.systemVersion
    
    let deviceInfo: [String: Any] = [
      "model": deviceModel,
      "systemVersion": systemVersion
    ]
    
    result(deviceInfo)
  }
}
