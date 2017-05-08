import Foundation
import CoreData

@objc(Node)
public class Node: NSManagedObject {
	convenience public init?(_ dictionary: [String: String], insertInto context: NSManagedObjectContext) {
		typealias Key = DataSerializer.Key
		
		guard
			let address = dictionary[Key.address],
			let name = dictionary[Key.name],
			let city = dictionary[Key.city],
			let latitudeString = dictionary[Key.latitude],
			let latitude = Float(latitudeString),
			let longitudeString = dictionary[Key.longitude],
			let longitude = Float(longitudeString) else {
				assertionFailure("Cannot create model with: \(dictionary)")
				return nil
		}
		
		self.init(
			entity: type(of: self).entity(),
			insertInto: context
		)
		self.address = address
		self.name = name
		inCity = City.findOrCreate(name: city, in: context)
		inLocation = Location.findOrCreate(latitude: latitude, longitude: longitude, in: context)
	}
}
