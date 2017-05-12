import Foundation
import CoreData

public class ModelContainer: NSPersistentContainer {
	fileprivate static let sqliteExtensions = ["sqlite", "sqlite-shm", "sqlite-wal"]
	static let defaultPrebuildDataBaseURL = Bundle.main.url(forResource: "prebuild", withExtension: "sqlite")!
	
	let persistentStoreURL: URL
	
	static let `default`: ModelContainer = {
		let $ = ModelContainer(name: "Find_iTaiwan")
		
		func loadPrebuildDataIfNeeded() {
			if !FileManager.default.fileExists(atPath: $.persistentStoreURL.path) {
				try! $.copyPrebuildPersistenStore(url: defaultPrebuildDataBaseURL)
			}
		}
		
		loadPrebuildDataIfNeeded()
		$.loadPersistentStores() { (storeDescription, error) in
			if let error = error {
				assertionFailure("Loading core data stack error:\(error) of store \(storeDescription)")
			}
		}
		return $
	}()
	
	public override init(name: String, managedObjectModel model: NSManagedObjectModel) {
		persistentStoreURL = type(of: self).defaultDirectoryURL()
			.appendingPathComponent(name)
			.appendingPathExtension("sqlite")
		super.init(name: name, managedObjectModel: model)
		viewContext.automaticallyMergesChangesFromParent = true
	}
	
	func copyPrebuildPersistenStore(url: URL) throws {
		try FileManager.default.copyItem(at: url, to: persistentStoreURL)
	}
	
	func removePersistentStores() throws {
		try persistentStoreCoordinator
			.persistentStores.forEach() { try persistentStoreCoordinator.remove($0) }
		
		try type(of: self).sqliteExtensions
			.flatMap() { persistentStoreURL.deletingPathExtension().appendingPathExtension($0) }
			.forEach() { try FileManager.default.removeItem(at: $0) }
	}
}
