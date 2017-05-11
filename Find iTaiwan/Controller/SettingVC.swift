import Foundation
import UIKit

class SettingVC: UITableViewController {
	@IBOutlet weak var updateButton: UIButton!
	@IBOutlet weak var updateIndicator: UIActivityIndicatorView!
	@IBOutlet weak var updateProgressDescriptionLabel: UILabel!
	@IBOutlet weak var updateProgressView: UIProgressView!
	
	var api: API = API.default
	
	// MARK: Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
		
		api.syncWithServerDelegate = self
	}
	
	deinit {
		if let delegate = api.syncWithServerDelegate as? SettingVC, self == delegate {
			api.syncWithServerDelegate = nil
		}
	}
	
	// MARK: Action
	@IBAction func update(_ sender: Any) {
		updateProgressView.setProgress(0, animated: false)
		api.syncWithServer()
	}
	
	func resetToPrebuildData() {
		api.resetToBuildInDataBase()
	}
}

// MARK: - Delegate
// MARK: Table View
extension SettingVC {
	static let authorWebsite = URL(string: "https://people.cs.nctu.edu.tw/~pytai/")
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		
		switch (indexPath.section, indexPath.row) {
		case (0, 1):
			presentOKCancelAlert(
				title: nil,
				message: NSLocalizedString("This would clear newly downloaded data and restore to built-in data.", comment: "Setting scene reset DB alert message"),
				okHandler: resetToPrebuildData
			)
			
		case (1, _):
			guard let url = type(of: self).authorWebsite else {
				return
			}
			UIApplication.shared.open(url, options: [:], completionHandler: nil)
			
		default:
			break
		}
	}
}

// MARK: Progress
extension SettingVC: ProgressDelegate {
	private func updateProgressHidden(state: API.SyncState) {
		switch state {
		case .downloadFailed:
			updateButton.isEnabled = true
			updateIndicator.stopAnimating()
			updateProgressView.isHidden = true
			updateProgressDescriptionLabel.isHidden = true
			
		case .parsedAndInserted:
			updateButton.isEnabled = true
			updateIndicator.stopAnimating()
			updateProgressView.isHidden = true
			updateProgressDescriptionLabel.isHidden = false
			
		default:
			updateButton.isEnabled = false
			updateIndicator.startAnimating()
			updateProgressView.isHidden = false
			updateProgressDescriptionLabel.isHidden = false
		}
	}
	
	func progressChangedTo(state: API.SyncState) {
		if case let .parsing(completedUnitCount, totalUnitCount) = state {
			updateProgressView.setProgress(Float(completedUnitCount) / Float(totalUnitCount), animated: true)
		}
		
		if case .downloadFailed(_) = state {
			presentAlert(
				title: NSLocalizedString("Download failed", comment: "API.SyncState.downloadFailed description"),
				message: state.description,
				actionTitle: NSLocalizedString("Retry", comment: "Retry action title shown when API.SyncState.dowloading = .downloadFailed"),
				actionHandler: { self.update(self) }
			)
		}
		
		updateProgressDescriptionLabel.text = state.description
		updateProgressHidden(state: state)
	}
}

// MARK: Description of API.SyncState
extension API.SyncState: CustomStringConvertible {
	var description: String {
		switch self {
		case let .downloadFailed(error):
			return error?.localizedDescription ?? ""
		case .downloading:
			return NSLocalizedString("downloading from server", comment: "API.SyncState.dowloading description")
		case .parsedAndInserted:
			return NSLocalizedString("Update Success :)", comment: "API.SyncState.parsedAndInserted description")
		case let .parsing(completedUnitCount, totalUnitCount):
			// TODO: Formatted localization
			return NSLocalizedString("processing", comment: "API.SyncState.dowloading parsing") + " \(completedUnitCount)/\(totalUnitCount)"
		}
	}
}
