import Foundation
import CoreData

public class ModelContainer: NSPersistentContainer {
	static let `default`: ModelContainer = {
		let $ = ModelContainer(name: "Find_iTaiwan")
		$.loadPersistentStores() { (storeDescription, error) in
			if let error = error {
				assertionFailure("Loading core data stack error:\(error) of store \(storeDescription)")
			}
		}
		return $
	}()
	
	public func clearAll() {
		viewContext.reset()
		try! viewContext.save()
	}
}
