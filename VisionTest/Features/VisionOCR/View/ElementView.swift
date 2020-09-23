//
//  ElementView.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/19/20.
//

import SwiftUI

///UNUSED
struct DragResult: Equatable {
	let start: CGPoint
	let end: CGPoint
	
	static let zero: DragResult = .init(start: .zero, end: .zero)
	
	init(start: CGPoint, end: CGPoint) {
		self.start = start
		self.end = end
	}
	
	init(_ s: CGPoint, _ e: CGPoint) {
		self.start = s
		self.end = e
	}
	
}

extension CGPoint {
	var DEBUG_string: String {
		"(x:\(String(format: "%.2f", x)), y: \(String(format: "%.2f", y)))"
	}
}

extension ElementView {
	struct Word: Hashable, Equatable {
		func hash(into hasher: inout Hasher) {
			hasher.combine(string)
			hasher.combine(elementID)
		}
		
		let string: String
		let elementID: VisionRecognizedTextResult.ID
		let boundingRect: CGRect
		var highlighted: Bool = false
		var selected: Bool = false
		let font: UIFont
		let estimatedCharWidth: CGFloat
	}
	
	
	class ElementViewModel: Identifiable, ObservableObject {
		let id: String
		
		@Published var words: [Word] = []
		private var wordBoundaries: [Int] = []
		private var wordRanges: [Range<String.Index>] = []
		
		init() {
			self.id = UUID().uuidString
			print("EVM - INIT - \(self.id.prefix(4))")
		}
		
		deinit {
			print("EVM - deinit - words: \(words.count)")
		}
		
		//TODO: Rects are not correct. Fix or toss function.
		///Needs fix
		func createWords(from element: VisionRecognizedTextResult, inRect rect: CGRect) {
			print(element.string)
			let trimmed = String(element.string).filter({ !" \n\t\r".contains($0) })
			if wordBoundaries.isEmpty, rect != .zero {
				let diff = trimmed.difference(from: element.string)
				wordBoundaries = diff.removals.reduce(into: [Int]()) { (res, change) in
					switch change {
					case .remove(let offset, _, _):
						res.append(offset)
					case .insert(let offset, _, _):
						print("Insert: \(offset)")
					}
				}
				
				if wordRanges.isEmpty {
					wordRanges = {
						var ranges: [Range<String.Index>] = []
						for i in wordBoundaries.indices {
							let start = element.string.startIndex
							if i == 0 {
								let rangeStart = start
								let rangeEnd = element.string.index(start, offsetBy: wordBoundaries[i])
								if rangeEnd > rangeStart {
									ranges.append(rangeStart..<rangeEnd)
								}else {
									print("range error")
								}
							}else {
								//TODO: Incomplete implementation - need to figure out best estimate for spacing for punctuation, if possible. Slash this is not a good approach.
								if i == wordBoundaries.indices.last {
									let rangeStart = element.string.index(start, offsetBy: wordBoundaries[i - 1] + 1)
									let rangeEnd = element.string.index(start, offsetBy: wordBoundaries[i])
									if rangeEnd > rangeStart {
										ranges.append(rangeStart..<rangeEnd)
									}else {
										print("range error")
									}
									let finalRangeStart = element.string.index(start, offsetBy: wordBoundaries[i] + 1)
									if finalRangeStart < element.string.endIndex {
										ranges.append(finalRangeStart..<element.string.endIndex)
									}else {
										print("range error")
									}
								}else {
									let rangeStart = element.string.index(start, offsetBy: wordBoundaries[i - 1] + 1)
									let rangeEnd = element.string.index(start, offsetBy: wordBoundaries[i])
									if rangeEnd > rangeStart {
										ranges.append(rangeStart..<rangeEnd)
									}else {
										print("range error")
									}
								}
							}
						}
						let increment = rect.width / CGFloat(element.string.count)
						if ranges.count != 0 {
							for idx in ranges.indices {
								let range = ranges[idx]
								
								let str = element.string[range]
								let nsRng = NSRange(range, in: element.string)
								if let font = UIFont.init(fitting: element.string, into: rect.size, with: [:], options: []) {

									if var bound = String(str).boundingRect(forCharacterRange: nsRng, withFont: font, insideBoundingRect: rect) {
//										if !(bound.width > 0.0) {
										bound = CGRect(origin: CGPoint(x: idx == 0 ? rect.minX : bound.origin.x + (increment / 1), y: bound.origin.y), size: CGSize(width: max(CGFloat(nsRng.length + (nsRng.length > 3 ? 1 : 0)) * increment, bound.width), height: bound.height))
//											bound = CGRect(origin: bound.origin, size: CGSize(width: imgRect.width / CGFloat(nsRng.length), height: bound.height))
//										}
										print("Word,Rect=", str, bound, "\nFont: \(font.pointSize)")
										words.append(Word(string: String(str), elementID: element.id, boundingRect: bound, font: font, estimatedCharWidth: increment))
									}
								}
							}
						}else {
							if let font = UIFont.init(fitting: element.string, into: rect.size, with: [:], options: []) {
								
									print("Word, Rect=", element.string, rect, "\nFont: \(font.pointSize)")
								if let index = words.firstIndex(where: { $0.elementID == element.id }) {
									words.remove(at: index)
								}
								words.append(Word(string: element.string, elementID: element.id, boundingRect: rect, font: font, estimatedCharWidth: increment))
								
							}
						}
						return ranges
					}()
				}
			}
		}
	}
	
}

struct ElementView: View {
	
	typealias SubElement = VisionRecognizedTextResult.SubElement
	
	@Binding var element: VisionRecognizedTextResult
	///Unused
	@Binding var elementSelected: Bool
	
