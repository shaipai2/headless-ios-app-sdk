//
//  InitController.swift
//  CCAIExample
//
//  Created by Nirob Hasan on 2/5/25.
//

import Foundation
import UIKit
import CCAIKit
import CCAIChat

final class InitController {
    static let shared = InitController()

    private(set) var key: String = ""
    private(set) var urlHost: String = ""

    private init() {
        loadEnvironment()
    }

    private func loadEnvironment() {
        guard let url = Bundle.main.url(forResource: "environment", withExtension: "json") else {
            print("[InitController] Environment file not found")
            showEnvironmentErrorAlert()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                self.key = json["key"] as? String ?? ""
                self.urlHost = json["hostname"] as? String ?? ""
            }
        } catch {
            print("[InitController] Failed to load environment: \(error.localizedDescription)")
            showEnvironmentErrorAlert()
        }
    }

    private func showEnvironmentErrorAlert() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else {
                exit(1)
                return
            }
            
            let alert = UIAlertController(
                title: "Configuration Error",
                message: "Environment configuration file 'environment.json' not found or invalid. Please check your configuration.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                exit(1)
            })
            
            window.rootViewController?.present(alert, animated: true)
        }
    }

    func initializeSDK() {
        let authController = AuthController()
        let chatDelegate = ChatDelegate()
        let options = InitOptions(key: key, urlHost: urlHost, delegate: authController, cacheAuthToken: false)
        let chatOptions:CCAIChat.ChatOptions = ChatOptions(delegate: chatDelegate)
        do {
            try CCAI.shared.initialize(options: options)
            CCAI.shared.initializeChat(chatOptions)
            print("[InitController] CCAI initialized successfully")
        } catch {
            print("[InitController] Failed to initialize CCAI: \(error.localizedDescription)")
        }
    }
    
}
