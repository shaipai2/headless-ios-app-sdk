//
//  CCaaSMessageManager.swift
//  CCAIExample
//
//  Created by Shailesh Pai on 9/3/25.
//

import Foundation
import SwiftUI
import CCAIKit
import CCAIChat
import Combine
import ExyteChat
import CryptoKit


@MainActor
class CCaaSMessageManager: ObservableObject{
    private var cancellables = Set<AnyCancellable>()
    private var participants: [String: User] = [:]
    let service: ChatServiceProtocol?
    
    @Published var errorMessage: String?
    @Published var state: ChatProviderState = .none
    @Published var messages: [Message] = []
    @Published var isTyping = false
    @Published var currentAgent: Agent?
    @Published var chatStatus: ChatStatus?
    @Published var showChatIcon: Bool = true
    @Published var formDetailsList:[FormDetails] = []
    @Published var currentFormDetails:FormDetails?
    @Published var webFormResponse:WebFormResponse?
    @Published var formSubmitSignature:String?
    @Published var dimissedState: Bool = false
    @Published var waitingForAgent: Bool = true
    @Published var currentScreenShareSessionState: ScreenShareServiceState = .none
    @Published var currentRequestNoti: PushNotification?
    
    var pushNotificationService: PushNotificationServiceProtocol?
    var currentScreenShareRequestMessage: ChatMessage?
    var screenShareService : ScreenShareServiceProtocol?
    var currentChatId: Int?
    var screenShareInitiatedFrom: ScreenShareFrom?
    
    init () {
        print("App_Log: in init")
        pushNotificationService = CCAI.shared.serviceLocator?.get(of: PushNotificationServiceProtocol.self)
        service = CCAI.shared.chatService!
        setupSubscriptions(with: self.service!)
    }
    
    // Function to convert JSON string to ExternalChatTranscript object
    private func decodeJSON(ext_chat_transcript:String) -> ExternalChatTranscript?{
        guard let jsonData = ext_chat_transcript.data(using: .utf8) else {
            fatalError("Could not convert string to Data")
        }
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(ExternalChatTranscript.self, from: jsonData)
            return decodedData
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
    
    // Initiate the chat by passing custom data containing external chat transcripts and un-signed meta-data and signed meta-data
    func startChat(menuId: Int) async {
        do {
            waitingForAgent = true
            //Array of ExternalChatTranscript objects
            var externalChatTranscripts : [ExternalChatTranscript] = []
            var jsonString = """
                {
                    "sender":"end_user",
                    "timestamp":"2025-10-02T22:24:37Z",
                    "content":[
                        {
                            "type":"text",
                            "text":"How do I add a plan ?"
                        }
                    ]
                }
            """
            var externalChatTranscript:ExternalChatTranscript=decodeJSON(ext_chat_transcript: jsonString)!
            externalChatTranscripts.append(externalChatTranscript)
            jsonString = """
                {
                    "sender":"agent",
                    "timestamp":"2025-10-02T22:25:37Z",
                    "content":[
                        {
                            "type":"text",
                            "text":"Which plan are you interested in ?"
                        }
                    ]
                }
            """
            
            externalChatTranscript=decodeJSON(ext_chat_transcript: jsonString)!
            externalChatTranscripts.append(externalChatTranscript)
            jsonString = """
                {
                    "sender":"end_user",
                    "timestamp":"2025-10-02T22:26:37Z",
                    "content":[
                        {
                            "type":"media",
                            "media":
                            {
                                "type":"image",
                                "url":"https://www.w3schools.com/w3css/img_avatar3.png"
                            }
                        }
                    ]
                }
            """
            externalChatTranscript=decodeJSON(ext_chat_transcript: jsonString)!
            externalChatTranscripts.append(externalChatTranscript)

            var payload = CustomDataPayload()
            let transfer = ExternalChatTransfer(
                agent: ExternalChatAgent(name: "John Smith", avatar:nil),
                transcript: externalChatTranscripts
            )
            payload.externalChatTransfer = transfer
            
            // Adding meta-data to customData
            payload["app_version"] = CustomDataItem(label: "App Version", value: "3.1.0", type: .string, invisibleToAgent: true)
            payload["app_type"] = CustomDataItem(label: "App Type", value: "iOS", type: .string, invisibleToAgent: false)
            
            // Get signed custom data in a form JWTToken
            let jwtToken = await requestJWTForEndUser()
            let customData = CustomData(signed: jwtToken, unsigned:payload)
            
            //Create the request
            let request = ChatRequest(menuId: menuId,customData: customData)
            
            //Start the chat
            try await service!.start(request: request)
        } catch {
            handleError(error, message: "Failed to start chat", shouldUpdateState: true)
        }
    }
    
    // MARK: - Private Methods
    // Create the subscriptions to listen to events and chat updates
    private func setupSubscriptions(with service: ChatServiceProtocol) {
        setupMessagesSubscription(service)
        setupChatReceivedSubscription(service)
        setupMemberEventSubscription(service)
        setupStateChangeSubscription(service)
        setupTypingEventSubscription(service)
        setupPushNotificationSubscription(with: pushNotificationService!)
    }

    // Subscription to get messages from the agent and events
    private func setupMessagesSubscription(_ service: ChatServiceProtocol) {
        print("App_Log: in setupMessagesSubscription")
        service.messagesReceivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chatMessages in
                self?.handleChatMessages(chatMessages,service: service)
            }
            .store(in: &cancellables)
    }
    