	@StateObject private var model = ElementViewModel()
	///Unused
	@State private var subElements: [SubElement] = []
	///Unused
	@State private var boundingBoxesDict: [Int: CGRect] = [:]
	
	@State private var startLocation: CGPoint? = nil
	@State private var lastLocation: DragResult = .zero
	@Binding var dragLocation: CGPoint
	
	@Binding var selectedRange: [VisionRecognizedTextResult.ID: (Word, CGFloat, CGFloat)]
		
	var body: some View {
		Rectangle()
			.fill(Color.blue.opacity(0.005))
			.anchorPreference(key: AnchorPreferenceKey<String>.self, value: .bounds) { [element.id:$0] }
			.overlayPreferenceValue(AnchorPreferenceKey<String>.self) { value in
				GeometryReader { proxy in
					overlayWordViewsUsingPreferenceValue(value, geo: proxy)
				}
			}
//			.onChange(of: model.words) { value in
//				print("--------\nWords!\n\(value.map({$0.string}))\n\(value.map({$0.boundingRect}))\n--------")
//			}
//			.onChange(of: element.subElements) { val in
//				self.subElements = val
//			}
//			.gesture(
//				DragGesture(minimumDistance: 0)
//					.updating($dragLocation, body: { (val, state, _) in
//						state = val.location
//						if startLocation == nil {
//							DispatchQueue.main.async {
//								startLocation = val.location
//							}
//						}
//					})
//					.onEnded({ val in
//						if let start = startLocation {
//							lastLocation = .init(start: start, end: val.location)
//							startLocation = nil
//						}
//					})
//			)
//			.overlay(
//				HStack {
//					Text("Subs: \(element.subElements.count)")
//					Text("Drag: \(dragLocation.DEBUG_string))")
//				}
//				.background(Color(.systemBackground))
//				, alignment: .bottom)
//			.frame(width: geo.size.width, height: geo.size.height)
//			.border(Color.red)
	}

		
	func overlayWordViewsUsingPreferenceValue(_ value: AnchorPreferenceKey<String>.Value, geo: GeometryProxy) -> some View {
		var elementBounds: CGRect = .zero
		
		if let anchor = value[element.id] {
			elementBounds = geo[anchor]
			if model.words.isEmpty {
				DispatchQueue.main.async {
					model.createWords(from: element, inRect: elementBounds)
				}
			}
		}
		
		return HStack(alignment: .top, spacing: 0.0) {
			if elementBounds != .zero {
				ForEach(model.words.indices, id: \.self) { idx in
					let word = model.words[idx]
					if let font = UIFont.init(fitting: word.string, into: word.boundingRect.size, with: [:], options: []) {
						WordView(word: $model.words[idx], dragLocation: $dragLocation, font: font, size: word.boundingRect.size, highlightRangeInX: { (word, min, max) in
							///TODO: Temporarily removing highlighted words. Obviously have to save these.
							selectedRange.removeAll()
							selectedRange[element.id] = (word, min, max)
						}, deselectRangeInX: {
							selectedRange[element.id] = nil
						})
					}
				}
			}
		}
		.frame(width: elementBounds.width, height: elementBounds.height)
		.position(x: elementBounds.midX, y: elementBounds.midY)
	}
	
	
	
//	func checkHighlightForSubElementIndex(_ idx: Int, boundingBox box: CGRect) -> Bool {
//		guard subElements.indices.contains(idx), let startLocation = self.startLocation else { return false }
//
//		let check: Bool = {
//			var dictCopy = boundingBoxesDict
//			if !dictCopy.keys.contains(idx) {
//				dictCopy[idx] = box
//				DispatchQueue.main.async {
//					boundingBoxesDict[idx] = box
//				}
//			}
//			let rect = dictCopy[idx]!
//			if rect.contains(startLocation) {
//				//highlightedElements[idx] = element
//				return true
//			}
//			if startLocation.y > dragLocation.y {
//				if rect.maxY >= dragLocation.y && rect.maxY <= startLocation.y {
//					//highlightedElements[idx] = element
//					return true
//				}
//			}else {
//				if dragLocation.y >= rect.minY - 10 {
//					if startLocation.y <= rect.minY {
//						//highlightedElements[idx] = element
//						return true
//					}
//					if rect.contains(dragLocation) {
//						//highlightedElements[idx] = element
//						return true
//					}
//				}
//			}
//			return false
//		}()
//		return check
//	}
    
}

#if DEBUG
//struct ElementPreview: View {
//	@ObservedObject var visionVM: VisionViewModel
//	@State private var element: VisionRecognizedTextResult? = nil
//
//	var body: some View {
//		VStack {
//			if let element = element, let img = visionVM.vpImage?.uiImage() {
//				Image(uiImage: img)
//					.resizable()
//					.scaledToFit()
//					.overlay(
//						GeometryReader { geo in
//							ElementView(
//								element: Binding(get: { element }, set: { self.element = $0 }), elementSelected: .constant(true), dragLocation: .constant(.zero), selectedRange: <#Binding<[VisionRecognizedTextResult.ID : (CGFloat, CGFloat)]>#>)
//						}
//					)
//			}else {
//				Text("No Element Found")
//			}
//		}
//		.onChange(of: visionVM.vpImage?.textDisplayResults){ value in
////			if let idx = value?.firstIndex(where: { !$0.subElements.isEmpty }) {
////				let element = value![idx]
//			self.element = value?.first
////			}
//		}
//	}
//}
//struct ElementView_Previews: PreviewProvider {
//    static var previews: some View {
//		ElementPreview(visionVM: visionVM)
//    }
//}

extension PreviewProvider {
	static var imageNames: [String] { ["TestText", "ExamplePost"] }
	static var visionVM: VisionViewModel { VisionViewModel(forPreviewProviderWithImage: UIImage(named: imageNames[0])) }
}
#endif
