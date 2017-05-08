import Foundation
import CoreData

@objc(Node)
public class Node: NSManagedObject {
	convenience public init?(_ dictionary: [String: String], insertInto context: NSManagedObjectContext) {
		typealias Key = DataSerializer.Key
		
		guard Set(Key.allKeys).isSubset(of: dictionary.keys) else {
			assertionFailure("Cannot create model with: \(dictionary)")
			return nil
		}
		
		self.init(
			entity: type(of: self).entity(),
			insertInto: context
		)
		address = dictionary[Key.address]
		name = dictionary[Key.name]
		inCity = City.findOrCreate(name: dictionary[Key.city]!, in: context)
		inLocation = Location.findOrCreate(
			latitude: Float(dictionary[Key.latitude]!)!,
			longitude: Float(dictionary[Key.longitude]!)!,
			in: context
		)
	}
}

private extension DataSerializer.Key {
	static var allKeys: [String] {
		return [city, name, address, latitude, longitude]
	}
}
