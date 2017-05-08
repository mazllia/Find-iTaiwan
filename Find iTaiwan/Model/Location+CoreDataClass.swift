import Foundation
import CoreData

@objc(Location)
public class Location: NSManagedObject {
	public class func findOrCreate(latitude: Float, longitude: Float, in context: NSManagedObjectContext) -> Location {
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
	
	convenience init(latitude: Float, longitude: Float, insertInto context: NSManagedObjectContext) {
		self.init(entity: type(of: self).entity(), insertInto: context)
		self.latitude = latitude
		self.longitude = longitude
	}
}
