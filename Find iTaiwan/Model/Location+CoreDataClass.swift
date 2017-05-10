import Foundation
import CoreData

@objc(Location)
public class Location: NSManagedObject {
	internal class func findOrCreate(latitude: Float, longitude: Float, in context: NSManagedObjectContext) -> Location {
		let request: NSFetchRequest<Location> = {
			let $: NSFetchRequest<Location> = fetchRequest()
			$.predicate = NSPredicate(format: "latitude == %@ AND longitude == %@",
			                          NSNumber(value: latitude),
			                          NSNumber(value: longitude)
			)
			return $
		}()
		
		let results = try! context.fetch(request)
		return results.first ?? Location(latitude: latitude, longitude: longitude, insertInto: context)
	}
	
	convenience fileprivate init(latitude: Float, longitude: Float, insertInto context: NSManagedObjectContext) {
		self.init(entity: type(of: self).entity(), insertInto: context)
		self.latitude = latitude
		self.longitude = longitude
	}
}

import MapKit
public extension Location {
	class func fetchRequest(in region: MKCoordinateRegion) -> NSFetchRequest<Location> {
		let latitudeRange = (region.center.latitude - region.span.latitudeDelta / 2 ...
			region.center.latitude + region.span.latitudeDelta / 2
		)
		let longitudeRange = (region.center.longitude - region.span.longitudeDelta / 2 ...
			region.center.longitude + region.span.longitudeDelta / 2
		)
		
		let $: NSFetchRequest<Location> = fetchRequest()
		$.predicate = NSPredicate(format: "latitude >= %@ && latitude <= %@ && longitude >= %@ && longitude <= %@",
		                          NSNumber(value: latitudeRange.lowerBound), NSNumber(value: latitudeRange.upperBound),
		                          NSNumber(value: longitudeRange.lowerBound), NSNumber(value: longitudeRange.upperBound)
		)
		return $
	}
}
