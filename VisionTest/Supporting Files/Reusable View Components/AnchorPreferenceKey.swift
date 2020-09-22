//
//  AnchorPreferenceKey.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/16/20.
//

import SwiftUI

struct AnchorPreferenceKey<ID>: PreferenceKey where ID : Hashable {
	///Use unique ID per View as dictionary key.
	typealias Value = [ID:Anchor<CGRect>]
	
	static var defaultValue: Value { [:] }
	
	static func reduce(value: inout Value, nextValue: () -> Value) {
		value.merge(nextValue(), uniquingKeysWith: { $1 })
	}
}

