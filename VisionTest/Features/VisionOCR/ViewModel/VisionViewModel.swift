//
//  VisionViewModel.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import Combine
import SwiftUI
import Vision

class VisionViewModel: ObservableObject {
	
	//Google
	@Published var googleOCRResult: OCRResult? = nil
	
	//Apple Vision
	@Published var vpImage: VisionProcessedImage?
	@Published var visionResults: [VisionRecognizedTextResult] = []
	@Published private var imageRequestHandler: VNImageRequestHandler?
	@Published var imageProcessed: Bool = false
	@Published var processTime: String = ""
	@Published var processingProgress: Double = 0
	private var startTime: Date?
	private var processTimeMilliseconds: TimeInterval? {
		didSet {
			if let ms = processTimeMilliseconds {
				if ms > 1000 {
					processTime = "(\(String(format: "%.2f", ms / 1000)) sec)"
				}else {
					processTime = "(\(Int(ms)) ms)"
				}
			}else {
				processTime = ""
			}
		}
	}
	
	//Error Handling
	@Published var errorAlert: Identified<Alert>? = nil
	
	
	private var imageSub: AnyCancellable?
	private var requestSub: AnyCancellable?
	
	
	
	private var completionHandler: VNRequestCompletionHandler?
	private var progressHandler: VNRequestProgressHandler?
	
	init() {}
	
	init(forPreviewProviderWithImage image: UIImage?) {
		if let image = image {
			self.vpImage = .init(id: UUID().uuidString, image: image, processDate: nil)
			process(using: .appleVision, image: vpImage, fast: false)
		}
	}
	
	func reset() { cleanUp() }
	
	private func cleanUp() {
		imageSub?.cancel()
		requestSub?.cancel()
		vpImage?.clear()
		progressHandler = nil
		completionHandler = nil
		processTimeMilliseconds = nil
		processTime = ""
		processingProgress = 0
		startTime = nil
		
		googleOCRResult = nil
		visionResults.removeAll()
		vpImage = nil
		
	}
	
	func process(using recognizer: Recognizer, image: VisionProcessedImage? = nil, fast: Bool = true) {
		switch recognizer {
		case .appleVision: processWithAppleVision(image: image, type: fast ? .fast : .accurate)
		case .googleVision: processWithGoogle()
		}
	}
	
