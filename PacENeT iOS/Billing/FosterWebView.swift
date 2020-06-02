//
//  FosterWebView.swift
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

protocol FosterWebViewHandlerDelegate {
    func cancelPayment()
}

// MARK: - FosterWebView
struct FosterWebView: UIViewRepresentable, FosterWebViewHandlerDelegate {
    func cancelPayment() {
        viewModel.showFosterWebViewPublisher.send(false)
        viewModel.showLoader.send(false)
        viewModel.errorToastPublisher.send((true, "Payment can not be done at this moment, Please try again later!"))
    }
    
    @ObservedObject var viewModel: BillingViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.isScrollEnabled = true
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let fosterUrl = viewModel.fosterProcessUrl else {
            cancelPayment()
            return
        }
        if let url = URL(string: fosterUrl) {
            webView.load(URLRequest(url: url))
        }
    }
    
    class Coordinator : NSObject, WKNavigationDelegate {
        var parent: FosterWebView
        var delegate: FosterWebViewHandlerDelegate?
        var webViewNavigationSubscriber: AnyCancellable? = nil
        
        init(_ uiWebView: FosterWebView) {
            self.parent = uiWebView
            self.delegate = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("didFinish")
            parent.viewModel.showLoader.send(false)
        }
        
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("webViewWebContentProcessDidTerminate")
            parent.viewModel.showLoader.send(false)
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("didFail")
            parent.viewModel.showLoader.send(false)
        }
        
        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            print("Started Loading")
              parent.viewModel.showLoader.send(true)
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("Started provisioning!!!")
            parent.viewModel.showLoader.send(true)
            self.webViewNavigationSubscriber = self.parent.viewModel.fosterWebViewNavigationPublisher.receive(on: RunLoop.main).sink(receiveValue: { navigation in
                if navigation == "Back" && webView.canGoBack {
                    webView.goBack()
                } else if navigation == "Next" && webView.canGoForward {
                    webView.goForward()
                } else if navigation == "Back" && !webView.canGoBack {
                    self.parent.viewModel.showFosterWebViewPublisher.send(false)
                }
            })
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if let host = navigationAction.request.url?.host {
                if host == "pacenet.net" {
                    let response = navigationAction.request.description.description.split(separator: "?")[1].split(separator: "=")
                    if response[0] == "paymentStatus" && response[1] == "true" {
                        parent.viewModel.checkFosterStatus()
                    } else if response[0] == "paymentStatus" && response[1] == "false" {
                        delegate?.cancelPayment()
                    } else {
                        delegate?.cancelPayment()
                    }

                    decisionHandler(.cancel)
                    return
                }
            }
            
            decisionHandler(.allow)
        }
    }
}
