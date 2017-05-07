import Foundation

fileprivate extension NSRegularExpression {
	/// A convenient function that specify range as the full lengh of `in string: String`
	func matches(in string: String, options: NSRegularExpression.MatchingOptions = []) -> [NSTextCheckingResult] {
		let range = NSRange(location: 0, length: (string as NSString).length)
		return matches(in: string, options: options, range: range)
	}
	
	func matchStrings(in string: String, options: NSRegularExpression.MatchingOptions = []) -> [String] {
		return matches(in: string, options: options)
			.map() { (string as NSString).substring(with: $0.range) }
	}
}

/// Serialize iTaiwan csv file from [official website](http://itaiwan.gov.tw/func/hotspotlist.csv)
public class DataSerializer {
	public struct Key {
		static let city = "city"
		static let name = "name"
		static let address = "address"
		static let latitude = "latitude"
		static let longitude = "longitude"
	}
	
	internal static let postCodeRegularExpression = try! NSRegularExpression(pattern: "^(\\d*)(.*)$", options: [])
	
	/// csv title foramtted: `"主管機關","地區","熱點名稱","地址","緯度","經度"`
	public static func serialize(string: String) throws -> [[String : String]] {
		return string
			.components(separatedBy: .newlines)
			.dropFirst()
			.map() {
				let values = $0
					.replacingOccurrences(of: "\"", with: "")
					.components(separatedBy: ",")
				
				let addressInfo: (postCode: String, address: String) = {
					let strings = postCodeRegularExpression.matchStrings(in: values[3])
					return (strings[0], strings[1])
				}()
				
				return [
					Key.city.rawValue: values[1],
					Key.name.rawValue: values[2],
					Key.postCode.rawValue: addressInfo.postCode,
					Key.address.rawValue: addressInfo.address,
					Key.latitude.rawValue: values[4],
					Key.longitude.rawValue: values[5],
				]
		}
	}
}
