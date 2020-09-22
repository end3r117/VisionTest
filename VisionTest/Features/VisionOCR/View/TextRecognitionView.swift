//
//  TextRecognitionView.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import SwiftUI

//DEV
enum Recognizer: String, CaseIterable, Identifiable {
	var id: String { rawValue }
	
	case appleVision = "Apple Vision", googleVision = "Google OCR"
}

struct TextRecognitionView: View {
	@StateObject var model = VisionViewModel()
//	@StateObject var textProcessor = TextElementsProcessor()
	@State private var selectedFramework: Recognizer = .appleVision
//	@State private var words: [OCRFrame] = []
	@State private var fast: Bool = false
	@State private var count: Int = 0
	
	@State private var startLocation: CGPoint? = nil
	@GestureState var dragLocation: CGPoint = .zero
	
	@State private var highlightedWords: [VisionRecognizedTextResult.ID: (CGFloat, CGFloat)] = [:]
	@State private var highlightedWordsActual: [VisionRecognizedTextResult.SubElement] = []
	
	var body: some View {
		VStack {
			Text("Status: ")
				.font(.footnote)
				.foregroundColor(Color.secondary.opacity(0.5)) +
				Text("\(model.vpImage == nil ? "No Image" : model.imageProcessed ? "Done \(model.processTime)" : "Processing (\(Int(model.processingProgress * 100))%)")")
				.foregroundColor(model.imageProcessed ? Color.blue.opacity(0.5) : .secondary)
				.font(.footnote)
//			if !model.imageProcessed && selectedFramework != .googleVision && model.vpImage != nil {
				ProgressView(value: model.processingProgress, total: 1)
//			}
			Spacer()
			Group {
				Text("Drag Location: \(dragLocation.DEBUG_string)")
				Text("Count: \(count)")
			}
			image?
				.resizable()
				.scaledToFit()
				.anchorPreference(key: AnchorPreferenceKey<String>.self, value: .bounds) { [model.vpImage!.id: $0] }
				.coordinateSpace(name: CoordinateSpace.named("Image"))
				.border(Color.orange, width: 2)
				.overlayPreferenceValue(AnchorPreferenceKey<String>.self) { value in
					GeometryReader { geo in
						overlayResultViews(usingPreferenceValue: value, geometryProxy: geo)
					}
				}
//				.overlay(
//					ZStack {
//						if let results = model.vpImage?.textDisplayResults {
//							ForEach(results.indices, id: \.self) { idx in
//								ElementView(element: Binding(get: { results[idx] }, set: {_ in}))
//							}
//						}
//					}
//				)
//				.onChange(of: lastLocation) { (result) in
//					print("Last location: \(result)")
//				}
//				.onChange(of: dragLocation) { val in
//					if startLocation == nil, val != .zero {
//						startLocation = val
//					}
//					if val == .zero {
//						endLocation = .zero
//						highlightedWords.removeAll()
//					}
//				}
				.gesture(
//					SimultaneousGesture(
					DragGesture(minimumDistance: 0, coordinateSpace: .named("Image"))
						.updating($dragLocation, body: { (val, state, _) in
							state = val.location
							if startLocation == nil {
								highlightedElements.removeAll()
								highlightedWords.removeAll()
								startLocation = val.location
							}
						})
						.onEnded({ val in
							if startLocation != nil {
								startLocation = nil
							}
						})
//						,
//						TapGesture(count: 2)
//							.onEnded({
//								highlightedElements.removeAll()
//							})
//
//						)
				)
			
			Spacer()
		}
		
//		.onReceive(model.$googleOCRResult) { val in
//			guard let val = val else { return }
//			self.words = val.elements
//			count = val.elements.count
//			print(val.elements)
//		}
		.toolbar {
			ToolbarItem(placement: ToolbarItemPlacement.navigationBarTrailing) {
				Picker(selection: $selectedFramework, label: Text(selectedFramework.rawValue)){
					ForEach(Recognizer.allCases) { rec in
						Text(rec.rawValue)
							.tag(rec)
					}
				}
				.pickerStyle(MenuPickerStyle())
			}
			ToolbarItem(placement: ToolbarItemPlacement.navigationBarLeading) {
				Picker(selection: $fast, label: Text(fast ? "Fast":"Accurate")) {
					Text("Fast")
						.tag(true)
					Text("Accurate")
						.tag(false)
				}
				.disabled(selectedFramework == .googleVision)
				.opacity(selectedFramework == .googleVision ? 0 : 1)
			}
			ToolbarItemGroup(placement: ToolbarItemPlacement.bottomBar) {
				Button("Clear", action: clear)
				Spacer()
				Button {
					if let groups = model.wordGroups, !groups.isEmpty, !(self.imageFrame == .zero) {
						model.vpImage?.incorporateCharacterRects(groups, inImageFrame: imageFrame)
					}
				} label: {
					Text("Characters")
					Image(systemName: "textbox")
						.font(.title)
						.border(Color.secondary, width: 1)
				}
				Button("Process") {
					model.process(using: selectedFramework, fast: fast)
				}
			}
		}
		.padding(.top)
		.navigationBarTitleDisplayMode(.inline)
		.alert(item: $model.errorAlert) { $0.wrappedValue }
	}
	
