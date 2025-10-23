//
//  AuthController.swift
//  App
//
//  Created by Jaesung on 1/23/25.
//

import Foundation
import CCAIKit

class AuthController: CCAIDelegate {

    /// Replace with your server URL
    ///
    /// ### Example
    /// 1. Copy `server/.env.example` to `server/.env` and fill out secret
    /// 2. Run `node ./server/app.js`
    /// If you want to run in the physical device, tunnel the local server using `ssh -R 80:localhost:3000 ssh.localhost.run`
    /// and replace with the tunnel URL. For example, `https://yourname.lhr.life`
    let signingBaseUrl = "http://localhost:3000"

    func ccaiShouldAuthenticate() async -> String? {
        guard let jwt = await requestJWTForEndUser() else { return nil }
        do {
            return try await CCAI.shared.authService?.authenticate(jwt)
        } catch {
            print("[AuthController] Failed to authenticate: \(error)")
            return nil
        }
    }

    func requestJWTForEndUser() async -> String? {
        guard let serverURL = URL(string: "\(signingBaseUrl)/ccai/auth") else { return nil }
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "identifier": "ios_user",
            "email":"abc@gmail.com"
        ]
//        let payload:[String: String] = [:]
        
        guard let jsonData = try? JSONEncoder().encode(payload) else { return nil }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("[AuthController] Invalid response")
                return nil
            }
            
            let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
            return authResponse.token
        } catch {
            print("[AuthController] Network or decoding error: \(error)")
            return nil
        }
    }
}

struct AuthResponse: Decodable {
    let token: String
}
