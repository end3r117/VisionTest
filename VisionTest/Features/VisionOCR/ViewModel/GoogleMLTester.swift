//
//  GoogleMLTester.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import Combine
import MLKitVision
import MLKitTextRecognition
import Foundation

class GoogleMLTester: ObservableObject {
	enum GMLError: Error {
		case unknown, error(Error)
		
		var stringDescription: String {
			switch self {
			case .error(let error): return error.localizedDescription
			case .unknown: return "Unknown error"
			}
		}
	}
	let image: UIImage
	@Published var processedFeatures: OCRResult? = nil
	
	private let textRecognizer = TextRecognizer.textRecognizer()
		
	init(image: UIImage) {
		self.image = image
	}
	
	func beginProcessing() -> AnyPublisher<OCRResult, GMLError> {
		return Future { [image] (promise) in
			let startTime = Date()
			let vision = VisionImage(image: image)
			vision.orientation = image.imageOrientation
			self.textRecognizer.process(vision) { (features, error) in
				guard let features = features else {
					if let error = error {
						print(error)
						DispatchQueue.main.async {
							promise(.failure(.error(error)))
						}
					}else {
						DispatchQueue.main.async {
							promise(.failure(.unknown))
						}
					}
					return
				}
				
				let elapsed = Date().timeIntervalSince(startTime) * 1000
				DispatchQueue.main.async {
					promise(.success(OCRResult(features: features, timeElapsed: elapsed)))
				}
			}
		}
		.eraseToAnyPublisher()
	}
}

struct OCRResult:Codable, CustomDebugStringConvertible, Equatable {
	static func ==(lhs: OCRResult, rhs: OCRResult) -> Bool {
		return (lhs.text == rhs.text)
	}
	var processingTime: TimeInterval
	var blocks:[OCRFrame]
	var lines:[OCRFrame]
	var elements:[OCRFrame]
	var text:String
	
	var debugDescription: String {
		return text
	}
	
	init(features: Text, timeElapsed: TimeInterval) {
		self.processingTime = timeElapsed
		
		self.blocks = features.blocks.map({ OCRFrame(text: $0.text, frame: $0.frame) })
		self.lines = self.blocks.map({ OCRFrame(text: $0.text, frame: $0.frame) })
		self.elements = self.lines.map({ OCRFrame(text: $0.text, frame: $0.frame) })
		
		self.text = features.text
	}
	
}

struct OCRFrame: Identifiable, Codable {
	var id = UUID()
	
	var text:String
	var frame:CGRect
	var selected:Bool = false
}

