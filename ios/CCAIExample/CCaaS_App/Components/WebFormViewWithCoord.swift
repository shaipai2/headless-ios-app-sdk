//
//  WebFormViewWithCoord.swift
//  Shipai_Test
//
//  Created by Shailesh Pai on 9/21/25.
//


import SwiftUI
import WebKit
import CCAIChat

struct WebFormViewWithCoord: UIViewRepresentable {
    let url: URL?
    @Binding var formSubmitted: Bool
    let messageHandlerName: String


    func makeUIView(context: Context) -> WKWebView {

        
        let webViewConfiguration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()

        // Add the script message handler
        userContentController.add(context.coordinator, name: messageHandlerName)
        webViewConfiguration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: webViewConfiguration)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = url {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
//        uiView.loadHTMLString(htmlString, baseURL: nil)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: WebFormViewWithCoord

        init(_ parent: WebFormViewWithCoord) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject JavaScript to listen for button clicks
            let script = """
            
            document.addEventListener('click', function(e) {
                window.webkit.messageHandlers.callbackHandler.postMessage('submitClicked');
            });
            document.addEventListener('submit', function(e) {
                window.webkit.messageHandlers.callbackHandler.postMessage('submitClicked');
            });
            """
            webView.evaluateJavaScript(script) { (result, error) in
                if let error = error {
                    print("Error injecting script: \(error.localizedDescription)")
                }else{
                    print(script)
                    print("evalauteJavaScript success")
                }
            }
        }

//        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
//            print("message /(message.name)")
//            if message.name == "buttonHandler", let messageBody = message.body as? String, messageBody == "submitClicked" {
//                parent.buttonClicked = true
//            }
//        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            print("App_Log: received message \(message.name)")
            if message.name == parent.messageHandlerName, let body = message.body as? String {
                parent.formSubmitted = true
            }
        }
    }
}
