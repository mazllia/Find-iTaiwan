import Foundation
import CoreData

@objc(City)
public class City: NSManagedObject {
	public class func findOrCreate(name: String, in context: NSManagedObjectContext) -> City {
		let request: NSFetchRequest<City> = {
			let $: NSFetchRequest<City> = fetchRequest()
			$.predicate = NSPredicate(format: "name == %@", name)
			return $
		}()
		
		let results = try! context.fetch(request)
		return results.first ?? City(name: name, insertInto: context)
	}
	
	convenience init(name: String, insertInto context: NSManagedObjectContext) {
		self.init(entity: type(of: self).entity(), insertInto: context)
		self.name = name
	}
}
