//
//  BKashWebView.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/19/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine
import WebKit

// MARK: - BkashWebViewHandlerDelegate
/// Implement this protocol to be notified about actions done by the WebView
/// via postMessage or parameters sent by the page via a URL starting with AndroidNative://
protocol BkashWebViewHandlerDelegate {
    /// Called when a message with create payment action is received by the WebView
    /// - Parameter message: the message received
    func createPayment()
    
    /// Called when a message with execute payment action is received by the WebView
    /// - Parameter message: the message received
    func executePayment()
    
    /// Called when a message with finish payment action is received by the WebView
    /// - Parameter message: the message received
    func finishPayment()
    
    func cancelPayment()
}

 // MARK: - BKashWebView
struct BKashWebView: UIViewRepresentable, BkashWebViewHandlerDelegate {
    @ObservedObject var viewModel: BillingViewModel
    
    func createPayment() {
        viewModel.createBkashPayment()
    }
    
    func executePayment() {
        viewModel.executeBkashPayment()
    }
    
    func finishPayment() {
        viewModel.billPaymentHelper = nil
        viewModel.bkashTokenModel = nil
        viewModel.showBkashWebViewPublisher.send(false)
        viewModel.showLoader.send(false)
    }
    
    func cancelPayment() {
        viewModel.billPaymentHelper = nil
        viewModel.showBkashWebViewPublisher.send(false)
        viewModel.showLoader.send(false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let preferences = WKPreferences()
        preferences.javaScriptEnabled = true
        
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self.makeCoordinator(), name: "iOSNative")
        configuration.preferences = preferences
        
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
       return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let bkashUrl = Bundle.main.url(forResource: "checkout_120", withExtension: "html", subdirectory: "www") {
              //webView.load(URLRequest(url: bkashUrl))
            webView.loadFileURL(bkashUrl, allowingReadAccessTo: bkashUrl.deletingLastPathComponent())
        }
    }
    
    class Coordinator : NSObject, WKNavigationDelegate {
        var parent: BKashWebView
        var delegate: BkashWebViewHandlerDelegate?
        var paymentStatusSubscriber: AnyCancellable? = nil
        var createPaymentSubscriber: AnyCancellable? = nil
        var webViewNavigationSubscriber: AnyCancellable? = nil
        
        init(_ uiWebView: BKashWebView) {
            self.parent = uiWebView
            self.delegate = parent
        }
        
