import XCTest
@testable import Find_iTaiwan
import CoreData

class ModelTests: XCTestCase {
	struct TestData {
		typealias Key = DataSerializer.Key
		
		static let entity1 = [
			Key.city: "臺北市",
			Key.name: "立法院大門會客室",
			Key.address: "中正區中山南路1號",
			Key.latitude: "25.043965",
			Key.longitude: "121.519581"
		]
		
		static let entity2 = [
			Key.city: "臺北市",
			Key.name: "國家圖書館B1樓閱覽室",
			Key.address: "中正區中山南路20號",
			Key.latitude: "25.03717",
			Key.longitude: "121.516567"
		]
	}
	
	static var modelContainer: ModelContainer!
	
	/// Clear all data in root context, tests are performed in temporary clear context
    override class func setUp() {
		modelContainer = ModelContainer(name: "Test Coordinator", managedObjectModel: ModelContainer.default.managedObjectModel)
		modelContainer.loadPersistentStores() { _, error in
			assert(error == nil)
			assert(modelContainer.viewContext.registeredObjects.count == 0)
		}
		
		super.setUp()
    }
    
    override class func tearDown() {
		modelContainer.persistentStoreDescriptions.forEach() {
			if let URL = $0.url {
				[
					URL,
					URL.deletingPathExtension().appendingPathExtension("sqlite-shm"),
					URL.deletingPathExtension().appendingPathExtension("sqlite-wal")
					]
					.forEach() { try! FileManager.default.removeItem(at: $0) }
			}
		}
		
        super.tearDown()
    }
    
    func testConfiguration() {
		let context = type(of: self).modelContainer.newBackgroundContext()
		
		func testNodeProperty(node: Node, dictionary: [String: String]) {
			XCTAssertEqual(node.name, dictionary[TestData.Key.name])
			XCTAssertEqual(node.address, dictionary[TestData.Key.address])
			
			XCTAssertEqual(node.inCity?.name, dictionary[TestData.Key.city])
			
			let latitude = Float(dictionary[TestData.Key.latitude]!)!
			let longitude = Float(dictionary[TestData.Key.longitude]!)!
			XCTAssertEqual(node.inLocation?.latitude, latitude)
			XCTAssertEqual(node.inLocation?.longitude, longitude)
		}
		
		let node1 = Node(TestData.entity1, insertInto: context)!
		let node2 = Node(TestData.entity2, insertInto: context)!
		
		testNodeProperty(node: node1, dictionary: TestData.entity1)
		testNodeProperty(node: node2, dictionary: TestData.entity2)
		
		XCTAssertEqual(node1.inCity, node2.inCity)
		XCTAssertNotEqual(node1.inLocation, node2.inLocation)
		
		XCTAssert(context.registeredObjects.count == 5)
    }	
}
