//
//  DragonEggXApp.swift
//  Dragon Egg X
//
//  Multiplatform SwiftUI entry (iOS + macOS). Grok Imagine handles all in-app art.
//

import SwiftUI

@main
struct DragonEggXApp: App {
    @State private var catalog = CatalogService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(catalog)
        }
    }
}