	private func processWithAppleVision(image: VisionProcessedImage? = nil, type: VNRequestTextRecognitionLevel = .fast) {
		cleanUp()
		
		self.vpImage = image ?? VisionProcessedImage(withImageNamed: "RedditOCR", processDate: nil, textDisplayResults: [])
//		self.vpImage = image ?? VisionProcessedImage(withImageNamed: "ExamplePost", processDate: nil, textDisplayResults: [])
//		self.vpImage = image ?? VisionProcessedImage(withImageNamed: "TestText", processDate: nil, textDisplayResults: [])
		
		imageSub = $vpImage
			.receive(on: DispatchQueue.main)
			.removeDuplicates()
			.compactMap({ $0 })
			.sink(receiveValue: {[weak self] (img) in
				guard let cg = img.uiImage()?.cgImage else {
					self?.errorAlert = Identified(Alert(title: Text("Error"), message: Text("No Image"), dismissButton: .default(Text("Okay"))))
					return
				}
				
				self?.buildRequest(cg)
			})
		
		requestSub = $imageRequestHandler
			.receive(on: DispatchQueue.global(qos: .userInteractive))
			.sink(receiveValue: {[weak self] (requestHandler) in
				guard let self = self, let comp = self.completionHandler, let prog = self.progressHandler else { return }
				do {
					let textRequest = VNRecognizeTextRequest(completionHandler: comp)
					textRequest.recognitionLevel = type
					textRequest.usesLanguageCorrection = false
					textRequest.customWords = ["r/", "u/"]
					textRequest.progressHandler = prog
					textRequest.recognitionLanguages = ["en"]
					
//					let textRectsRequest = VNDetectTextRectanglesRequest(completionHandler: comp)
//					textRectsRequest.reportCharacterBoxes = true
					
					
					self.startTime = Date()
//					try requestHandler?.perform([textRequest, textRectsRequest])
					try requestHandler?.perform([textRequest])
				}catch {
					print(error)
					self.errorAlert = Identified(Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("Okay"))))
				}
			})
	}
	
	private func processWithGoogle() {
		if vpImage == nil { vpImage = VisionProcessedImage(withImageNamed: "ExamplePost") }
		guard let name = vpImage?.imageName, let img = UIImage(named: name) else { return }
		
		cleanUp()
		
		let googleMLTester = GoogleMLTester(image: img)
		
		requestSub = googleMLTester.beginProcessing()
			.receive(on: DispatchQueue.main)
			.sink(receiveCompletion: {[weak self] (completion) in
				guard let self = self else { return }
				switch completion {
				case .failure(let error):
					self.errorAlert = Identified(Alert(title: Text("Error"), message: Text(error.stringDescription), dismissButton: .default(Text("Okay"))))
				case .finished: break
				}
			}, receiveValue: {[weak self] (val) in
//				print(val)
				self?.imageProcessed = true
				self?.googleOCRResult = val
				self?.processingProgress = 1
				self?.processTimeMilliseconds = val.processingTime
			})
		
	}
	
	static private func getRectForWord(inTextObservation observation: VNTextObservation) -> CGRect {
		guard let boxes = observation.characterBoxes else {
			return .zero
		}
		
		var maxX: CGFloat = 9999.0
		var minX: CGFloat = 0.0
		var maxY: CGFloat = 9999.0
		var minY: CGFloat = 0.0
		
		for char in boxes {
			if char.bottomLeft.x < maxX {
				maxX = char.bottomLeft.x
			}
			if char.bottomRight.x > minX {
				minX = char.bottomRight.x
			}
			if char.bottomRight.y < maxY {
				maxY = char.bottomRight.y
			}
			if char.topRight.y > minY {
				minY = char.topRight.y
			}
		}
		
		return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
		
//			let xCord = maxX * imageView.frame.size.width
//			let yCord = (1 - minY) * imageView.frame.size.height
//			let width = (minX - maxX) * imageView.frame.size.width
//			let height = (minY - maxY) * imageView.frame.size.height
	}
	
	static func getRectsForChars(inTextObservation observation: VNTextObservation) -> [CGRect] {
		guard let boxes = observation.characterBoxes else {
			return []
		}
		
		return boxes.map({ $0.boundingBox })
		
	}
	
	typealias SubElement = VisionRecognizedTextResult.SubElement
	@Published private var textResults: [VNRecognizedTextObservation]? = nil
	@Published private var rectResults: [VNTextObservation]? = nil
	@Published var wordGroups: [(word: CGRect, letters: [CGRect])]? = nil
	
	private var visionSub: AnyCancellable?
	
	private func buildRequest(_ cgImage: CGImage) {
		visionSub = Publishers.CombineLatest($textResults, $rectResults)
			.receive(on: DispatchQueue.global(qos: .userInitiated))
			.compactMap({ output -> ([VNRecognizedTextObservation], [VNTextObservation])? in
				if let text = output.0, let rect = output.1 {
					return (text, rect)
				}
				return nil
			})
			.sink(receiveValue: {[weak self] (textResults, rectResults) in
				guard let self = self, let image = self.vpImage else { return }
				
				
				//	print("Results: \(results)")
				var wordRects: [(word: CGRect, letters: [CGRect])] = []
				rectResults.forEach({ obs in
					let word = obs.boundingBox//Self.getRectForWord(inTextObservation: obs)
					let chars = Self.getRectsForChars(inTextObservation: obs)//.filter({ word.contains($0) })
					wordRects.append((word, chars))
				})
				DispatchQueue.main.async {
					self.wordGroups = wordRects
					
				}
				
				// print("Word rects: \(wordRects)")
				
				var textDisplayResults: [VisionRecognizedTextResult] = []
				textResults.indices.forEach({ obsIdx in
					let obs = textResults[obsIdx]
//					var subs: Set<SubElement> = []
//					if let candidate: VNRecognizedText = obs.topCandidates(1).first {
//						wordRects.indices.forEach({ rectIdx in
//							let rect = wordRects[rectIdx]
//							let subID = "\(candidate.string)-\(obsIdx)-\(rectIdx)"
//							var letters: [SubElement] = []
//							if obs.boundingBox.contains(rect.word) {
//								for idx in rect.letters.indices {
//									let charRect = rect.letters[idx]
//									if rect.word.contains(charRect) {
//										var str = candidate.string
//										let strIdx = String.Index(utf16Offset: idx, in: str)
//										if str.indices.contains(strIdx) {
//											str = String(str[strIdx])
//											letters.append(SubElement(id: "\(idx)",imageID: image.id, parentID: obs.uuid.uuidString, string: str, boundingBox: charRect, subElements: []))
//										}
//									}
//								}
//								if !subs.map({$0.id}).contains(subID), rect.word.width >= 0, rect.word.height > 0 {
//									let subElement = SubElement(id: subID, imageID: image.id, parentID: obs.uuid.uuidString, string: candidate.string, boundingBox: rect.word, subElements: letters)
//									subs.insert(subElement)
//								}
//							}
//							else {
//								var otherLetters: [SubElement] = []
//								for idx in rect.letters.indices.filter({ !letters.map({$0.id}).contains("\($0)") }) {
//									let charRect = rect.letters[idx]
//									if rect.word.contains(charRect) {
//										var str = candidate.string
//										let strIdx = String.Index(utf16Offset: idx, in: str)
//										if str.indices.contains(strIdx) {
//											str = String(str[strIdx])
//											otherLetters.append(SubElement(id: subID,imageID: image.id, parentID: obs.uuid.uuidString, string: str, boundingBox: charRect, subElements: []))
//										}
//									}
//								}
//								if var sub = subs.first(where: { $0.id == candidate.string }) {
//									sub.subElements.append(contentsOf: otherLetters)
//								}else {
//									subs.insert(SubElement(id: subID, imageID: image.id, parentID: obs.uuid.uuidString, string: candidate.string, boundingBox: rect.word, subElements: otherLetters))
//								}
//							}
//						})
						textDisplayResults.append(
							VisionRecognizedTextResult(
								imageID: image.id,
								observation: obs,
								subElements: [])
						)
//					}
				})
				DispatchQueue.main.async { [weak self] in
//					print(textDisplayResults.map({($0.string, $0.subElements.map({$0.string}))}))
					self?.imageProcessed = true
					self?.processingProgress = 1
					self?.vpImage?.updateResults(
					processedOn: Date(),
					textDisplayResults: textDisplayResults)
				}
			})
		
		completionHandler = {[weak self] (request, error) in
			guard let self = self else { return }
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
					self.errorAlert = Identified(Alert(title: Text("Error"), message: Text(error.localizedDescription), dismissButton: .default(Text("Okay"))))
				}
				if self.vpImage != nil {
					if let results = request.results {
						let textResults = results.compactMap({ $0 as? VNRecognizedTextObservation })
						let rectResults = results.compactMap({ $0 as? VNTextObservation })
						
						if !textResults.isEmpty {
							self.textResults = textResults
						}
//						if !rectResults.isEmpty {
							self.rectResults = rectResults
//						}
					}
				}
			}
		}
		progressHandler = {[weak self] request, progress, error in
			DispatchQueue.main.async {
				if let error = error {
					print("\n\n----\nERROR\n\(error.localizedDescription)\n----\n\n")
				}
				self?.processingProgress = progress
				
				self?.imageProcessed = progress == 1
				if let start = self?.startTime {
					self?.processTimeMilliseconds = Date().timeIntervalSince(start) * 1000
				}
			}
		}
		
		imageRequestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
	}
	
}
