import Foundation
import CoreData

class API {
	static let `default`: API = API(
		baseURL: URL(string: "https://itaiwan.gov.tw/func")!,
		modelContainer: ModelContainer.default
	)
	
	init(baseURL: URL, modelContainer: ModelContainer) {
		self.baseURL = baseURL
		self.modelContainer = modelContainer
	}
	
	let baseURL: URL
	let modelContainer: ModelContainer
	
	func syncWithServer() -> URLSessionDataTask {
		return URLSession.shared.dataTask(with: baseURL.appendingPathComponent("hotspotlist.csv")) { [weak self] (data, response, error) in
			guard error == nil, (response as? HTTPURLResponse)?.statusCode == 200, let data = data else {
				debugPrint("API.syncWithServer() failed for: \(String(describing: error)), with resopnse: \(String(describing: response))")
				return
			}
			
			func resetDBAndSave(in context: NSManagedObjectContext) {
				context.automaticallyMergesChangesFromParent = true
				context.reset()
				
				let string = String(big5EData: data)!
				try! DataSerializer.serialize(string: string)
					.forEach() { _ = Node($0, insertInto: context) }
				
				try! context.save()
			}
			self?.modelContainer.performBackgroundTask(resetDBAndSave)
		}
	}
	
	func load(resource: String, extension: String = "csv", inBundle bundle: Bundle = Bundle.main) {
		guard let URL = bundle.url(forResource: resource, withExtension: `extension`),
		let data = try? Data(contentsOf: URL),
		let string = String(big5EData: data)
		else {
			return
		}
		
		modelContainer.performBackgroundTask() { context in
			context.reset()
			try! DataSerializer.serialize(string: string)
				.forEach() { _ = Node($0, insertInto: context) }
			try! context.save()
		}
	}
}
