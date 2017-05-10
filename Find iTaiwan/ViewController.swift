import UIKit
import CoreLocation
import MapKit
import CoreData

class ViewController: UIViewController {
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
	fileprivate(set) var resultsController: NSFetchedResultsController<Location>!
	func setupResultsControllerAndUpdateAnnotation(in map: MKMapView) {
		let previousLocations = resultsController?.fetchedObjects ?? []
		let didShowAnnotaions = !map.annotations.isEmpty
		
		resultsController = {
			let request: NSFetchRequest<Location> = Location.fetchRequest(in: map.region)
			
			// Arbitrary sort descriptor as we don't leverage on such feature of NSFetchedResultsController
			request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
			
			
			let $ = NSFetchedResultsController(
				fetchRequest: request,
				managedObjectContext: api.modelContainer.viewContext,
				sectionNameKeyPath: nil,
				cacheName: nil
			)
			$.delegate = self
			return $
		}()
		try! resultsController.performFetch()
		
		assert(resultsController.fetchedObjects != nil)
		
		let locations = resultsController.fetchedObjects ?? []
		
		let shouldShowAnnotations: Bool = {
			let $ = annotationVisibleThreshold
			return map.camera.altitude < $.cameraDistance ||
				locations.count < $.annotationCount
		}()
		guard shouldShowAnnotations else {
			// TODO: Formatted localization
			navigationItem.title = locations.count.description + NSLocalizedString("routers", comment: "When map camera latitude has not reached max visible annotations, shows navigation item title string")
			navigationItem.prompt = NSLocalizedString("zoom in for details", comment: "When map camera latitude has not reached max visible annotations, shows navigation item prompt string")
			navigationController?.setNavigationBarHidden(false, animated: true)
			
			map.removeAnnotations(map.annotations)
			return
		}
		
		navigationItem.title = nil
		navigationItem.prompt = nil
		navigationController?.setNavigationBarHidden(true, animated: true)
		
		let newlyInsertedLocations = didShowAnnotaions ? Set(locations).subtracting(previousLocations).allObjects : locations
		let removedLocations = Set(previousLocations).subtracting(locations).allObjects
		
		map.removeAnnotations(removedLocations)
		map.addAnnotations(newlyInsertedLocations)
	}
	
	// MARK: Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		navigationController?.setNavigationBarHidden(true, animated: false)
		
		// Note: Request location asap to avoid map view loads nonrelated resources
		func requestLocationAuthorization() {
			if CLLocationManager.authorizationStatus() == .notDetermined {
				locationManager.requestWhenInUseAuthorization()
			}
		}
		requestLocationAuthorization()
		
		mapView.setUserTrackingMode(.follow, animated: false)
	}
}

// MARK: - Delegates
// MARK: FetchedResultsController
extension ViewController: NSFetchedResultsControllerDelegate {
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
	                didChange anObject: Any,
	                at indexPath: IndexPath?,
	                for type: NSFetchedResultsChangeType,
	                newIndexPath: IndexPath?) {
		
		switch type {
		case .insert:
			let $ = resultsController.object(at: newIndexPath!)
			mapView.addAnnotation($)
			
		case .delete:
			let $ = resultsController.object(at: indexPath!)
			mapView.removeAnnotation($)
			
		case .update:
			// No need to command any refresh as MapKit uses KVO in MKAnnotation
			// - seealso: `MKAnnotationCalloutInfoDidChange` supports legacy applications and is no longer necessary. MapKit tracks changes to the title and subtitle of an annotation using KVO notifications
			break
			
		case .move:
			break
		}
	}
}

// MARK: Map View
extension ViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		 setupResultsControllerAndUpdateAnnotation(in: mapView)
	}
}

// MARK: - Set helper
extension Set {
	var allObjects: [Element] {
		return map() { $0 }
	}
}
