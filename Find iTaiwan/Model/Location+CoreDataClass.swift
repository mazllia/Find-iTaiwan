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
		let latitudeRange = region.latitudeRange
		let longitudeRange = region.longitudeRange
		
		let $: NSFetchRequest<Location> = fetchRequest()
		$.predicate = NSPredicate(format: "latitude >= %@ && latitude <= %@ && longitude >= %@ && longitude <= %@",
		                          latitudeRange.lowerBound.toNSNumber, latitudeRange.upperBound.toNSNumber,
		                          longitudeRange.lowerBound.toNSNumber, longitudeRange.upperBound.toNSNumber
		)
		return $
	}
}

extension MKCoordinateRegion {
	var latitudeRange: ClosedRange<CLLocationDegrees> {
		return (center.latitude - span.latitudeDelta / 2 ... center.latitude + span.latitudeDelta / 2)
	}
	
	var longitudeRange: ClosedRange<CLLocationDegrees> {
		return (center.longitude - span.longitudeDelta / 2 ... center.longitude + span.longitudeDelta / 2)
	}
}

private let numberFormatter = NumberFormatter()
fileprivate extension LosslessStringConvertible {
	var toNSNumber: NSNumber {
		return numberFormatter.number(from: description)!
	}
}
