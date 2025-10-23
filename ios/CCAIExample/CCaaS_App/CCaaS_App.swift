//
//  Shaipai_TestApp.swift
//  Shipai_Test
//
//  Created by Shailesh Pai on 9/1/25.
//

import SwiftUI

@main
struct CCaaS_App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init(){
        print("App_Log: In init")
        InitController.shared.initializeSDK()
    }
    var body: some Scene {
        WindowGroup {
            CCaaSChatView()
        }
    }
}
