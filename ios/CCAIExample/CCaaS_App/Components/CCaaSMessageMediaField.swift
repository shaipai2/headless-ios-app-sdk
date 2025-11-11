//
//  CCaaSMessageMediaField.swift
//  Shipai_Test
//
//  Created by Shailesh Pai on 11/11/25.
//

import SwiftUI
import ExyteChat

struct CCaaSMessageMediaField: View {
    var messagesManager: CCaaSMessageManager
    
    var body: some View {
        ChatView(messages: messagesManager.messages, chatType: .conversation) { draft in
            Task {
                await messagesManager.sendMessage(message: draft)
            }
        } inputViewBuilder: { textBinding, attachments, inputViewState, inputViewStyle, inputViewActionClosure, dismissKeyboardClosure in
            Group {
                    VStack(spacing: 6) {
                        Divider()
                        HStack(spacing: 6) {
                            Button { inputViewActionClosure(.photo) } label: { Image(systemName: "photo") }
                            Button { inputViewActionClosure(.camera) } label: { Image(systemName: "camera") }
                            TextField("Write your message", text: textBinding)
                            Button("Send") { inputViewActionClosure(.send) }
                        }
                        .padding(.horizontal, 20)
                    }
                
            }
        }
        .messageUseMarkdown(true)
        }
}

#Preview {
    CCaaSMessageMediaField(messagesManager:CCaaSMessageManager())
}