        deinit {
            paymentStatusSubscriber?.cancel()
            createPaymentSubscriber?.cancel()
            webViewNavigationSubscriber?.cancel()
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            paymentStatusSubscriber = parent.viewModel.bkashPaymentStatusPublisher.receive(on: RunLoop.main).sink(receiveValue: { (isSuccessful, message) in
                if isSuccessful {
                    self.parent.viewModel.successToastPublisher.send((true, message))
                    let javascriptFunction = "finishBkashPayment();"
                    webView.evaluateJavaScript(javascriptFunction) { (response, error) in
                        if let _ = error {
                            print("Error calling javascript:finishBkashPayment()")
                            self.parent.viewModel.errorToastPublisher.send((true, "Error finishing payment, Please try again later!"))
                            self.delegate?.cancelPayment()
                        }
                        else {
                            print("Called javascript:finishBkashPayment()")
                        }
                    }
                } else {
                    self.parent.viewModel.errorToastPublisher.send((true, message))
                    self.delegate?.cancelPayment()
                }
            })
            
            createPaymentSubscriber = parent.viewModel.bkashCreatePaymentPublisher.receive(on: RunLoop.main).sink(receiveValue: { resBkash in
                guard let data = resBkash.data(using: .utf8) else {
                    self.parent.viewModel.errorToastPublisher.send((true, "Error in resBkash data parsing, Please try again later!"))
                    self.delegate?.cancelPayment()
                    return
                }
                
                var jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                jsonObject?["errorCode"] = nil
                jsonObject?["errorMessage"] = nil
                
                guard let bkashExecuteJson = jsonObject else {
                    self.parent.viewModel.errorToastPublisher.send((true, "Error in jsonObject data parsing, Please try again later!"))
                    self.delegate?.cancelPayment()
                    return
                }
                
                self.parent.viewModel.bkashPaymentExecuteJson = bkashExecuteJson
                
                guard let newJsonData = try? JSONSerialization.data(withJSONObject: jsonObject as Any, options: .fragmentsAllowed) else {
                    self.parent.viewModel.errorToastPublisher.send((true, "Error in newJsonData parsing, Please try again later!"))
                    self.delegate?.cancelPayment()
                    return
                }

                
                guard let jsonString = String(data: newJsonData, encoding: .utf8) else {
                    self.parent.viewModel.errorToastPublisher.send((true, "Error in jsonString parsing, Please try again later!"))
                    self.delegate?.cancelPayment()
                    return
                }
                
                let javascriptFunction = "createBkashPayment(\(jsonString));"
                webView.evaluateJavaScript(javascriptFunction) { (response, error) in
                    if let _ = error {
                        print("Error calling javascript:createBkashPayment()")
                        self.parent.viewModel.errorToastPublisher.send((true, "Error creating payment, Please try again later!"))
                        self.delegate?.cancelPayment()
                    }
                    else {
                        print("Called javascript:createBkashPayment()")
                    }
                }
                
            })
            
            guard let amount = parent.viewModel.billPaymentHelper?.balanceAmount else {
                self.parent.viewModel.errorToastPublisher.send((true, "Invalid payment amount!"))
                self.delegate?.cancelPayment()
                return
            }
            
            let request = PaymentRequest(amount: String(amount))
            guard let jsonData = try? JSONEncoder().encode(request) else {
                self.parent.viewModel.errorToastPublisher.send((true, "Error in jsonData parsing, Please try again later!"))
                self.delegate?.cancelPayment()
                return
            }
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                self.parent.viewModel.errorToastPublisher.send((true, "Error in jsonString parsing, Please try again later!"))
                self.delegate?.cancelPayment()
                return
            }

            let parameter = "{paymentRequest:\(jsonString)}"
            let javascriptFunction1 = "callReconfigure(\(parameter));"
            let javascriptFunction2 = "clickPayButton();"
            webView.evaluateJavaScript(javascriptFunction1) { (response, error) in
                if let _ = error {
                    self.parent.viewModel.errorToastPublisher.send((true, "Error configuring payment, Please try again later!"))
                    self.delegate?.cancelPayment()
                    print("Error calling javascript:callReconfigure()")
                }
                else {
                    print("Called javascript:callReconfigure()")
                }
            }

            webView.evaluateJavaScript(javascriptFunction2) { (response, error) in
                if let _ = error {
                    self.parent.viewModel.errorToastPublisher.send((true, "Error opening bkash payment, Please try again later!"))
                    self.delegate?.cancelPayment()
                    print("Error calling javascript:clickPayButton()")
                }
                else {
                    print("Called javascript:clickPayButton()")
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.viewModel.showLoader.send(false)
            }
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            parent.viewModel.showLoader.send(false)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.viewModel.showLoader.send(false)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.viewModel.showLoader.send(true)
            webViewNavigationSubscriber = parent.viewModel.bkashWebViewNavigationPublisher.receive(on: RunLoop.main).sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        print(error.localizedDescription)
                }
            }, receiveValue: { navigation in
                
                if navigation == "Back" && webView.canGoBack {
                    webView.goBack()
                } else if navigation == "Next" && webView.canGoForward {
                    webView.goForward()
                } else if navigation == "Back" && !webView.canGoBack {
                    self.delegate?.cancelPayment()
                } else {
                    self.delegate?.cancelPayment()
                }
            })
        }
    }
}

// MARK: - Extensions
extension BKashWebView.Coordinator: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "iOSNative" {
            if let body = message.body as? [String: String] {
                guard let action = body["action"] else { return }
                if action == "CREATE" {
                    delegate?.createPayment()
                } else if action == "EXECUTE" {
                    delegate?.executePayment()
                } else if action == "FINISH" {
                    delegate?.finishPayment()
                }
            }
        }
    }
}
