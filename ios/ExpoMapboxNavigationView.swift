import ExpoModulesCore
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections


// https://github.com/homeeondemand/react-native-mapbox-navigation/blob/master/ios/MapboxNavigationView.swift

// This view will be used as a native component. Make sure to inherit from `ExpoView`
// to apply the proper styling (e.g. border radius and shadows).
class ExpoMapboxNavigationView: ExpoView, NavigationViewControllerDelegate {
  weak var navViewController: NavigationViewController?
  let onArrive = EventDispatcher()
  let onError = EventDispatcher()
  let onCancelNavigation = EventDispatcher()
  let onLocationChange = EventDispatcher()
  let onRouteProgressChange = EventDispatcher()
  
  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    clipsToBounds = true
    
    // Define two waypoints to travel between
    let origin = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.9131752, longitude: -77.0324047), name: "Mapbox")
    let destination = Waypoint(coordinate: CLLocationCoordinate2D(latitude: 38.8977, longitude: -77.0365), name: "White House")
    
    // Set options
    let routeOptions = NavigationRouteOptions(waypoints: [origin, destination])
    
    Directions.shared.calculate(routeOptions) { [weak self] (_, result) in
      guard let strongSelf = self else {
        return
      }
      switch result {
      case .failure(let error):
        print(error.localizedDescription)
      case .success(let response):
        guard let weakSelf = self else {
          return
        }
        let navigationService = MapboxNavigationService(routeResponse: response, routeIndex: 0, routeOptions: routeOptions, simulating: .always)
        
        let navigationOptions = NavigationOptions(navigationService: navigationService)
        let vc = NavigationViewController(for: response, routeIndex: 0, routeOptions: routeOptions, navigationOptions: navigationOptions)
        
        // vc.showsEndOfRouteFeedback = strongSelf.showsEndOfRouteFeedback
        // StatusView.appearance().isHidden = strongSelf.hideStatusView
        
        // NavigationSettings.shared.voiceMuted = strongSelf.mute;
        
        vc.delegate = strongSelf
        
        //          parentVC.addChild(vc)
        if (vc.view != nil) {
          strongSelf.addSubview((vc.view)!)
        }
        strongSelf.addSubview(vc.view)
        vc.view.frame = strongSelf.bounds
        //          vc.didMove(toParent: parentVC)
        strongSelf.navViewController = vc
        print(response)
      }
    }
  }
  
  override func layoutSubviews() {
    navViewController?.view.frame = bounds
  }
  
  func navigationViewController(_ navigationViewController: NavigationViewController, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
    onLocationChange(["longitude": location.coordinate.longitude, "latitude": location.coordinate.latitude])
    onRouteProgressChange(["distanceTraveled": progress.distanceTraveled,
                           "durationRemaining": progress.durationRemaining,
                           "fractionTraveled": progress.fractionTraveled,
                           "distanceRemaining": progress.distanceRemaining])
  }
  
  func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
    if (!canceled) {
      return;
    }
    onCancelNavigation();
  }
  
  func navigationViewController(_ navigationViewController: NavigationViewController, didArriveAt waypoint: Waypoint) -> Bool {
    onArrive();
    return true;
  }
}
