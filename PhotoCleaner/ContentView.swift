//
//  ContentView.swift
//  PhotoCleaner
//
//  Created by Алексей Емельянов on 15.08.2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var photoManager = PhotoManager()
    
    var body: some View {
        MainMenuView(photoManager: photoManager)
    }
}

#Preview {
    ContentView()
}
