//
//  SwiftUIView.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/1/25.
//

import SwiftUI
import CCAIChat

//Main View
struct CCaaSChatView: View {
    @ObservedObject var messagesManager=CCaaSMessageManager()
    
    @State var showingConfirmationDialog = false
    
    @State var showChatIcon: Bool  = true
    
    @State var formTapped: Bool  = false
    
    var body: some View {
        //Start the view with Chat Icon
        if messagesManager.showChatIcon == true {
            VStack{
                CCaaSChat(messagesManager: messagesManager)
            }
        }
        //Show loading till an agent joins
        else if messagesManager.waitingForAgent == true &&  messagesManager.showChatIcon == false {
            VStack{
                LoadingView()
            }.task {
                await messagesManager.startChat(menuId: 26)
                print("App_Log: after startChat \(messagesManager.showChatIcon)")
            }
            }
        // When customer taps on the Form image
        else if formTapped{
            VStack{
                DisplayForm(messagesManager: messagesManager,formTapped: $formTapped)
            }.onAppear {
                print("App_Log: Displaying Form")
            }
        }
        else {
            VStack {
                VStack{
                    CCaaSTitleRow(messagesManager: messagesManager,showingConfirmationDialog: $showingConfirmationDialog,
                    showChatIcon: $showChatIcon)
                        .background(Color.indigo.opacity(0.2))
                    ScrollViewReader {proxy in
                        ScrollView{
                            ForEach(messagesManager.messages,id:\.id){message in
                                CCaaSMessageBubble(message: message ,messagesManager: messagesManager,formTapped:$formTapped)
                            }
                        }
                        .padding(.top,50)
                        .background(Color.white)
                    }
                }
                CCaaSMessageField(messagesManager: messagesManager, ).environmentObject(messagesManager)
            }
            .alert("Would you like to continue chatting?", isPresented: $messagesManager.dimissedState){
                Button("Continue Chat ?") {
                    // Perform the action associated with continuing
                    print("Continuing with the action...")
                    messagesManager.dimissedState = false
                    Task {
                        await messagesManager.resumChat()
                    }
                }
                Button("Cancel", role: .cancel) {
                    // Dismiss the alert, no specific action needed
                    print("Action cancelled.")
                }
            }
        }
    }
}

#Preview {
    CCaaSChatView()
}
