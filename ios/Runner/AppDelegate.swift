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

// MARK: - Guided-generation schemas (iOS 26+)
//
// @Generable lets the on-device model fill a typed struct directly, which is
// far more reliable than prompting for JSON and hoping it parses. Each type
// maps 1:1 to the JSON contract the Dart side already understands, so the app
// treats an on-device estimate exactly like a cloud one.

#if canImport(FoundationModels)
@available(iOS 26.0, *)
@Generable
struct GenFoodItem {
  @Guide(description: "Simple, generic food name, e.g. 'chicken biryani', 'white rice'")
  var name: String
  @Guide(description: "Portion actually eaten, e.g. '1 plate', '2', '200 ml', '1 serving'")
  var portion: String
  @Guide(description: "Best estimate of total calories for this portion")
  var calories: Int
  @Guide(description: "Grams of protein in this portion")
  var proteinG: Double
  @Guide(description: "Grams of fiber in this portion")
  var fiberG: Double
  @Guide(description: "Grams of carbohydrate in this portion")
  var carbsG: Double
  @Guide(description: "Grams of fat in this portion")
  var fatG: Double
  @Guide(description: "Exactly one of: clean, moderate, dense")
  var quality: String
}

@available(iOS 26.0, *)
@Generable
struct GenMeal {
  @Guide(description: "One item per distinct food in the meal")
  var items: [GenFoodItem]
  @Guide(description: "One short, friendly note about the meal's energy impact")
  var note: String
  @Guide(description: "Exactly one of: high, medium, low")
  var confidence: String
}

@available(iOS 26.0, *)
@Generable
struct GenBeverage {
  var name: String
  @Guide(description: "Grams of sugar in this drink")
  var sugarG: Double
  @Guide(description: "Exactly one of: water, caffeine, alcohol, protein")
  var type: String
}

@available(iOS 26.0, *)
@Generable
struct GenExercise {
  var activity: String
  var durationMinutes: Int
  @Guide(description: "Exactly one of: low, moderate, vigorous")
  var intensity: String
}

@available(iOS 26.0, *)
@Generable
struct GenVoiceLog {
  @Guide(description: "Every distinct food eaten, with a calorie and macro estimate each")
  var foods: [GenFoodItem]
  @Guide(description: "Every drink mentioned")
  var beverages: [GenBeverage]
  @Guide(description: "Millilitres of plain water added, 0 if none")
  var hydrationMl: Int
  @Guide(description: "Any exercise or movement mentioned")
  var exercise: [GenExercise]
  @Guide(description: "Exactly one of: flat, steady, high_spike")
  var glycemicLoad: String
  @Guide(description: "True if a short walk would help after this")
  var postMealActionRequired: Bool
  @Guide(description: "Suggested post-meal walk in minutes, 0 if none")
  var recommendedWalkMinutes: Int
  @Guide(description: "One short, warm, energy-framed coaching line about what was logged")
  var coachingMessage: String
}
#endif

/// Bridges Apple's on-device FoundationModels LLM (iOS 26+) to Dart. It parses
/// and estimates nutrition entirely on-device — free, private, offline — for
/// any food, including ones no bundled table would know. Reports unavailable on
/// older iOS / unsupported devices, where the app falls back to its Dart parser.
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
    case "estimateMeal":
      guard let description = call.arguments as? String else { result(nil); return }
      FoundationModelPlugin.estimateMeal(description, result: result)
    case "parseVoiceLog":
      guard let transcript = call.arguments as? String else { result(nil); return }
      FoundationModelPlugin.parseVoiceLog(transcript, result: result)
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

  // MARK: Meal nutrition estimation

  static func estimateMeal(_ description: String, result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task {
        do {
          let session = LanguageModelSession(instructions: mealInstructions)
          let response = try await session.respond(
            to: "Meal: \(description)", generating: GenMeal.self)
          let json = Self.mealJson(response.content)
          DispatchQueue.main.async { result(json) }
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

  // MARK: Voice-log parsing

  static func parseVoiceLog(_ transcript: String, result: @escaping FlutterResult) {
    #if canImport(FoundationModels)
    if #available(iOS 26.0, *) {
      Task {
        do {
          let session = LanguageModelSession(instructions: voiceInstructions)
          let response = try await session.respond(
            to: "Log: \(transcript)", generating: GenVoiceLog.self)
          let json = Self.voiceJson(response.content)
          DispatchQueue.main.async { result(json) }
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

  // MARK: JSON encoding (match the Dart contracts)

  #if canImport(FoundationModels)
  @available(iOS 26.0, *)
  static func foodDict(_ f: GenFoodItem) -> [String: Any] {
    return [
      "name": f.name, "portion": f.portion, "quantity": f.portion,
      "calories": f.calories, "protein_g": f.proteinG, "fiber_g": f.fiberG,
      "carbs_g": f.carbsG, "fat_g": f.fatG, "quality_score": f.quality,
    ]
  }

  @available(iOS 26.0, *)
  static func mealJson(_ m: GenMeal) -> String? {
    let obj: [String: Any] = [
      "confidence": m.confidence,
      "note": m.note,
      "items": m.items.map(foodDict),
    ]
    return jsonString(obj)
  }

  @available(iOS 26.0, *)
  static func voiceJson(_ v: GenVoiceLog) -> String? {
    let obj: [String: Any] = [
      "log_summary": [
        "food_items": v.foods.map(foodDict),
        "beverages": v.beverages.map {
          ["name": $0.name, "sugar_content_g": $0.sugarG, "type": $0.type]
        },
        "hydration_added_ml": v.hydrationMl,
        "exercise_logged": v.exercise.map {
          ["activity": $0.activity, "duration_minutes": $0.durationMinutes,
           "intensity": $0.intensity]
        },
      ],
      "energy_impact_analysis": [
        "glycemic_load_estimate": v.glycemicLoad,
        "post_meal_action_required": v.postMealActionRequired,
        "recommended_walk_minutes": v.recommendedWalkMinutes,
      ],
      "coaching_message": v.coachingMessage,
    ]
    return jsonString(obj)
  }

  static func jsonString(_ obj: [String: Any]) -> String? {
    guard let data = try? JSONSerialization.data(withJSONObject: obj) else { return nil }
    return String(data: data, encoding: .utf8)
  }
  #endif

  static let mealInstructions = """
  You are a nutrition estimator. Given a meal description, break it into its \
  distinct foods and estimate realistic nutrition for the portion actually \
  eaten. Use your knowledge of common dishes from every cuisine — Indian, \
  Asian, Mediterranean, American, everything. Give usable numbers, never \
  zeros. Judge quality as 'clean' (whole foods, lean protein, vegetables), \
  'dense' (fried, sugary, refined), or 'moderate'. Set confidence by how \
  specific the description is.
  """

  static let voiceInstructions = """
  You turn a spoken health log into structured data. Pull out every food \
  (with a realistic calorie and macro estimate for the portion), every drink, \
  any plain water in millilitres, and any exercise. Use your knowledge of \
  dishes from every cuisine. Then write one short, warm, energy-framed \
  coaching line about what was logged. If a meal is carb-dense, set \
  glycemicLoad to 'high_spike' and suggest a short walk.
  """
}
