import ExpoModulesCore

public class ExpoMapboxNavigationModule: Module {
  public func definition() -> ModuleDefinition {
    Name("ExpoMapboxNavigation")

    Constants([
      "PI": Double.pi
    ])

    Events("onChange")

    Function("hello") {
      return "Hello world! 👋"
    }

    AsyncFunction("setValueAsync") { (value: String) in
      self.sendEvent("onChange", [
        "value": value
      ])
    }

    View(ExpoMapboxNavigationView.self) {
      Prop("name") { (view: ExpoMapboxNavigationView, prop: String) in
        print(prop)
      }
    }
  }
}
