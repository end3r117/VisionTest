//
//  AppContainerView.swift
//  VisionTest
//
//  Created by Anthony Rosario on 9/15/20.
//

import SwiftUI

struct AppContainerView: View {
	var body: some View {
		NavigationView {
			TextRecognitionView()
		}
		.navigationViewStyle(StackNavigationViewStyle())
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
       AppContainerView()
    }
}
