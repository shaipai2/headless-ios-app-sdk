//
//  CCaaSChat.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/6/25.
//

import SwiftUI

struct CCaaSChat: View {
    //@Binding var showChatIcon: Bool
    var messagesManager: CCaaSMessageManager
    var body: some View {
        VStack{
            Button(action: {
                messagesManager.showChatIcon=false
            }) {
                VStack{
                    Text("Tap Here to Chat")
                        .font(.headline)
                    Image("download")
                        .cornerRadius(800)
                }.frame(width: 300, height: 300, alignment: .center)
                    .padding(.horizontal)
                    .padding(.vertical)
            }
                
            
        }
        .padding(.horizontal)
        .padding(.vertical)
    }
}

#Preview {
    CCaaSChat(messagesManager:CCaaSMessageManager())
}
