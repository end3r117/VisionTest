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
	
	case appleVision = "Apple Vision"//, googleVision = "Google OCR"
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
	
	@State private var highlightedWords: [VisionRecognizedTextResult.ID: (ElementView.Word, CGFloat, CGFloat)] = [:]
	@State private var selectedWord: ElementView.Word? = nil
	@State private var highlightedWordsActual: [VisionRecognizedTextResult.SubElement] = []
	
	var body: some View {
		VStack {
			Text("Status: ")
				.font(.footnote)
				.foregroundColor(Color.secondary.opacity(0.5)) +
				Text("\(model.vpImage == nil ? "No Image" : model.imageProcessed ? "Done \(model.processTime)" : model.startTime == nil ? "Ready" : "Processing (\(Int(model.processingProgress * 100))%)")")
				.foregroundColor(model.imageProcessed ? Color.blue.opacity(0.5) : .secondary)
				.font(.footnote)
				ProgressView(value: model.processingProgress, total: 1)
			Spacer()
			if selectedWord != nil {
				Text("Selected: \(selectedWord!.string)")
					.font(.headline)
					.frame(height: 44)
			}else {
				Rectangle()
					.fill(Color(.systemBackground))
					.frame(height: 44)
			}
			if let vpImg = model.vpImage {
			image?
				.resizable()
				.scaledToFit()
				.anchorPreference(key: AnchorPreferenceKey<String>.self, value: .bounds) { [vpImg.id: $0] }
				.coordinateSpace(name: CoordinateSpace.named("Image"))
				.overlayPreferenceValue(AnchorPreferenceKey<String>.self) { value in
					GeometryReader { geo in
						overlayResultViews(usingPreferenceValue: value, geometryProxy: geo)
					}
				}
				.transition(.move(edge: .leading))
				.animation(.easeOut)
				.gesture(
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
				)
			Spacer()
		}
		}
		.onChange(of: model.vpImage) { _ in
			clear()
		}
		.onChange(of: highlightedWords.keys) { keys in
			guard selectedWord != nil else { return }
			if !(keys.contains(selectedWord!.elementID)) {
				selectedWord = nil
			}
		}
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
//				.disabled(selectedFramework == .googleVision)
//				.opacity(selectedFramework == .googleVision ? 0 : 1)
			}
			ToolbarItemGroup(placement: ToolbarItemPlacement.bottomBar) {
				Button("Clear", action: clear)
					.disabled(disableClear)
				Spacer()
				Button {
					clear()
					withAnimation {
						model.changePic()
					}
				} label: {
					Text("Next")
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
		selectedWord = nil
		highlightedWords.removeAll()
		highlightedWords = [:]
		highlightedWordsActual.removeAll()
		boundingBoxesDict.removeAll()
		highlightedElements.removeAll()
		
	}
	
	var disableClear: Bool {
		model.vpImage == nil || (count == 0 && selectedWord == nil && model.imageProcessed == false)
	}
	
	var image: Image? {
		if let uiImage = model.vpImage?.uiImage() {
			return Image(uiImage: uiImage)
		}
		
		return nil
	}
	
	@State private var boundingBoxesDict: [Int:CGRect] = [:]
	@State private var highlightedElements: [Int: VisionRecognizedTextResult.SubElement] = [:]
	
	
	func checkHighlightForResultIndex(_ idx: Int, boundingBox box: CGRect) -> Bool {
		guard let results = model.vpImage?.textDisplayResults, results.indices.contains(idx) else { return false }

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
		
		func getSelection(for elementID: VisionRecognizedTextResult.ID) -> (ElementView.Word, CGFloat, CGFloat)? {
			if var (word, min, max) = highlightedWords[elementID] {
				if [",", " "].contains(word.string.first) {
					let second = word.string.index(after: word.string.startIndex)
					if word.string.indices.contains(second) {
						let str = String(word.string[second..<word.string.endIndex])
						word = .init(string: str, elementID: word.elementID, boundingRect: word.boundingRect, font: word.font, estimatedCharWidth: word.estimatedCharWidth)
						min += word.estimatedCharWidth
					}
				}
				if [",", " "].contains(word.string.last) {
					let last = word.string.index(before: word.string.endIndex)
					if word.string.indices.contains(last) {
						let str = String(word.string[word.string.startIndex..<last])
						word = .init(string: str, elementID: word.elementID, boundingRect: word.boundingRect, font: word.font, estimatedCharWidth: word.estimatedCharWidth)
						max -= word.estimatedCharWidth
					}
				}
				
				return (word, min, max)
			}
			
			return nil
		}
		
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
						CGPoint(x: dragLocation.x, y: dragLocation.y)
					}, set: {_ in })
					, selectedRange: $highlightedWords,elemBBox: rect)
					.frame(width: rect.width, height: rect.height)
					.position(x: rect.midX, y: rect.midY)
					.background(
						Group {
							if let (word, min, max) = getSelection(for: results[idx].id) {
								Color.yellow.opacity(0.5)
									.frame(width: max - min, height: rect.height)
									.position(x: rect.minX + max - ((max - min) / 2), y: rect.midY)
									.onAppear {
										selectedWord = word
									}
							}
						}
					)
				}
			}
		}
	}
}

struct TextRecognitionView_Previews: PreviewProvider {
	static var previews: some View {
		TextRecognitionView()
	}
}
