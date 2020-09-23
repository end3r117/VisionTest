//
//  Identified.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import SwiftUI

struct Identified<Value>: Identifiable {
	let id = UUID()
	let wrappedValue: Value
	
	init(_ wrappedValue: @escaping @autoclosure () -> Value) {
		self.wrappedValue = wrappedValue()
	}
}
