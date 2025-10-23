//
//  DisplayForm.swift
//  Shipai_Test
//
//  Created by Shailesh Pai on 9/25/25.
//

import SwiftUI
import CCAIChat
import ExyteChat

struct DisplayForm: View {
    var messagesManager: CCaaSMessageManager
    @State private var formSubmitted = false
    @Binding var formTapped: Bool
    var body: some View {
        VStack {
            if !formSubmitted{
                if let url = URL(string: messagesManager.webFormResponse!.data.uri) {
                    WebFormViewWithCoord(url: url, formSubmitted: $formSubmitted,messageHandlerName: "myHandler")
                }
            }
            if formSubmitted {
                Text("Form submitted!")
                    .padding()
                    .onAppear(){
                        Task{
                                print("App_Log: form submited. Now reporting to CCaaS")
//                                ** Use the server generated formSubmit payload **.
//                                let formCompletePayload = await messagesManager.getFormSubmitSignature(smartActionId: messagesManager.currentFormDetails!.formSmartActionId, status: "success",externalFormId: messagesManager.currentFormDetails!.formExternalId)
//                                print("App_Log: server generated formCompletePayload \(formCompletePayload!)")

//                              ** Creating the payload from with in the App. This is for demonstration purpose only. Use the                                   server generated payload using the code above **
                                
                                let formCompletePayloadGenerator=FormCompletePayloadGenerator()
                                let formCompletePayload2=formCompletePayloadGenerator.generateFormCompletePayload(smartActionId: messagesManager.currentFormDetails!.formSmartActionId)
                                print("App_Log: locally generated formCompletePayload \(formCompletePayload2!)")
                                let message = OutgoingMessageContent.formComplete(payload: formCompletePayload2!)
                                            
                                await messagesManager.sendFormMessage(message)
                        }
                    }
                Spacer()
                Button("Return to chat") {
                    formTapped.toggle()
                }
                .buttonStyle(.borderedProminent)
                .padding()
                
            }
        }
        .onAppear {
            print("App_Log: uri in display form:\(messagesManager.webFormResponse!.data.uri)")
        }
    }
}

#Preview {
    DisplayForm(messagesManager:CCaaSMessageManager(), formTapped: .constant(true))
}
