//
//  MessageField.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/1/25.
//

import SwiftUI
import ExyteChat
struct CCaaSMessageField: View {
    @EnvironmentObject var messagesManager: CCaaSMessageManager
    
    @State private var message=""

    private var msgManager: CCaaSMessageManager
    init(messagesManager: CCaaSMessageManager, message: String = "") {
        msgManager = messagesManager
    }
        
    var body: some View {
        HStack{
            CCaaSTextField(placeHolder: Text("Enter your message here"), text: $message)
            Button {
                let draftMessage=DraftMessage(text: message,medias:[],giphyMedia:nil,recording:nil,replyMessage:nil,createdAt:Date())
                Task {
                    await messagesManager.sendMessage(message: draftMessage)
                }
                message=""
            }
        label: {
            Image(systemName: "paperplane.fill")
                .padding(10)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.vertical)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(50)
        .padding()
    }
}

#Preview {
    CCaaSMessageField(messagesManager:CCaaSMessageManager() ).environmentObject(CCaaSMessageManager())
}

struct CCaaSTextField: View{
    var placeHolder: Text
    @Binding var text: String
    var editingChanged: (Bool) -> Void = { _ in }
    var commit: () -> Void = {}
    
    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                placeHolder
                    .opacity(0.5)
            }
            TextField("",text:$text,onEditingChanged: editingChanged,onCommit: commit)
        }
    }
}
