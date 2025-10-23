//
//  Shipai_TestApp.swift
//  Shipai_Test
//
//  Created by Shailesh Pai on 9/1/25.
//

import SwiftUI
import Firebase

@main
struct Shipai_TestApp: App {
    init(){
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
