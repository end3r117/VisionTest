//
//  WordView.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/21/20.
//

import SwiftUI

struct WordView: View {
	@Binding var word: ElementView.Word
	@Binding var dragLocation: CGPoint
	
	let font: UIFont
	let size: CGSize
	
	var highlightRangeInX: (_ min: CGFloat, _ max: CGFloat) -> Void
	var deselectRangeInX: () -> Void
	
	var body: some View {
		Text(word.string)
			.font(Font(font))
//			.allowsTightening(true)
//			.minimumScaleFactor(0.8)
			.foregroundColor(.clear)//word.highlighted ? .yellow : .clear)
			.frame(minWidth: size.width, maxHeight: size.height)
//			.position(x: word.boundingRect.midX, y: word.boundingRect.midY)
//			.border(Color.green.opacity(0.3))
			.onChange(of: dragLocation, perform: { value in
				guard value != .zero else { return }
				word.highlighted = word.boundingRect.contains(value)
			})
			.onChange(of: word.highlighted) { bool in
				if bool {
					highlightRangeInX(word.boundingRect.minX, word.boundingRect.maxX)
				}else {
					deselectRangeInX()
				}
			}
			.onLongPressGesture {
				word.highlighted.toggle()
			}
	}
}
struct WordViewPreview: View {
	var body: some View {
		EmptyView()
	}
}

struct WordView_Previews: PreviewProvider {
    static var previews: some View {
        WordViewPreview()
    }
}
