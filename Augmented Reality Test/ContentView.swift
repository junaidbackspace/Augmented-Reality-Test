//
//  ContentView.swift
//  Augmented Reality Test
//
//  Created by Umer Farooq on 16/10/2024.
//

import SwiftUI
import RealityKit

struct ContentView: View {
    var body: some View {
        ARViewContainer(modelName: "cup_saucer_set") // Replace with your actual model name (without .usdz)
                    .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}



