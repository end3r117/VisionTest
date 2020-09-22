//
//  UIFont+.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/17/20.
//

import Foundation
import UIKit

extension UIFont {
	convenience init?(named fontName: String? = nil, fitting text: String, into targetSize: CGSize, with attributes: [NSAttributedString.Key: Any], options: NSStringDrawingOptions) {
		var attributes = attributes
		let fontSize = targetSize.height
		if let fontName = fontName {
			attributes[.font] = UIFont(name: fontName, size: fontSize)
		}else {
			attributes[.font] = UIFont.systemFont(ofSize: fontSize)
		}
		let size = text.boundingRect(with: CGSize(width: .greatestFiniteMagnitude, height: fontSize),
									 options: options,
									 attributes: attributes,
									 context: nil).size

		let heightSize = targetSize.height / (ceil(size.height) / fontSize) + 1
		let widthSize = targetSize.width / (ceil(size.width) / fontSize) + 1
		
		if let fn = fontName {
			self.init(name: fn, size: max(heightSize, widthSize))
		}else {
			let font = UIFont.systemFont(ofSize: max(heightSize, widthSize))
			self.init(name: font.fontName, size: font.pointSize)
		}
	}
}
