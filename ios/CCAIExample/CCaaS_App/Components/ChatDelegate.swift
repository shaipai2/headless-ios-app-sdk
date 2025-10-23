//
//  ChatDelegate.swift
//  Shipai_Test
//
//  Created by Shailesh Pai on 9/25/25.
//

import Foundation
import CCAIChat

class ChatDelegate: CCAIChatDelegate{
    func handleWebFormRequest(_ webFormRequest: CCAIChat.WebFormRequest) async -> CCAIChat.WebFormResponse?{
        
        guard let serverURL = URL(string: "https://<form server url>/validateRequest") else { return nil }
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "signature": webFormRequest.signature,
            "externalFormId": webFormRequest.externalFormId,
            "smartActionId": String(webFormRequest.smartActionId)
        ]
        
        guard let jsonData = try? JSONEncoder().encode(payload) else { return nil }
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("[AuthController] Invalid response")
                return nil
            }
            
//            let decodedForm = try JSONDecoder().decode(WebFormData.self, from: data)
//            let webFormResponse = CCAIChat.FormPayload(type: "WebForm", data: decodedForm)
            let webFormResponse = try JSONDecoder().decode(WebFormResponse.self, from: data)
            return webFormResponse
        } catch {
            print("[AuthController] Network or decoding error: \(error)")
            return nil
        }
    }
}
