//
//  MessageBubble.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/1/25.
//

import SwiftUI
import ExyteChat
import CCAIChat

struct CCaaSMessageBubble: View {
    var message: Message
//    var formDetailsList:[FormDetails]
    var messagesManager: CCaaSMessageManager
        
    @Binding var formTapped: Bool
    
    
    var body: some View {
        VStack(alignment:  message.user.id.starts(with: "end_user") ? .leading: .trailing){
            HStack{
                if (message.text != ""){
                    Text(.init(message.text))
                        .padding()
                        .background( message.user.id.starts(with: "end_user") ? Color.blue: Color.gray)
                        .cornerRadius(30)
                        .onAppear(){
                            formTapped=false
                        }
                    
                }else{
//                    if var foundObject = messagesManager.formDetailsList.first(where: { $0.id == message.id }) {
                    if var currentFormDetails = messagesManager.currentFormDetails{
                        AsyncImage(url: URL(string: currentFormDetails.formImageUrl)){phase in
                                switch phase {
                                    case .success(let image):
                                        image
                                            .resizable() // 1. Allow the image to be resized.
                                            .scaledToFill() // 2. Scale the image to fill its container.
                                            .frame(width: 150, height: 100) // 3. Set the fixed size of the image container.
                                             //
                                    case .failure:
                                        // Show a placeholder for a failed load
                                        Rectangle()
                                            .fill(Color.red.opacity(0.3))
                                            .frame(width: 150, height: 100)
                                            .overlay(Text("Failed to load"))
                                    case .empty:
                                        // Show a placeholder while loading
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                            .frame(width: 150, height: 100)
                                            .overlay(ProgressView())
                                    @unknown default:
                                        EmptyView()
                                }
                        }
                        .padding()
                        .onTapGesture {
                            if messagesManager.currentFormDetails!.formClicked==false {
                                messagesManager.currentFormDetails!.formClicked = true
                                Task{
                                    await messagesManager.fetchForm(signature: currentFormDetails.formSignature, smartActionId: currentFormDetails.formSmartActionId, externalFormId: currentFormDetails.formExternalId)
                                    formTapped=true
                                }
                            }
                            
                        }
                    }
                }
                    
            }
            .frame(maxWidth:250, alignment: message.user.id.starts(with: "end_user") ? .leading: .trailing)
            .padding(message.user.id.starts(with: "end_user") ? .leading: .trailing)
        }
    }
}

#Preview {
    CCaaSMessageBubble(message: Message(id: "12345", user: User(id:"end_use12",name:"John", avatarURL: nil,type:.other), text: "Hi, Logan Foster. Sorry to hear about the issue you are experiencing. Let’s take a few steps together to determine how to fix it as soon as possible."),messagesManager: CCaaSMessageManager(),formTapped: .constant(false))
}
