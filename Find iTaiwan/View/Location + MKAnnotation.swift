import Foundation
import MapKit

extension Location: MKAnnotation {
	public var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(
			latitude: CLLocationDegrees(latitude),
			longitude: CLLocationDegrees(longitude)
		)
	}
	
	public enum NodeType {
		case one, many
		init(count: Int) {
			switch count {
			case 1:
				self = .one
			case (2 ... Int.max):
				self = .many
			default:
				fatalError("This Location model contains illegal node number")
			}
		}
	}
	public var nodeType: NodeType {
		return NodeType(count: nodes!.count)
	}
	
	public var title: String? {
		switch nodeType {
		case .one:
			return (nodes!.allObjects.first! as! Node).name
			
		case .many:
			// TODO: Formatted localization
			return nodes!.allObjects.count.description + " " + NSLocalizedString("routers:", comment: "Annotation title with multiple WiFi")
		}
	}
	
	public var subtitle: String? {
		switch nodeType {
		case .one:
			return (nodes!.allObjects.first! as! Node).address
			
		case .many:
			return nodes!.reduce("") { $0 + (($1 as! Node).name ?? "") }
		}
	}
}
