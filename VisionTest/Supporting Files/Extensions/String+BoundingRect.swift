//
//  String+BoundingRect.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/19/20.
//

import UIKit

extension String {
	func boundingRect(forCharacterRange range: NSRange, withFont font: UIFont, insideBoundingRect rect: CGRect) -> CGRect? {
		
		let attributedText = NSAttributedString(string: self, attributes: [.font: font])
		
		let textStorage = NSTextStorage(attributedString: attributedText)
		let layoutManager = NSLayoutManager()
		
		textStorage.addLayoutManager(layoutManager)
		
		let textContainer = NSTextContainer(size: rect.size)
		textContainer.lineFragmentPadding = 0.0
		
		layoutManager.addTextContainer(textContainer)
		
		var glyphRange = NSRange()
		
		// Convert the range for glyphs.
		layoutManager.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
		
		return layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
	}
}