    // Subscription to receive chat updates. Ex - queued, assigned
    private func setupChatReceivedSubscription(_ service: ChatServiceProtocol) {
        print("App_Log: in setupChatReceivedSubscription")
        service.chatReceivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] chat in
                self?.handleChatUpdate(chat)
            }
            .store(in: &cancellables)
    }
    
    // Subscription to receieve member joined and left events for Agent and End-Users
    private func setupMemberEventSubscription(_ service: ChatServiceProtocol) {
        print("App_Log: in setupMemberEventSubscription")
        service.memberEventSubject
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event {
                case .joined(let member):
                    print("Member joined: \(member ?? "Unknown")")
                case .left(let member):
                    print("Member left: \(member ?? "Unknown")")
                    if let member = member, self.participants[member] != nil {
                        self.participants.removeValue(forKey: member)
                    }
                    Task{
                        Task {
                            print("App_Log: member left now cheking status")
                            try? await service.checkStatus()
                        }
                    }
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func setupStateChangeSubscription(_ service: ChatServiceProtocol) {
        print("App_Log: in setupStateChangeSubscription")
        service.stateChangedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
                Task { try? await service.checkStatus() }
            }
            .store(in: &cancellables)
    }

    // Function to handle incoming messages and events. This function is called when an event is detected in setupMessagesSubscription
    private func handleChatMessages(_ chatMessages: [ChatMessage],service:ChatServiceProtocol) {
        print("App_Log: handleChatMessages \(chatMessages)")
        print("=============================")
        var chatEvent:ChatMessageEvent = .none
        self.messages.append(contentsOf: chatMessages.compactMap { message in
            guard let content = message.body.content, !content.isEmpty else {
                print("App_Log: content empty")
                print("App_Log: message \(message.body)")
                print("App_Log: Event: \(message.body.event ?? .none)")
                chatEvent=message.body.event ?? .none
                if message.body.type == CCAIChat.ChatMessageBodyType.form{
                    print("App_Log: this is a form")
                    let signature = message.body.signature!
                    if case let .web(webForm) = message.body.form! {
                        let uuId = UUID().uuidString
                        print("App_Log: webForm :\(webForm)")
                        let formDetails=FormDetails(form: webForm, id:uuId,signature:signature)
                        self.currentFormDetails=formDetails
                        self.formDetailsList.append(formDetails)
                        guard let authorId = message.author else {return nil}
                        let user = userFromMessageAuthorId(authorId)
                        self.messages.append(Message(id: uuId, user: user, text: ""))
                    }
                }
                if (chatEvent ==  .chatDismissed){
                    dimissedState = true
                }
                return nil
            }
            print("App_Log: message \(message.body)")
            print("App_Log: content : \(content)")
            guard let authorId = message.author else { return nil }
            let user = userFromMessageAuthorId(authorId)
            print("App_Log: user name :\(user.name)")
            return Message(id: UUID().uuidString, user: user, text: content)
        })
        if chatEvent == .chatEnded{
            let user = userFromMessageAuthorId("system")
            self.messages.append(Message(id: UUID().uuidString, user: user, text: "Chat Ended"))
            Task {
                    print("App_Log: calling end chat")
                    try? await endChat()
            }
        }
            
    }
    
    private func setupTypingEventSubscription(_ service: ChatServiceProtocol) {
        service.typingEventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleTypingEvent(event)
            }
            .store(in: &cancellables)
    }
    
    // Function to handle incoming chat updated. This function is called when an event is detected in setupChatReceivedSubscription
    private func handleChatUpdate(_ chat: ChatResponse?) {
        print("App_Log: handleChatUpdate \(String(describing: chat))")
        print("App_Log: chatStatus : \(String(describing: chatStatus))")
        currentChatId = chat?.id
        if chatStatus != chat?.status {
            chatStatus = chat?.status
            if (chatStatus == .assigned){
                waitingForAgent=false
            }
        }
        guard let agent = chat?.currentAgent,
              let agentId = agent.agentIdString else {
            return
        }
        print("App_Log: agentId : \(agentId)")
        if currentAgent?.agentIdString != agentId {
            currentAgent = chat?.currentAgent
        }

        if self.participants[agentId] == nil {
            self.participants[agentId] = User(
                id: agentId,
                name: agent.displayName,
                avatarURL: URL(string: agent.avatarUrl ?? ""),
                isCurrentUser: false
            )
        }
    }
    
    // Function to send messages (text, media) from the End-User
    func sendMessage(message: DraftMessage) async {
        var outGoingMessage: OutgoingMessageContent?
        if let photo = message.medias.first,
                  photo.type == .image,
                  let data = await photo.getData(),
                  let img = UIImage(data: data),
                  let jpgData = img.jpegData(compressionQuality: 0.8) {
            outGoingMessage = .images(images: [jpgData], smartAction: nil, contentType: "image/jpeg")
        } else if let video = message.medias.first,
                  video.type == .video,
                  let urlPath = await video.getURL()?.path() {
            outGoingMessage = .videos(videoUrls: [urlPath], smartAction: nil, contentType: "video/mp4")
        } else if !message.text.isEmpty {
            outGoingMessage = .text(content: message.text)
        }
        
        // Create end user if not exists
        let endUserId = "end_user"
        let endUser = participants[endUserId] ?? User(
            id: endUserId,
            name: "You",
            avatarURL: nil,
            isCurrentUser: true
        )
        participants[endUserId] = endUser
        print("App_Log: endUserId : \(endUserId)")
        if let convertedMessage = await outGoingMessage?.convertToDisplayMessageModel(user: endUser, url: message.medias.first?.getURL()) {
            messages.append(convertedMessage)
        }
        if let outGoingMessage = outGoingMessage {
            do {
                try await service!.sendMessage(outGoingMessage)
            } catch {
                handleError(error, message: "Failed to send message", shouldUpdateState: false)
            }
            print("App_Log: message sent")
        }
    }
    
    func sendOutgoingMessage(_ message: OutgoingMessageContent, url: URL?) async {

        // Create end user if not exists
        let endUserId = "end_user"
        let endUser = participants[endUserId] ?? User(
            id: endUserId,
            name: "You",
            avatarURL: nil,
            isCurrentUser: true
        )
        participants[endUserId] = endUser

        guard let messagesToSend = message.convertToDisplayMessageModel(user: endUser, url: url) else {
            return
        }
        messages.append(messagesToSend)
        do {
            try await service?.sendMessage(message)
        } catch {
            handleError(error, message: "Failed to send message")
        }
    }
    
    // Function to send Form submission related events to CCaaS to notify the Agent. Ex - "Form Complete"
    func sendFormMessage(_ outGoingMessage: CCAIChat.OutgoingMessageContent) async{
        print("App_Log: sending form submit message: \(outGoingMessage)")
        do {
            try await service!.sendMessage(outGoingMessage)
            print("App_Log: form submission message sent")
        } catch {
            handleError(error, message: "App_Log: Failed to send message", shouldUpdateState: false)
        }
    }
    
    // Function to validate the Form response received from back-end server. The validation is done at CCaaS by checking the signature sent in the request
    func validateWebForm(_ form: CCAIChat.WebFormResponse) async  {
        print("App_Log: sending form submit event: \(form)")
        do {
            let isFormValid=try await service!.validateWebForm(form)
            print("App_Log: form validation done \(isFormValid)" )
        } catch {
            handleError(error, message: "App_Log: form validation failed", shouldUpdateState: false)
        }
    }
    
   // Getting the signature from the back-end server. This signature is used when sending the form submission event to CCaaS
    func getFormSubmitSignature(smartActionId:Int,status:String,externalFormId:String) async -> FormCompletePayload?{
        guard let serverURL = URL(string: "https://form-server-url/getFormCompleteSignature") else { return nil }
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: String] = [
            "status": status,
            "smartActionId": String(smartActionId),
            "externalFormId":externalFormId
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
            
            let formCompletePayload = try JSONDecoder().decode(FormCompletePayload.self, from: data)
            
            print("App_Log: returned signature: \(formCompletePayload)")
            return formCompletePayload
        } catch {
            print("[AuthController] Network or decoding error: \(error)")
            return nil
        }

    }
    
    private func handleTypingEvent(_ event: TypingEvent) {
        switch event {
        case .started:
            isTyping = true
        case .ended:
            isTyping = false
        @unknown default:
            print(#function, "unknown event:", event)
        }
    }
    
    private func userFromMessageAuthorId(_ id: String) -> User {
        if let user = participants[id] {
            return user
        } else {
            let isEndUser = id.starts(with: "end_user")
            let name = isEndUser ? "You" : "System"
            let type = isEndUser ? UserType.current : UserType.system

            let user = User(id: id,
                            name: name,
                            avatarURL: nil,
                            type: type)
            participants[id] = user

            return user
        }
    }
    //Always call this function when ending the chat, both from client side and from the Agent side.
    func endChat() async {
        do {
            try await service!.endChat()
            cleanupChat()
        } catch {
            handleError(error, message: "Failed to end chat", shouldUpdateState: true)
        }
    }
    
    // Resetting of variables
    private func cleanupChat() {
        print("App_Log: in cleanupChat()")
        isTyping = false
        waitingForAgent = true
        messages=[]
        showChatIcon=true
        
   }
    
    func handleError(_ error: Error, message: String, shouldUpdateState: Bool = false) {
        if shouldUpdateState {
            self.state = .none
        }
        errorMessage = "\(message): \(error.localizedDescription)"
        LoggingUtil.shared.log("\(message): \(error)", level: .error)
    }
    
    //Function to fetch the web form from the back end server
    func fetchForm(signature: String, smartActionId: Int, externalFormId: String) async{
        let webFormRequest:WebFormRequest = WebFormRequest(signature:signature, smartActionId: smartActionId, externalFormId: externalFormId)
        do{
            print("App_Log: fetching form \(webFormRequest)")
            let formResponse = try await service!.fetchWebForm(webFormRequest)
            print("App_Log: form response \(String(describing: formResponse))")
            let isFormValid = try await service!.validateWebForm(formResponse!)
            self.webFormResponse=formResponse
            //self.formSubmitSignature=try await getFormSubmitSignature(smartActionId: smartActionId, status: "success")
            print ("App_Log: uri : \(self.webFormResponse?.data.uri ?? "None")")
            print ("App_Log: isFormValid : \(isFormValid)")
        }catch {
            handleError(error, message: "Failed to end chat", shouldUpdateState: true)
        }
    }
    
    // Use resumeChat when the user bring the app from background to foreground.
    func resumChat() async{
        do{
            print("App_Log: resuming chat")
            let lastChatInProgress = try await service!.getLastChatInProgress()
            print("App_Log: last chat in progress \(lastChatInProgress!)")
            let resumeResponse = try await service!.resumeChat(lastChatInProgress!)
            print("App_Log: resume response \(resumeResponse)")
        }catch {
            handleError(error, message: "Failed to end chat", shouldUpdateState: true)
        }
    }

    //Subscribe for Push Notifications
    private func setupPushNotificationSubscription(with service: PushNotificationServiceProtocol) {
        print("App_Log: setting up push notification subscription")
        setupRequestNotificationSubscription(service)
        setupTestNotificationSubscription(service)
        setupChatNotificationReceivedSubscription(service)
    }

    private func setupRequestNotificationSubscription(_ service: PushNotificationServiceProtocol) {
        print("App_Log: requestNotificationReceivedSubject")
        service.requestNotificationReceivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                 print("App_Log: subscription for requestNotificationReceivedSubject \(notification)")
            }
        
        print("App_Log: all APNS subscription set")
    }

    private func setupChatNotificationReceivedSubscription(_ service: PushNotificationServiceProtocol) {
        print("App_Log: setupChatNotificationReceivedSubscription")
        service.chatNotificationReceivedSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                print("App_Log: subscription for chatNotificationReceivedSubject \(notification)")
            }
            .store(in: &cancellables)
    }
    
    private func setupTestNotificationSubscription(_ service: PushNotificationServiceProtocol) {
        print("App_Log: setupTestNotificationSubscription")
        service.testNotificationReceivedSubject
            .receive(on: DispatchQueue.main)
            .sink { notification in
                print("Test notification received: \(notification.apsAlertTitle ?? "No Title")")
                Toast.show(message: "Test notification received: \(notification.apsAlertTitle ?? "No Title")")
            }
            .store(in: &cancellables)
    }
    
    //Function to get signed custom data
    func requestJWTForEndUser() async -> String? {
        guard let serverURL = URL(string: "http://localhost:3000/ccai/auth") else { return nil }
        var request = URLRequest(url: serverURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload:[String: String] = ["MSISDN":"980123456"]
        
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

extension OutgoingMessageContent {
    func convertToDisplayMessageModel(user: User, url: URL?) -> Message? {
        switch self {
        case let .text(content):
            return Message(id: UUID().uuidString, user: user, text: content)

        case .images(_, _, _):
            guard let url = url else { return nil }
            let attachment = Attachment(id: UUID().uuidString, url: url, type: .image)
            return Message(id: UUID().uuidString, user: user, attachments: [attachment])

        case .videos(_, _, _):
            guard let url = url else { return nil }
            let attachment = Attachment(id: UUID().uuidString, url: url, type: .video)
            return Message(id: UUID().uuidString, user: user, attachments: [attachment])

        case .formComplete(_):
            return Message(id: UUID().uuidString, user: user, text: "form completed")
            
        @unknown default:
            break
        }

        return nil
    }
}

public struct FormDetails:Identifiable {
    public var id: String
    public var formName:String
    public var formSignature:String
    public var formExternalId:String
    public var formImageUrl:String
    public var formClicked:Bool=false
    public var formSmartActionId:Int
    
    init(form:CCAIChat.WebForm,id:String, signature:String){
        self.id=id
        formName=form.name!
        formSignature=signature
        formExternalId=form.externalFormId!
        formImageUrl=form.image!
        formSmartActionId=form.smartActionId!
    }
}

// Local function to generate the signature for demo. Should always use a back-end server to generate signature. Refer function getFormSubmitSignature
public struct FormCompletePayloadGenerator {
    let secretKey = "<forms secret key>" // Please update with your own secret
    func generateFormCompletePayload(smartActionId: Int?) -> FormCompletePayload? {
        guard let smartActionId = smartActionId,
              let dictPayload = generateFormCompleteData(smartActionId: smartActionId) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        if let jsonData = try? JSONSerialization.data(withJSONObject: dictPayload),
           let payload = try? decoder.decode(FormCompletePayload.self, from: jsonData) {
            return payload
        }
        return nil
    }

    func generateFormCompleteData(smartActionId: Int) -> [String: Any]? {
        let dataDict: [String: Any] = [
            "smart_action_id": smartActionId,
            "status": "success",
//            "timestamp": "2025-10-02T22:24:37Z"
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        guard let signature = hmacSHA256(data: dataDict, secretKey: secretKey) else { return nil }
        print("shhaipai Signature from local: \(signature)")
        return [
            "type": "form_complete",
            "signature": signature,
            "data": dataDict
        ]
    }

    private func hmacSHA256(data: [String: Any], secretKey: String) -> String? {
        guard let jsonString = jsonStringBySortedKeys(from: data),
              let messageData = jsonString.data(using: .utf8) else { return nil }
        
        print("App_Log: local jsonString: \(jsonString)")
        print("App_Log: local messageData: \(messageData)")
        
        let key = SymmetricKey(data: Data(secretKey.utf8))
        let signature = HMAC<SHA256>.authenticationCode(for: messageData, using: key)
        let hashData = Data(signature)

        return hashData.base64EncodedString()
    }

    private func jsonStringBySortedKeys(from dictionary: [String: Any]) -> String? {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: dictionary, options: .sortedKeys),
              var jsonString = String(data: jsonData, encoding: .utf8) else {
            return nil
        }
        jsonString = jsonString.replacingOccurrences(of: "\\/", with: "/")
        return jsonString
    }
}
