//
//  VisionProcessedImage.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import UIKit
//import MLKitTextRecognition
import Vision

let ProcessedImageCache = NSCache<NSString, UIImage>()

class VisionProcessedImage: Identifiable, Codable, Equatable {
	typealias SubElementsByResultID = [VisionRecognizedTextResult.ID:[VisionRecognizedTextResult.SubElement]]
	typealias SubElement = VisionRecognizedTextResult.SubElement
	static func == (lhs: VisionProcessedImage, rhs: VisionProcessedImage) -> Bool {
		lhs.id == rhs.id
	}
	
	let id: String
	var processDate: Date?
	var localURI: URL?
	
	private(set) var textDisplayResults: [VisionRecognizedTextResult]
//	private(set) var googleOCRResult: OCRResult?
	
	init(id: String, image: UIImage, processDate: Date?, localURI: URL? = nil, textDisplayResults: [VisionRecognizedTextResult] = []) {
		self.id = id
		ProcessedImageCache.setObject(image, forKey: id as NSString)
		self.localURI = localURI
		self.textDisplayResults = textDisplayResults
	}
	
//	func addSubElementToTextDisplayResult(at index: Int, subElement: VisionRecognizedTextResult.SubElement) {
//		if textDisplayResults.indices.contains(index) {
//			if let idx = textDisplayResults[index].subElements.firstIndex(of: subElement) {
//				textDisplayResults[index].subElements.remove(at: idx)
//			}else {
//				textDisplayResults[index].subElements.append(subElement)
//			}
//		}
//	}
//	
//	func updateSubElementsForTextDisplayResult(at index: Int, subElements: [VisionRecognizedTextResult.SubElement]) {
//		if textDisplayResults.indices.contains(index) {
//			textDisplayResults[index].subElements.append(contentsOf: subElements)
//		}
//	}
	
//	func incorporateCharacterRects(_ groups: [(word: CGRect, letters: [CGRect])], inImageFrame bounds: CGRect) {
//		var unmatchedElements: [VisionRecognizedTextResult] = []
//		textDisplayResults.indices.forEach { idx in
//			let element = textDisplayResults[idx]
//			var matched: Bool = false
//			for group in groups {
//				let word = group.word
//				if element.boundingBox.contains(word) {
//					matched = true
//					print("\n----\n\(element.string)\n----\n\(word): \n\(group.letters.reduce(into: ""){ (result, next) in result.append("\n\(next)") })\n----")
//					let subElements = group.letters.indices.reduce(into: [SubElement]()) { (res, idx) in
//						let letter = group.letters[idx]
//						let stringIdx = String.Index(utf16Offset: idx, in: element.string)
//						let string = String(element.string[stringIdx])
//						res.append(SubElement("\(idx)", imageID: id, parentID: element.id, string: string, boundingBox: letter))
//					}
//					updateSubElementsForTextDisplayResult(at: idx, subElements: subElements)
//				}
//			}
//			if !matched {
//				unmatchedElements.append(element)
//			}
//		}
//		print("Unmatched: \(unmatchedElements.map({$0.string}))")
//		for element in unmatchedElements {
//			print("Creating letters for \(element.string)...")
//			let boundingBox = element.relativeBoundingBox(forImageFrame: bounds)
//			var subElements: [VisionRecognizedTextResult.SubElement] = []
//			let split = element.string.map({ String($0) })
//			print("Element Bounds: \(boundingBox)\n----")
//			split.indices.forEach({ index in
//				if let font = UIFont.init(fitting: split[index], into: CGSize(width: boundingBox.width / CGFloat(split.count), height: boundingBox.height), with: [:], options: []) {
//					let range = NSRange(location: index, length: split[index].count)//(element.string as NSString).range(of: split[index])
//					if var box = element.string.boundingRect(forCharacterRange: range, withFont: font, insideBoundingRect: boundingBox) {
//						box = CGRect(x: box.minX + boundingBox.minX, y: boundingBox.minY, width: box.width, height: boundingBox.height)
//						print(box)
//						let sub = VisionRecognizedTextResult.SubElement(id: "\(index)", imageID: id, parentID: element.id, string: split[index], boundingBox: box, subElements: [])
//						subElements.append(sub)
//					}
//				}
//			})
//			if let idx = textDisplayResults.firstIndex(of: element) {
//				print("Done. Updating element with \(subElements.map({$0.string}))")
//				updateSubElementsForTextDisplayResult(at: idx, subElements: subElements)
//			}
//		}
//	}
	
