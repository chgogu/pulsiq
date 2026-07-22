import Flutter
import UIKit

#if canImport(FoundationModels)
import FoundationModels
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "FoundationModelPlugin") {
      FoundationModelPlugin.register(with: registrar)
    }
  }
}

/// Bridges Apple's on-device FoundationModels LLM (iOS 26+) to Dart. Used to
/// parse messy meal descriptions into structured items at $0, on-device, and
/// privately. Reports unavailable on older iOS / unsupported devices, where the
/// app falls back to its Dart parser and the cloud model.
public class FoundationModelPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "pulsiq/foundation_model",
      binaryMessenger: registrar.messenger())
    registrar.addMethodCallDelegate(FoundationModelPlugin(), channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "available":
      result(FoundationModelPlugin.isAvailable())
    case "parseMeal":
      guard let description = call.arguments as? String else {
        result(nil)
        return
      }
      FoundationModelPlugin.parseMeal(description, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  static func isAvailable() -> Bool {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      if case .available = SystemLanguageModel.default.availability { return true }
    }
    #endif
    return false
  }

  static func parseMeal(_ description: String, result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task {
        do {
          let session = LanguageModelSession(instructions: Self.instructions)
          let response = try await session.respond(to: "Meal: \(description)")
          // Extract the String (Sendable) before hopping to the main queue.
          let content = response.content
          DispatchQueue.main.async { result(content) }
        } catch {
          DispatchQueue.main.async {
            result(FlutterError(code: "fm_error", message: "\(error)", details: nil))
          }
        }
      }
      return
    }
    #endif
    result(nil)
  }

  static let instructions = """
  You extract the distinct foods from a meal description. Reply with ONLY a \
  JSON object of the form {"items":[{"name":"food","quantity":"amount"}]}. \
  Use quantities like "2", "1 cup", "half", "200 ml", or "1 serving" when the \
  amount is unspecified. Split every distinct food into its own item, even \
  when they run together without commas. Keep each name simple and generic \
  (e.g. "chicken breast", "white rice", "spinach"). No prose — JSON only.
  """
}
