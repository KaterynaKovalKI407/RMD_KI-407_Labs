import Flutter
import UIKit
import AVFoundation

public class FlutterLightPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "flutter_light_plugin", binaryMessenger: registrar.messenger())
    let instance = FlutterLightPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "onLight":
      toggleTorch(result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func toggleTorch(result: @escaping FlutterResult) {
    if let device = AVCaptureDevice.default(for: .video), device.hasTorch {
      do {
        try device.lockForConfiguration()
        if device.torchMode == .on {
          device.torchMode = .off
          result("Torch off")
        } else {
          try device.setTorchModeOn(level: 1.0)
          result("Torch on")
        }
        device.unlockForConfiguration()
      } catch {
        result(FlutterError(code: "UNAVAILABLE", message: "Torch not available on this device", details: nil))
      }
    } else {
      result(FlutterError(code: "UNAVAILABLE", message: "Torch not available on this device", details: nil))
    }
  }
}