	func clear() {
		count = 0
//		words.removeAll()
		model.reset()
		highlightedWords.removeAll()
		highlightedWordsActual.removeAll()
		boundingBoxesDict.removeAll()
		highlightedElements.removeAll()
		
	}
	
	var disableClear: Bool {
//		if selectedFramework == .googleVision && words.isEmpty {
//			return true
//		}else
		if selectedFramework == .appleVision && model.visionResults.isEmpty {
			return true
		}else {
			return false
		}
	}
	
	var image: Image? {
		if let uiImage = model.vpImage?.uiImage() {
			return Image(uiImage: uiImage)
		}
		
		return nil
	}
	
	@State private var boundingBoxesDict: [Int:CGRect] = [:]
	@State private var highlightedElements: [Int: VisionRecognizedTextResult.SubElement] = [:]
	
	func createSubElementsForResult(_ element: VisionRecognizedTextResult, in boundingBox: CGRect) {
		DispatchQueue.main.async {
			guard let idx = model.vpImage?.textDisplayResults.firstIndex(of: element) else { return }
			var subElements: [VisionRecognizedTextResult.SubElement] = []
			let split = element.string.split(separator: " ", omittingEmptySubsequences: false).map({ String($0) })
			print(split)
			split.indices.forEach({ index in
				if let storedRect = boundingBoxesDict[idx] {
					print("Stored rect: \(storedRect)")
					if let font = UIFont.init(fitting: element.string, into: storedRect.size, with: [:], options: []) {
						let range = (element.string as NSString).range(of: split[index])
						if var box = boundingRect(forCharacterRange: range, inText: element.string, withFont: font, insideBoundingRect: storedRect) {
							if model.vpImage != nil {
								box = CGRect(x: box.minX + storedRect.minX, y: storedRect.minY, width: box.width, height: box.height)
								print(box)
								//highlightedWords[results[idx].id]![index] =
								let sub = VisionRecognizedTextResult.SubElement(id: "\(index)", imageID: model.vpImage!.id, parentID: element.id, string: split[index], boundingBox: box, subElements: [])
								subElements.append(sub)
							}
						}
					}
				}
			})
			model.vpImage!.updateSubElementsForTextDisplayResult(at: idx, subElements: subElements)
		}
	}
	
	func checkHighlightForResultIndex(_ idx: Int, boundingBox box: CGRect) -> Bool {
		guard let results = model.vpImage?.textDisplayResults, results.indices.contains(idx) else { return false }
		let element = results[idx]
		
//		if element.subElements.isEmpty && box != .zero {
//			createSubElementsForResult(element, in: box)
//		}
		
//		if highlightedElements[idx] != nil { return true }
		let check: Bool = {
		guard let startLocation = self.startLocation else { return false }
		var dictCopy = boundingBoxesDict
		if !dictCopy.keys.contains(idx) {
			dictCopy[idx] = box
			DispatchQueue.main.async {
				boundingBoxesDict[idx] = box
			}
		}
		let rect = dictCopy[idx]!
		if rect.contains(startLocation) {
//			highlightedElements[idx] = element
			return true
		}
		if startLocation.y > dragLocation.y {
			if rect.maxY >= dragLocation.y && rect.maxY <= startLocation.y {
//				highlightedElements[idx] = element
				return true
			}
		}else {
			if dragLocation.y >= rect.minY - 10 {
				if startLocation.y <= rect.minY && rect.contains(dragLocation) {
//					highlightedElements[idx] = element
					return true
				}
				if rect.contains(dragLocation) {
//					highlightedElements[idx] = element
					return true
				}
			}
		}
		
		return false
		}()
		
//		if check {
//			DispatchQueue.main.async {
//				if highlightedWords[element.id] == nil {
//					highlightedWords[element.id] = []
//				}
//				for idx in element.subElements.indices {
////					if element.subElements[idx].boundingBox.minX >= dragLocation.x {
//					if element.subElements[idx].containsPoint(dragLocation) {
//						highlightedWords[element.id]?.append(idx)
//					}
//				}
//			}
//		}
		
		return check
	}
	
