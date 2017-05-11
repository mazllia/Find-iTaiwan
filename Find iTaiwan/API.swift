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
	
	// MARK: Sync properties
	var syncWithServerDelegate: ProgressDelegate? {
		didSet {
			if let delegate = syncWithServerDelegate, let state = syncWithServerState {
				OperationQueue.main.addOperation() { delegate.progressChangedTo(state: state) }
			}
		}
	}
	fileprivate(set) var syncWithServerState: SyncState? {
		didSet {
			if let newValue = syncWithServerState,
				oldValue != newValue, let delegate = syncWithServerDelegate {
				OperationQueue.main.addOperation() { delegate.progressChangedTo(state: newValue) }
			}
		}
	}
	fileprivate let syncWithServerLock = NSLock()
}

// MARK: - Sync -
protocol ProgressDelegate {
	func progressChangedTo(state: API.SyncState)
}

extension API {
	enum SyncState: Equatable {
		case downloading, downloadFailed(error: Error?)
		case parsing(completedUnitCount: Int, totalUnitCount: Int), parsedAndInserted
		
		static func ==(lhs: SyncState, rhs: SyncState) -> Bool {
			switch (lhs, rhs) {
			case (.downloading, .downloading), (.downloadFailed(_), .downloadFailed(_)), (.parsedAndInserted, .parsedAndInserted):
				return true
			case let (.parsing(c1, t1), .parsing(c2, t2)):
				return c1 == c2 && t1 == t2
			default:
				return false
			}
		}
	}
	func syncWithServer() {
		guard syncWithServerLock.tryLockInMainQueue() else {
			return
		}
		syncWithServerState = .downloading
		
		let $ = URLSession.shared.dataTask(with: baseURL.appendingPathComponent("hotspotlist.csv")) { [weak self] (data, response, error) in
			guard error == nil, (response as? HTTPURLResponse)?.statusCode == 200, let data = data else {
				debugPrint("API.syncWithServer() failed for: \(String(describing: error)), with resopnse: \(String(describing: response))")
				self?.syncWithServerState = .downloadFailed(error: error)
				return
			}
			
			func resetDBAndSave(in context: NSManagedObjectContext) {
				context.automaticallyMergesChangesFromParent = true
				context.reset()
				
				let string = String(big5EData: data)!
				let dictionaries = try! DataSerializer.serialize(string: string)
				let entitieCount = dictionaries.count
				for (index, dictionary) in dictionaries.enumerated() {
					_ = Node(dictionary, insertInto: context)
					self?.syncWithServerState = .parsing(completedUnitCount: index, totalUnitCount: entitieCount)
				}
				
				try! context.save()
				
				self?.syncWithServerLock.unlockInMainQueue()
				self?.syncWithServerState = .parsedAndInserted
			}
			self?.modelContainer.performBackgroundTask(resetDBAndSave)
		}
		$.resume()
	}
}

// MARK: - Load and Parse File -
extension API {
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

// MARK: - Thread Safe Lock -
extension NSLock {
	func tryLockInMainQueue() -> Bool {
		if OperationQueue.main == OperationQueue.current {
			return self.try()
		}
		
		var $: Bool?
		let tryOperation = BlockOperation() { $ = self.try() }
		OperationQueue.main.addOperations([tryOperation], waitUntilFinished: true)
		return $!
	}
	
	func unlockInMainQueue() {
		OperationQueue.main.addOperation() { self.unlock() }
	}
}
