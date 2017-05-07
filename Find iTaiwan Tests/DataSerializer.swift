import XCTest
@testable import Find_iTaiwan

extension Data {
	init?(resource: String?, withExtension extension: String?) {
		guard
			let url = Bundle(for: DataSreializerTests.self).url(forResource: resource, withExtension: `extension`),
			let data = try? Data(contentsOf: url) else {
				return nil
		}
		
		self = data
	}
}

class DataSreializerTests: XCTestCase {
	func testEmpty() {
		let $ = try! DataSerializer.serialize(string: "")
		XCTAssertTrue($.isEmpty)
	}
	
	func testTitleOnly() {
		let data = Data(resource: "titleOnly", withExtension: "csv")!
		let string = String(big5EData: data)!
		let result = try! DataSerializer.serialize(string: string)
		XCTAssertTrue(result.isEmpty)
	}
	
	func testWithFile() {
		let data = Data(resource: "test", withExtension: "csv")!
		let string = String(big5EData: data)!
		let result = try! DataSerializer.serialize(string: string)
		
		XCTAssert(result.count == 6)
		
		typealias Key = DataSerializer.Key
		
		let firstLineDictionary: NSDictionary = [
			Key.city: "臺北市",
			Key.name: "立法院大門會客室",
			Key.address: "中正區中山南路1號",
			Key.latitude: "25.043965",
			Key.longitude: "121.519581"
		]
		XCTAssertTrue(firstLineDictionary == result.first! as NSDictionary)
		
		let lastLineDictionary: NSDictionary = [
			Key.city: "臺北市",
			Key.name: "國家圖書館B1樓閱覽室",
			Key.address: "中正區中山南路20號",
			Key.latitude: "25.03717",
			Key.longitude: "121.516567"
		]
		XCTAssertTrue(lastLineDictionary == result.last! as NSDictionary)
	}
}