	func clear() {
		textDisplayResults.removeAll()
	}
	
	func updateResult(at index: Array<VisionRecognizedTextResult>.Index, with element: VisionRecognizedTextResult) {
		guard textDisplayResults.indices.contains(index) else { return }
		textDisplayResults[index] = element
	}
	
	func updateResults(processedOn: Date, textDisplayResults: [VisionRecognizedTextResult]) {
		self.processDate = processedOn
		self.textDisplayResults = textDisplayResults
	}
	
//	func createSubElements(inRect boundingBox: CGRect, completion: @escaping (SubElementsByResultID) -> Void) {
//		guard !textDisplayResults.isEmpty else {
//			completion([:])
//			return
//		}
//		var results: SubElementsByResultID = [:]
//		DispatchQueue.global(qos: .userInitiated).async {[weak self, id] in
//			self?.textDisplayResults.forEach({ element in
//				var subElements: [VisionRecognizedTextResult.SubElement] = []
//				let split = element.string.split(separator: " ", omittingEmptySubsequences: false).map({ String($0) })
//				print("----\nCreate subs\n----\nSplit:\(split)\ninRect: \(boundingBox)")
//				print("Element Bounds: \(element.boundingBox)\n----")
//				split.indices.forEach({ index in
//					if let font = UIFont.init(fitting: element.string, into: boundingBox.size, with: [:], options: []) {
//						let range = (element.string as NSString).range(of: split[index])
//						if var box = element.string.boundingRect(forCharacterRange: range, withFont: font, insideBoundingRect: boundingBox) {
//							box = CGRect(x: box.minX + boundingBox.minX, y: boundingBox.minY, width: box.width, height: box.height)
//							print(box)
//							let sub = VisionRecognizedTextResult.SubElement(id: "\(index)", imageID: id, parentID: element.id, string: split[index], boundingBox: box, subElements: [])
//							subElements.append(sub)
//						}
//					}
//				})
//				results[element.id] = subElements
//			})
//			DispatchQueue.main.async {
//				completion(results)
//			}
//		}
//	}
	
	func uiImage() -> UIImage? {
		if let img = ProcessedImageCache.object(forKey: id as NSString) {
			return img
		}else if let url = localURI, let img = UIImage(contentsOfFile: url.path) {
			return img
		}
		#if DEBUG
		if let name = imageName {
			return UIImage(named: name)
		}
		#endif
		
		return nil
	}
	
	//DEV
	#if DEBUG
	var imageName: String?
	#endif
	
	
	
}
#if DEBUG
extension VisionProcessedImage {
	convenience init?(withImageNamed name: String, processDate: Date? = nil, textDisplayResults: [VisionRecognizedTextResult] = []) {
//		guard
//			let data = UIImage(named: name)?.jpegData(compressionQuality: 0.5),
//			let compressed = UIImage(data: data)
//		else { return nil }
		if let compressed = UIImage(named: name) {
			self.init(id: name, image: compressed, processDate: processDate, textDisplayResults: textDisplayResults)
			self.imageName = name
		}else {
			return nil
		}
	}
}
#endif
//
//extension VisionProcessedImage: Codable {
//init(id: String, imageName: String, textDisplayResults: [VisionTextDisplayResult] = []) {
//	var image: UIImage?
//	if let img = ProcessedImageCache.object(forKey: id as NSString) {
//		image = img
//
//	}else if let img = UIImage(named: imageName){
//		image = img
//	}
//
//	self.init(id: id, image: image, localURI: nil, textDisplayResults: textDisplayResults)
//	self.imageName = imageName
//}
//	enum CodingKeys: String, CodingKey {
//		case id, localURI, textDisplayResults
//	}
//	init(from decoder: Decoder) throws {
//		let container = try decoder.container(keyedBy: CodingKeys.self)
//
//		self.id = try container.decode(String.self, forKey: .id)
//		self.localURI = try container.decodeIfPresent(URL.self, forKey: .localURI)
//		self.textDisplayResults = try container.decode([VisionTextDisplayResult].self, forKey: .textDisplayResults)
//
//
//	}
//	func encode(to encoder: Encoder) throws {
//		var container = encoder.container(keyedBy: CodingKeys.self)
//
//		try container.encode(id, forKey: .id)
//		try container.encodeIfPresent(localURI, forKey: .localURI)
//		try container.encode(textDisplayResults, forKey: .textDisplayResults)
//
//	}
//
//}


