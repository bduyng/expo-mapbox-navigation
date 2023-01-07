import ExpoModulesCore
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections


// https://github.com/homeeondemand/react-native-mapbox-navigation/blob/master/ios/MapboxNavigationView.swift

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).


extension ExpoView {
  var parentViewController: UIViewController? {
    var parentResponder: UIResponder? = self
    while parentResponder != nil {
      parentResponder = parentResponder!.next
      if let viewController = parentResponder as? UIViewController {
        return viewController
      }
    }
    return nil
  }
}

class ExpoMapboxNavigationView: ExpoView {
  weak var navViewController: NavigationViewController?
  var embedded: Bool
  var embedding: Bool
  
  let onArrive = EventDispatcher()
  let onError = EventDispatcher()
  let onCancelNavigation = EventDispatcher()
  let onLocationChange = EventDispatcher()
  let onRouteProgressChange = EventDispatcher()
  
  required init(appContext: AppContext? = nil) {
    self.embedded = false
    self.embedding = false
    super.init(appContext: appContext)
    clipsToBounds = true
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if (navViewController == nil && !embedding && !embedded) {
      embed()
    } else {
      navViewController?.view.frame = bounds
    }
  }
  
  override func removeFromSuperview() {
    super.removeFromSuperview()
    // cleanup and teardown any existing resources
    self.navViewController?.removeFromParent()
  }
  
  
  private func embed() {
    embedding = true
    
    
    // Define two waypoints to travel between
    let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
    let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9130752, longitude: -77.0320047), name: "White House")
    
    // Set options
    let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
    
    Directions.shared.calculate(routeOptions) { [weak self] (_, result) in
      guard let strongSelf = self, let parentVC = strongSelf.parentViewController else {
        return
      }
      switch result {
      case .failure(let error):
        strongSelf.onError(["message": error.localizedDescription])
        print(error.localizedDescription)
      case .success(let response):
        
        let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)
        let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
                                                        customRoutingProvider: NavigationSettings.shared.directions,
                                                        credentials: NavigationSettings.shared.directions.credentials,
                                                        simulating: .always)
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let navigationViewController = NavigationViewController(for: indexedRouteResponse,
                                                                navigationOptions: navigationOptions)
        
        navigationViewController.showsEndOfRouteFeedback = false
        NavigationSettings.shared.voiceMuted = false
        navigationViewController.delegate = strongSelf
        
        parentVC.addChild(navigationViewController)
        if (navigationViewController.view != nil) {
          strongSelf.addSubview((navigationViewController.view)!)
        }
        navigationViewController.view.frame = strongSelf.bounds
        navigationViewController.didMove(toParent: parentVC)
        strongSelf.navViewController = navigationViewController
      }
      
      strongSelf.embedding = false
      strongSelf.embedded = true
    }
  }
  
  
}

extension ExpoMapboxNavigationView: NavigationViewControllerDelegate {
  func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
    onLocationChange(["longitude": location.coordinate.longitude, "latitude": location.coordinate.latitude])
    onRouteProgressChange(["distanceTraveled": progress.distanceTraveled,
                           "durationRemaining": progress.durationRemaining,
                           "fractionTraveled": progress.fractionTraveled,
                           "distanceRemaining": progress.distanceRemaining])
  }
  
  func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
    onArrive();
    return true;
  }
  
  func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
    if (!canceled) {
      return;
    }
    onCancelNavigation();
  }
}
