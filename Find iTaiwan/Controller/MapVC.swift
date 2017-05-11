import UIKit
import CoreLocation
import MapKit
import CoreData

class MapVC: UIViewController {
	/**
	To prevent too many annotations showing in map, this threshold provides threshold guidance depends on current _size classes_.
	- cameraDistance: if map.camera.altitude is smaller than this, show annotations
	- annotationCount: if matched annotations are smaller than this, show annotations
	*/
	internal var annotationVisibleThreshold: (cameraDistance: CLLocationDistance, annotationCount: Int) {
		switch (traitCollection.horizontalSizeClass, traitCollection.verticalSizeClass) {
		case (.regular , .regular):
			return (100000, 1200)
		case (.compact, _), (_, .compact):
			return (60000, 500)
		default:
			return (60000, 500)
		}
	}
	
	@IBOutlet weak var mapView: MKMapView!
	let locationManager = CLLocationManager()
	
	var api: API = API.default
	
	// MARK: FetchedResultsController
	fileprivate(set) var locations = [Location]()
	func updateLocationAndAnnotation(in map: MKMapView) {
		let previousLocations = locations
		let didShowAnnotaions = !map.annotations.isEmpty
		
		locations = try! api.modelContainer.viewContext.fetch(
			Location.fetchRequest(in: map.region)
		)
				
		let shouldShowAnnotations: Bool = {
			let $ = annotationVisibleThreshold
			return map.camera.altitude < $.cameraDistance ||
				locations.count < $.annotationCount
		}()
		
		func configureNavigationBar() {
			let noLocationOnScreen = locations.isEmpty
			
			switch (shouldShowAnnotations, noLocationOnScreen) {
			case (_, true):
				navigationItem.title = NSLocalizedString("No router in this area", comment: "Navigaition item title when no annotation can be shown on screen")
				navigationItem.prompt = nil
				navigationController?.setNavigationBarHidden(false, animated: true)
				
			case (false, _):
				// TODO: Formatted localization
				navigationItem.title = locations.count.description + " " +
					NSLocalizedString("locations", comment: "When map does not reached annotationVisibleThreshold, shows navigation item title string")
				navigationItem.prompt = NSLocalizedString("zoom in for details", comment: "When map does not reached annotationVisibleThreshold, shows navigation item prompt string")
				navigationController?.setNavigationBarHidden(false, animated: true)
				
			default:
				navigationItem.title = nil
				navigationItem.prompt = nil
				navigationController?.setNavigationBarHidden(true, animated: true)
			}
		}
		func configureAnnotations() {
			guard shouldShowAnnotations else {
				map.removeAnnotations(map.annotations)
				return
			}
			
			let newlyInsertedLocations = didShowAnnotaions ? Set(locations).subtracting(previousLocations).allObjects : locations
			let removedLocations = Set(previousLocations).subtracting(locations).allObjects
			
			map.removeAnnotations(removedLocations)
			map.addAnnotations(newlyInsertedLocations)
		}
		
		configureNavigationBar()
		configureAnnotations()
	}
	
	// MARK: Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Note: Request location asap to avoid map view loads nonrelated resources
		func requestLocationAuthorization() {
			if CLLocationManager.authorizationStatus() == .notDetermined {
				locationManager.requestWhenInUseAuthorization()
			}
		}
		requestLocationAuthorization()
		
		mapView.setUserTrackingMode(.follow, animated: false)
		
		NotificationCenter.default.addObserver(self, selector: #selector(dataBaseDidReload(_:)), name: NSNotification.Name.NSManagedObjectContextObjectsDidChange, object: api.modelContainer.viewContext)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	// MARK: Action
	@IBAction func follow(_ sender: Any) {
		switch CLLocationManager.authorizationStatus() {
		case .notDetermined:
			locationManager.requestWhenInUseAuthorization()
			
		case .denied, .restricted:
			presentAlert(
				title: NSLocalizedString("Location Service", comment: "When failed to authorized from CoreLocation, alert controller title"),
				message: NSLocalizedString("We need your permission to follow you by getting your location info.", comment: "When failed to authorized from CoreLocation, alert controller message"),
				actionTitle: NSLocalizedString("Go Settings", comment: "When failed to authorized from CoreLocation, alert action go settings string"),
				actionHandler: { UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil) }
			)
			
		case .authorizedAlways, .authorizedWhenInUse:
			mapView.setUserTrackingMode(.follow, animated: true)
		}
	}
	
	override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
		let shouldHideToolBar = traitCollection.verticalSizeClass == .compact
		navigationController?.setToolbarHidden(shouldHideToolBar, animated: false)
		
		// TODO: In simulator, changing orientation will not call `mapView(_:, regionDidChangeAnimated:)`, the following call as consequence. Test in device!
		mapView(mapView, regionDidChangeAnimated: false)
	}
	
	func dataBaseDidReload(_: Any) {
		updateLocationAndAnnotation(in: mapView)
	}
}

// MARK: - Delegates
// MARK: Map View
extension MapVC: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		 updateLocationAndAnnotation(in: mapView)
	}
}

// MARK: - Set helper
extension Set {
	var allObjects: [Element] {
		return map() { $0 }
	}
}
