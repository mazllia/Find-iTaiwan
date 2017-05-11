import Foundation
import UIKit

extension UIAlertController {
	convenience init(title: String?, message: String?, style: UIAlertControllerStyle, actionTitle: String, actionHandler: (() -> ())?) {
		self.init(title: title, message: message, preferredStyle: style)
		[
			UIAlertAction(title: actionTitle, style: .default, handler: { _ in actionHandler?() }),
			UIAlertAction(title: NSLocalizedString("Cancel", comment: "Common alert controller cancel title"), style: .cancel, handler: nil)
			].forEach() { addAction($0) }
	}
}

extension UIViewController {
	func presentAlert(title: String?, message: String?, actionTitle: String, actionHandler: (() -> ())?) {
		let $ = UIAlertController(title: title, message: message, style: .alert, actionTitle: actionTitle, actionHandler: actionHandler)
		present($, animated: true, completion: nil)
	}
	
	func presentOKCancelAlert(title: String?, message: String?, okHandler: (() ->())?) {
		let $ = UIAlertController(title: title, message: message, style: .alert,
		                          actionTitle: NSLocalizedString("OK", comment: "Common alert controller OK title"),
		                          actionHandler: okHandler)
		present($, animated: true, completion: nil)
	}
}
