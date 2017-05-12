import Foundation

/// Serialize iTaiwan csv file from [official website](http://itaiwan.gov.tw/func/hotspotlist.csv)
public class DataSerializer {
	public struct Key {
		static let city = "city"
		static let name = "name"
		static let address = "address"
		static let latitude = "latitude"
		static let longitude = "longitude"
	}
	
	internal static let postCodeRegularExpression = try! NSRegularExpression(pattern: "^\\d{3|5}", options: [])
	
	// FIXME: This kinda parsing does not conform to CSV format. Implement target: "attribute, with comma", "another"
	/// csv title foramtted: `"主管機關","地區","熱點名稱","地址","緯度","經度"`
	public static func serialize(string: String) throws -> [[String : String]] {
		return string
			.components(separatedBy: "\r\n")
			.dropFirst()
			// TODO: Invest why there's an empty component in the last line. EOF? Should opt for .filter()?
			.dropLast()
			.map() {
				let values = $0
					.replacingOccurrences(of: "\"", with: "")
					.components(separatedBy: ",")
				
				let address: String = {
					let rawString = values[3]
					
					let postCodeAndCityRegularExpression = try! NSRegularExpression(pattern: "^(\\d{3}|\\d{5})" + values[1], options: [])
					return postCodeAndCityRegularExpression.stringByReplacingMatches(in: rawString, options: [], range: rawString.NSRange, withTemplate: "")
				}()
				
				return [
					Key.city: values[1],
					Key.name: values[2],
					Key.address: address,
					Key.latitude: values[4],
					Key.longitude: values[5],
				]
		}
	}
}

// MARK: String helper
internal extension String {
	// MARK: Big 5 Extension
	private struct Big5Encoding {
		static let CoreFoundation = CFStringEncoding(CFStringEncodings.big5_HKSCS_1999.rawValue)
		static let Foundation = CFStringConvertEncodingToNSStringEncoding(CoreFoundation)
	}
	
	init?(big5EData data: Data) {
		if let string = NSString(data: data, encoding: Big5Encoding.Foundation) as String? {
			self.init(string)
		} else {
			return nil
		}
	}
	
	// MARK: NSRange
	var NSRange: Foundation.NSRange {
		return Foundation.NSRange(location: 0, length: (self as NSString).length)
	}
}
