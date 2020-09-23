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
	
	var highlightRangeInX: (_ word: ElementView.Word, _ min: CGFloat, _ max: CGFloat) -> Void
	var deselectRangeInX: () -> Void
	
	var body: some View {
		Text(word.string)
			.font(Font(font))
			.foregroundColor(.clear)
            .background(word.string == "stress," ? Color.red.opacity(0.2) : Color.clear)
			.frame(minWidth: size.width, maxHeight: size.height)
            .border(Color.purple)
			.onChange(of: dragLocation, perform: { value in
				guard value != .zero else { return }
				let h = word.boundingRect.contains(value)
				word.highlighted = h
				if h {
					highlightRangeInX(word, word.boundingRect.minX, word.boundingRect.maxX)
				}
			})
			.onChange(of: word.selected) { bool in
				if bool {
					deselectRangeInX()
					highlightRangeInX(word, word.boundingRect.minX, word.boundingRect.maxX)
				}else {
					deselectRangeInX()
				}
			}
			.onLongPressGesture {
				word.selected.toggle()
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
