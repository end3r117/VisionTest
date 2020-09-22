//
//  SubElementView.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import Vision
import SwiftUI

struct SubElementView: View {
	typealias SubElement = VisionRecognizedTextResult.SubElement
	@Binding var subElement: SubElement
	@Binding var currentLocation: CGPoint
	let relativeRect: CGRect
	
	let string: String
	
	init(subElement: Binding<SubElement>, currentLocation: Binding<CGPoint>, boundingBox: CGRect, string: String) {
		self._subElement = subElement
		self._currentLocation = currentLocation
		self.relativeRect = subElement.wrappedValue.getRelativeFrame(forRect: boundingBox)
		self.string = string
	}
	
	var font: Font {
		if let uiFont = UIFont.init(fitting: string, into: relativeRect.size, with: [:], options: []) {
			return Font(uiFont)
		}
		return .body
	}
   
	var body: some View {
		Text(string)
			.font(font)
			.foregroundColor(.white)
			.frame(width: relativeRect.width, height: relativeRect.height)
			.background(
				Color.black.opacity(1)
			)
			.position(x: relativeRect.minX, y: relativeRect.midY)
			.onAppear { print("Sub: \(string), RR: \(relativeRect)") }
			.onChange(of: currentLocation, perform: { value in

				subElement.selected = relativeRect.contains(value)

			})
	}
	
	var highlighted: Bool {
		subElement.selected
	}
	
	
}
//
//struct VisionTextDisplayView_Previews: PreviewProvider {
//    static var previews: some View {
//		SubElementView(textDisplayResult: .constant(VisionTextDisplayResult(imageID: "123", observation: VNRecognizedTextObservation())))
//    }
//}
