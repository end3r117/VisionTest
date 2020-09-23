//
//  VisionTextDisplayResult.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import UIKit
import Vision

struct VisionRecognizedTextResult: Identifiable, Codable, Equatable {
	static func == (lhs: VisionRecognizedTextResult, rhs: VisionRecognizedTextResult) -> Bool {
		lhs.id == rhs.id || (lhs.boundingBox == rhs.boundingBox && lhs.imageID == rhs.imageID && lhs.string == rhs.string)
	}
	
	let id: String
	let imageID: String
	let string: String
	
	var selected: Bool = false
	
	//Bounding Box corners
	let topLeft: CGPoint
	let topRight: CGPoint
	let bottomLeft: CGPoint
	let bottomRight: CGPoint
		
	let boundingBox: CGRect
	
//	var subElements: [SubElement] = []
	
//	var subStringsConc: String {
//		subElements.map({ $0.string }).joined()
//	}
	
	init(imageID: String, observation: VNRecognizedTextObservation) {//, subElements: [SubElement]) {
		let candidate: VNRecognizedText = observation.topCandidates(1)[0]
		
		self.id = observation.uuid.uuidString
		self.imageID = imageID
		
		self.string = candidate.string

		self.bottomLeft = observation.bottomLeft
		self.bottomRight = observation.bottomRight
		self.topRight = observation.topRight
		self.topLeft = observation.topLeft
		
//		if let first = subElements.first, first.string == candidate.string {
//			self.subElements = first.subElements
//
//		}else {
//			self.subElements = subElements
//		}
		
		let rect = CGRect(x: topLeft.x, y: topLeft.y, width: topRight.x - bottomLeft.x, height: bottomRight.y - topLeft.y)
		
//		if rect.height > 0 && rect.width > 0 {
			self.boundingBox = rect
//		}
//		else {
//			let minX = self.subElements.reduce(into: CGFloat(0), { $0 = min($0, $1.boundingBox.minX)})
//			let minY = self.subElements.reduce(into: CGFloat(0), { $0 = min($0, $1.boundingBox.minY)})
//
//			let maxX = self.subElements.reduce(into: CGFloat(0), { $0 = min($0, $1.boundingBox.maxX)})
//			let maxY = self.subElements.reduce(into: CGFloat(0), { $0 = min($0, $1.boundingBox.maxY)})
//
//			let r = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
//			self.boundingBox = r
//			bottomLeft = CGPoint(x: r.minX, y: maxY)
//			bottomRight = CGPoint(x: r.maxX, y: maxY)
//			topLeft = CGPoint(x: r.minX, y: minY)
//			topRight = CGPoint(x: r.maxX, y: minY)
//		}
		
//		self.bottomLeft = bottomLeft; self.bottomRight = bottomRight; self.topLeft = topLeft; self.topRight = topRight
	}
	
	///Not sure if correct
	func relativeBoundingBox(forImageFrame frame: CGRect) -> CGRect {
		let r = CGRect(x: (topLeft.x * frame.width) + frame.minX, y: ((1 - topLeft.y) * frame.height) + frame.minY, width: boundingBox.width * frame.width, height: boundingBox.height * frame.height)
//		print("Relative bounding box: \(r)")
		return r
	}
	
	func containsPoint(_ point: CGPoint, imageFrame: CGRect) -> Bool {
		let rect = relativeBoundingBox(forImageFrame: imageFrame)
		
		return rect.contains(point)
	}
	
}
///Unused, for now
extension VisionRecognizedTextResult {
	struct SubElement: Identifiable, Codable, Equatable, Hashable {
		func hash(into hasher: inout Hasher) {
			hasher.combine(id)
			hasher.combine(string)
		}
		static func == (lhs: VisionRecognizedTextResult.SubElement, rhs: VisionRecognizedTextResult.SubElement) -> Bool {
			lhs.id == rhs.id
		}
		
		let id: String
		let imageID: VisionProcessedImage.ID
		let parentID: VisionRecognizedTextResult.ID
		
		let string: String
		let boundingBox: CGRect
		
		var selected: Bool = false
		
		var subElements: [SubElement]
		
		func containsPoint(_ point: CGPoint, inImageRect imageRect: CGRect) -> Bool {
			let rect = getRelativeFrame(forRect: imageRect)
			return rect.contains(point)
		}
		
		func getRelativeFrame(forRect imageRect: CGRect) -> CGRect {
			let size = CGSize(width: boundingBox.width * imageRect.width, height: boundingBox.height * imageRect.height)
			let rect = CGRect(x: boundingBox.minX * imageRect.width, y: (1 - boundingBox.minY) * imageRect.height, width: size.width, height: size.height)
			return rect
		}
	}
}

extension VisionRecognizedTextResult.SubElement {
	init(_ id: String = UUID().uuidString, imageID: VisionProcessedImage.ID, parentID: VisionRecognizedTextResult.ID, string: String, boundingBox: CGRect, selected: Bool = false, subElements: [VisionRecognizedTextResult.SubElement] = []) {
		self.id = id
		self.imageID = imageID
		self.parentID = parentID
		self.string = string
		self.selected = selected
		self.boundingBox = boundingBox
		self.subElements = subElements
	}
}

