//
//  TitleRow.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/1/25.
//

import SwiftUI
//@MainActor
struct CCaaSTitleRow: View {
    var messagesManager: CCaaSMessageManager
    @Binding var showingConfirmationDialog: Bool
    
    @Binding var showChatIcon: Bool
    
    var imageUrl=URL(string:"https://images.unsplash.com/photo-1552234994-66ba234fd567?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D")
    var name="John Smith"
    var body: some View {
        HStack(spacing: 20){
            AsyncImage(url: imageUrl) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .cornerRadius(50)
            } placeholder: {
                ProgressView()
            }
            VStack(alignment: .leading){
                Text(name)
                    .font(.title).bold()
                Text("Online")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity,alignment: .leading)
            Text("End Chat")
                .font(.caption)
                .foregroundColor(.purple)
                .onTapGesture {
                    showingConfirmationDialog=true
                }
                .alert("Are you sure you want to end the chat?", isPresented: $showingConfirmationDialog){
                    Button("End Chat", role: .destructive) {
                        // Perform delete action
                        print("Ending chat")
                        Task {
                            await messagesManager.endChat()
                            messagesManager.showChatIcon=true
                        }
                    }
                }

                
        }
        .padding()
    }
}

#Preview {
    CCaaSTitleRow(messagesManager:CCaaSMessageManager(),showingConfirmationDialog: .constant(true),showChatIcon: .constant(false))
        .background(Color.indigo.opacity(0.3))
}
