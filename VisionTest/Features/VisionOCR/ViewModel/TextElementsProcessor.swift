//
//  TextElementsProcessor.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/18/20.
//

import Foundation
import SwiftUI

///Unused
class TextElementsProcessor: ObservableObject {
	typealias SubElement = VisionRecognizedTextResult.SubElement
	@Published private(set) var readyToProcess: Bool = true
	@Published var percentProcessed: Double = 0
	@Published var processedWords: [SubElement]? = nil
	@Published var processedCharacters: [SubElement]? = nil
	
	private static let queue = DispatchQueue(label: "text-element-processor-queue", qos: .userInitiated, attributes: [])
	private var elements: [VisionRecognizedTextResult] = []
	private var boundingBoxes: [VisionRecognizedTextResult.ID: CGRect] = [:]
	private var elementsToProcess: Int {
		elements.count
	}
	private var elementsProcessed: Int = 0
	
	func fontForWordID(_ id: SubElement.ID) -> UIFont? {
		guard let boundingBox = boundingBoxes[id], let element = processedWords?.first(where: { $0.id == id }) else { return nil }
		return UIFont.init(fitting: element.string, into: boundingBox.size, with: [:], options: [])
	}
	
	func startProcessingElements(_ elements: [VisionRecognizedTextResult], imageFrame: CGRect) {
		self.readyToProcess = false
		self.elements = elements
		elements.indices.forEach({ idx in
			let element = elements[idx]
			self.boundingBoxes[element.id] = CGRect(x: element.boundingBox.minX * imageFrame.width, y: (1 - element.boundingBox.midY) * imageFrame.height, width: element.boundingBox.width * imageFrame.width, height: element.boundingBox.height * imageFrame.height)
//			TextElementsProcessor.queue.async {
				self.estimateWordBounds(forElement: element) { [weak self] in
					guard let self = self else { return }
					DispatchQueue.main.async {
						self.elementsProcessed += 1
						self.percentProcessed = Double(self.elementsProcessed / self.elementsToProcess) * 100
						if idx == elements.indices.last {
							print("Finished! Got \(self.processedWords?.count ?? 0) words.")
						}
					}
				}
//			}
		})
		
	}
	
	init() {}
	
	private func estimateWordBounds(forElement element: VisionRecognizedTextResult, completion: () -> Void) {
		let boundingBoxes = self.boundingBoxes
		guard boundingBoxes.keys.contains(element.id), let boundingBox = boundingBoxes[element.id] else { return }
		if let font = UIFont.init(fitting: element.string, into: boundingBox.size, with: [:], options: []) {
			let split = element.string.split(separator: " ", omittingEmptySubsequences: false)
			
			var totalWidthUsed: CGFloat = boundingBox.minX
			
			split.forEach({ word in
				guard ![""].contains(word) else {
					let size = NSString(string: " ").size(withAttributes: [.font: font])
					totalWidthUsed += size.width * 2
					return
				}
				
				let wordSize = (String(word) as NSString).size(withAttributes: [.font: font])
				let wordRect = CGRect(x: totalWidthUsed, y: boundingBox.minY, width: wordSize.width, height: wordSize.height)
				let subElement = SubElement(id: UUID().uuidString, imageID: element.imageID, parentID: element.id, string: String(word), boundingBox: wordRect, subElements: [])
				totalWidthUsed += wordSize.width
				
				DispatchQueue.main.async { [weak self] in
					guard let self = self else { return }
					self.boundingBoxes[subElement.id] = wordRect
					if self.processedWords == nil {
						self.processedWords = [subElement]
					}else {
						self.processedWords?.append(subElement)
					}
				}
			})
			completion()
		}
		
	}
	
	func estimateCharacterBounds(forSubElement subElement: SubElement) {
		
	}
}