	func boundingRect(forCharacterRange range: NSRange, inText text: String, withFont font: UIFont, insideBoundingRect rect: CGRect) -> CGRect? {
		
		let attributedText = NSAttributedString(string: text, attributes: [.font: font])
		
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
	@State private var imageFrame: CGRect = .zero
	func overlayResultViews(usingPreferenceValue value: AnchorPreferenceKey<String>.Value, geometryProxy geo: GeometryProxy) -> some View {
		var imageRect: CGRect = .zero
		var results: [VisionRecognizedTextResult] = []
		
		if let id = model.vpImage?.id, let anchor = value[id] {
			imageRect = geo[anchor]
			if self.imageFrame != imageRect {
				DispatchQueue.main.async {
					self.imageFrame = imageRect
				}
			}
		}
		if let dr = model.vpImage?.textDisplayResults, !dr.isEmpty, imageRect != .zero{//, !dr.indices.allSatisfy({boundingBoxesDict.keys.contains($0)}) {
			results = dr
			results.indices.forEach({ idx in
				let res = results[idx]
				let size = CGSize(width: res.boundingBox.width * imageRect.width, height: res.boundingBox.height * imageRect.height)
				DispatchQueue.main.async {
					boundingBoxesDict[idx] = CGRect(x: res.boundingBox.minX * geo.frame(in: .named("Image")).width, y: (1 - res.boundingBox.maxY) * geo.frame(in: .named("Image")).height, width: size.width, height: size.height)
				}
			})
			count = dr.reduce(into: 0, { (res, next) in
				res += next.string.split(separator: " ").map({String($0)}).count
			})
		}
		//		else if let features = model.googleOCRResult {
		//			words = features.elements
		//			count = words.count
		//
		//		}
		return 	Group {
			if imageRect != .zero {
				ForEach(results.indices, id: \.self) { idx in
					let rect = results[idx].relativeBoundingBox(forImageFrame: imageRect)
					
					ElementView(element: Binding(get: {
						if model.vpImage?.textDisplayResults.indices.contains(idx) ?? false {
							return (model.vpImage?.textDisplayResults[idx])!
						}
						return results[idx]
					}, set: {
						model.vpImage?.updateResult(at: idx, with: $0)
					}), elementSelected: Binding(get: {
						checkHighlightForResultIndex(idx, boundingBox: rect)
					}, set: {_ in}), dragLocation: Binding(get: {
						CGPoint(x: dragLocation.x - rect.minX, y: dragLocation.y - rect.minY)
					}, set: {_ in })
					, selectedRange: $highlightedWords)
					.frame(width: rect.width, height: rect.height)
					.position(x: rect.midX, y: rect.midY)
					.background(
						Group {
							if let (min, max) = highlightedWords[results[idx].id] {
								Color.yellow.opacity(0.5)
									.frame(width: max - min, height: rect.height)
									.position(x: rect.minX + max - ((max - min) / 2), y: rect.midY)
							}
						}
					)
//					.layoutPriority(idx == 0 ? 1 : 0)
				}
			}
		}
	}
//		return VStack {
//			if imageRect != .zero && model.vpImage != nil {
				//, let startLocation = startLocation {
//				switch selectedFramework {
//				case .appleVision:
//				ForEach(results.indices, id: \.self) { idx in
//					let res = results[idx]
//					if let rect = boundingBoxesDict[idx] {
//					let split = res.string.split(separator: " ", omittingEmptySubsequences: false).map({ String($0 == "" ? " " : $0) })
//					let split = res.string.map({ String($0) })
//					let highlighted = checkHighlightForResultIndex(idx, boundingBox: rect)
//					if let font = UIFont.init(fitting: res.string, into: size, with: [:], options: []) {
//						if highlighted {
//						HStack(alignment: .top, spacing: 0.0) {
//								ForEach(split.indices, id: \.self) { index in
//									let range = NSRange(location: index, length: split[index].count)
//									if let wordrect = boundingRect(forCharacterRange: range, inText: res.string, withFont: font, insideBoundingRect: rect) {
//										let show = highlighted
//									Text(split[index])
//										//.allowsTightening(true)
//										.minimumScaleFactor(0.8)
//										.fixedSize()
//										.font(Font(font))
//										.foregroundColor(show  ? .yellow : .clear)
							
//									ElementView(element: Binding(get: {
//										model.vpImage?.textDisplayResults[idx] ?? results[idx]
//									}, set: {
//										model.vpImage?.updateResult(at: idx, with: $0)
//									}), elementSelected: Binding(get: {
//										checkHighlightForResultIndex(idx, boundingBox: rect)
//									}, set: {_ in}), dragLocation: Binding(get: {
//										dragLocation
//									}, set: {_ in }))
//										.background(
//											Rectangle()
//												.background(show  ? .black : Color.clear))
//										.transition(.opacity)
//										.animation(.easeIn(duration: 0.1))
//								}
//							}
//					.frame(width: rect.width, height: rect.height)
//					.position(x: rect.midX, y: rect.midY)
//					}
//				}
//			}
//		}
}

struct TextRecognitionView_Previews: PreviewProvider {
	static var previews: some View {
		TextRecognitionView()
	}
}
