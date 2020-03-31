//
//  Billing.swift
//  PacENeT iOS
//
//  Created by rgl on 29/12/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI
import Foundation
import Combine
import UIKit
import WebKit

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
}

struct Billing: View {
    
    @EnvironmentObject var userData: UserData
    @ObservedObject var viewModel = BillingViewModel()
    @State var showRechargeDialog = false
    @State var showRechargeConfDialog = false
    @State var disableOkButton = true
    @State var showFosterWebView = false
    @State var showBkashWebView = false
    
    // Toasts
    @State var showSuccessToast = false
    @State var successMessage: String = ""
    @State var showErrorToast = false
    @State var errorMessage: String = ""
    
    @State private var showLoader = false
    @State private var showSignoutAlert = false
    
    @State var note = ""
    
    var signoutButton: some View {
        Button(action: {
            self.showSignoutAlert = true
        }) {
            Text("Sign Out")
                .foregroundColor(Colors.greenTheme)
        }
        .alert(isPresented:$showSignoutAlert) {
            Alert(title: Text("Sign Out"), message: Text("Are you sure to sign out?"), primaryButton: .destructive(Text("Yes")) {
                self.userData.isLoggedIn = false
                }, secondaryButton: .cancel(Text("No")))
        }
    }
    
    var refreshButton: some View {
        Button(action: {
            //            self.viewModel.refreshUI()
            
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 18, weight: .light))
                .imageScale(.large)
                .accessibility(label: Text("Refresh"))
                .padding()
                .foregroundColor(Colors.greenTheme)
            
        }
    }
    
    struct MultilineTextField: UIViewRepresentable {
        @Binding var text: String
        
        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }
        
        func makeUIView(context: Context) -> UITextView {
            let view = UITextView()
            view.delegate = context.coordinator
            view.layer.borderWidth = 0.5
            view.layer.borderColor = UIColor.lightGray.cgColor
            view.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
            view.layer.cornerRadius = 6
            view.isScrollEnabled = true
            view.isEditable = true
            view.isUserInteractionEnabled = true
            return view
        }
        
        func updateUIView(_ uiView: UITextView, context: Context) {
            uiView.text = text
        }
        
        class Coordinator : NSObject, UITextViewDelegate {
            
            var parent: MultilineTextField
            
            init(_ uiTextView: MultilineTextField) {
                self.parent = uiTextView
            }
            
            func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
                return true
            }
            
            func textViewDidChange(_ textView: UITextView) {
                self.parent.text = textView.text
            }
        }
    }
    
    var rechargeAmountDialog: some View {
        ZStack {
            Color.black
                .blur(radius: 0.5, opaque: false)
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    HStack {
                        Image("recharge_image")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .padding(.leading, 16)
                        Text("Recharge")
                            .font(.system(size: 20, weight: .light))
                            .foregroundColor(Colors.color2)
                    }
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.trailing, 20)
                
                VStack(spacing: 2) {
                    TextField("Amount", text: $viewModel.rechargeAmount)
                        .lineLimit(1)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                    HStack {
                        if viewModel.invalidAmountMessage != "" {
                            Text(viewModel.invalidAmountMessage)
                                .font(.caption)
                                .multilineTextAlignment(.leading)
                                .lineLimit(nil)
                                .foregroundColor(.red)
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                        }
                        Spacer()
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Note")
                        .font(.system(size: 20))
                        .fontWeight(.light)
                        .foregroundColor(Colors.color2)
                    
                    MultilineTextField(text: $note).frame(height: 150)
                }
                .padding(.leading, 20)
                .padding(.trailing, 20).padding(.top, 8)
                
                HStack(alignment: .center, spacing: 20) {
                    Spacer()
                    Button(action: {
                        self.showRechargeDialog = false
                    }) {
                        HStack{
                            Spacer()
                            Text("Cancel")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .background(Color.red)
                        .cornerRadius(2)
                    }
                    
                    Button(action: {
                        self.showRechargeDialog = false
                        self.showRechargeConfDialog = true
                    }) {
                        HStack{
                            Spacer()
                            Text("Pay")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 8)
                        .background(Colors.greenTheme)
                        .cornerRadius(2)
                    }
                    .disabled(self.disableOkButton)
                    .onReceive(self.viewModel.okButtonDisablePublisher.receive(on: RunLoop.main)) { isDisabled in
                        self.disableOkButton = isDisabled
                    }
                }
                .padding(.leading, 20)
                .padding(.trailing, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 6, style: .circular).fill(Color.white)
            .shadow(color: .black, radius: 15))
            .padding(.leading, 25)
            .padding(.trailing, 25)
        }
    }
    
    var rechargeConfDialog: some View {
        ZStack {
            Color.black
                .blur(radius: 0.5, opaque: false)
                .opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Recharge Summary")
                            .font(.system(size: 20, weight: .light))
                            .fontWeight(.bold)
                            .foregroundColor(Colors.color2)
                        Divider().padding(.top, 4).padding(.bottom, 4)
                        Text("Recharge Amount: \(viewModel.rechargeAmount)")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(Colors.color2)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil).padding(.top, 8)
                        Text("Note: \(note)")
                            .font(.system(size: 18, weight: .light))
                            .foregroundColor(Colors.color2)
                            .multilineTextAlignment(.leading)
                            .lineLimit(3).padding(.top, 4)
                    }
                    .padding(.top, 16)
                    .padding(.leading, 20)
                    
                    Spacer()
                    Button(action: {
                        self.showRechargeConfDialog = false
                        self.viewModel.rechargeAmount = ""
                        self.note = ""
                    }) {
                        Image(systemName: "multiply")
                            .font(.system(size: 18, weight: .ultraLight))
                            .imageScale(.large)
                            .accessibility(label: Text("Close Recharge Confirmation Dialog"))
                            .foregroundColor(.gray)
                        
                    }
                    .padding(.trailing, 10)
                    .padding(.leading, 10)
                    .padding(.top, 10)
                    .padding(.bottom, 10)
                }
                
                Image("recharge_now")
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        self.viewModel.showLoader.send(true)
                        self.viewModel.getFosterPaymentUrl()
                        
                        self.showRechargeConfDialog = false
                        self.viewModel.rechargeAmount = ""
                        self.note = ""
                }
                
                Image("bkash_payment_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding(.leading, 35)
                    .padding(.trailing, 35)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    .onTapGesture {
                        self.viewModel.showLoader.send(true)
                        if self.viewModel.bkashTokenModel == nil {
                            self.viewModel.getBkashToken()
                        } else {
                            self.showBkashWebView = true
                        }
                        self.showRechargeConfDialog = false
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 6, style: .circular).fill(Color.white)
            .shadow(color: .black, radius: 15))
            .padding(.leading, 25)
            .padding(.trailing, 25)
        }
    }
    
    struct FosterWebView: UIViewRepresentable {
        var viewModel: BillingViewModel
        
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
            if let url = URL(string: viewModel.fosterProcessUrl) {
                webView.load(URLRequest(url: url))
            }
        }
        
        class Coordinator : NSObject, WKNavigationDelegate {
            
            var parent: FosterWebView
            
            init(_ uiWebView: FosterWebView) {
                self.parent = uiWebView
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
//                parent.viewModel.showLoader.send(true)
            }
            
            func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
                print("Started provisioning!!!")
                parent.viewModel.showLoader.send(true)
                _ = parent.viewModel.fosterWebViewNavigationPublisher.receive(on: RunLoop.main).sink(receiveValue: { navigation in
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
                            parent.viewModel.showFosterWebViewPublisher.send(false)
                            parent.viewModel.checkFosterStatus()
                        } else if response[0] == "paymentStatus" && response[1] == "false" {
                            parent.viewModel.showFosterWebViewPublisher.send(false)
                            print("FAILURE")
                        }

                        decisionHandler(.cancel)
                        return
                    }
                }
                
                decisionHandler(.allow)
            }
        }
    }
    
    struct BKashWebView: UIViewRepresentable, BkashWebViewHandlerDelegate {
        var viewModel: BillingViewModel
        
        func createPayment() {
            viewModel.createBkashPayment()
        }
        
        func executePayment() {
            viewModel.executeBkashPayment()
        }
        
        func finishPayment() {
            viewModel.showBkashWebViewPublisher.send(false)
            viewModel.showLoader.send(false)
            viewModel.bkashTokenModel = nil
            viewModel.rechargeAmount = ""
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
//                webView.load(URLRequest(url: bkashUrl))
                webView.loadFileURL(bkashUrl, allowingReadAccessTo: bkashUrl.deletingLastPathComponent())
            }
        }
        
        class Coordinator : NSObject, WKNavigationDelegate {
            
            var parent: BKashWebView
            var delegate: BkashWebViewHandlerDelegate?
            
            init(_ uiWebView: BKashWebView) {
                self.parent = uiWebView
                self.delegate = parent
            }
            
            func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
                
//                if response.resdata.resstate! {
//                    self.successToastPublisher.send((true, response.resdata.message ?? "Payment not successful, Please try again"))
//                } else {
//                    self.errorToastPublisher.send((true, response.resdata.message ?? "Payment not successful, Please try again"))
//                }
                
                _ = parent.viewModel.bkashPaymentStatusPublisher.receive(on: RunLoop.main).sink(receiveValue: { (isSuccessful, message) in
                    if isSuccessful {
                        self.parent.viewModel.successToastPublisher.send((true, message ?? "Payment not successful, Please try again"))
                        let javascriptFunction = "finishBkashPayment();"
                        webView.evaluateJavaScript(javascriptFunction) { (response, error) in
                            if let _ = error {
                                print("Error calling javascript:callReconfigure()")
                            }
                            else {
                                print("Called javascript:callReconfigure()")
                            }
                        }
                    } else {
                        self.parent.viewModel.errorToastPublisher.send((true, message ?? "Payment not successful, Please try again"))
                        self.parent.viewModel.showBkashWebViewPublisher.send(false)
                        self.parent.viewModel.showLoader.send(false)
                    }
                })
                
                _ = parent.viewModel.bkashCreatePaymentPublisher.receive(on: RunLoop.main).sink(receiveValue: { resBkash in
                    guard let data = resBkash.data(using: .utf8) else {
                        print("Problem in response data parsing...")
                        return
                    }
                    
                    var jsonObject = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                    jsonObject?["errorCode"] = nil
                    jsonObject?["errorMessage"] = nil
                    
                    self.parent.viewModel.bkashPaymentExecuteJson = jsonObject!
                    
                    guard let newJsonData = try? JSONSerialization.data(withJSONObject: jsonObject as Any, options: .fragmentsAllowed) else { return }

                    
                    let jsonString = String(data: newJsonData, encoding: .utf8)!
                    
                    let javascriptFunction = "createBkashPayment(\(jsonString));"
                    webView.evaluateJavaScript(javascriptFunction) { (response, error) in
                        if let _ = error {
                            print("Error calling javascript:callReconfigure()")
                        }
                        else {
                            print("Called javascript:callReconfigure()")
                        }
                    }
                    
                })
                
                let request = PaymentRequest(amount: parent.viewModel.rechargeAmount)
                let jsonData = try! JSONEncoder().encode(request)
                let jsonString = String(data: jsonData, encoding: .utf8) ?? "ERROR"
                print(jsonString)
                
                let parameter = "{paymentRequest:\(jsonString)}"
                let javascriptFunction1 = "callReconfigure(\(parameter));"
                let javascriptFunction2 = "clickPayButton();"
                webView.evaluateJavaScript(javascriptFunction1) { (response, error) in
                    if let _ = error {
                        print("Error calling javascript:callReconfigure()")
                    }
                    else {
                        print("Called javascript:callReconfigure()")
                    }
                }
                
                webView.evaluateJavaScript(javascriptFunction2) { (response, error) in
                    if let _ = error {
                        print("Error calling javascript:clickPayButton()")
                    }
                    else {
                        print("Called javascript:clickPayButton()")
                    }
                }
                parent.viewModel.showLoader.send(false)
            }
            
            func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
                parent.viewModel.showLoader.send(false)
            }
            
            func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
                parent.viewModel.showLoader.send(false)
            }
            
            func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
                parent.viewModel.showLoader.send(true)
                _ = parent.viewModel.bkashWebViewNavigationPublisher.receive(on: RunLoop.main).sink(receiveValue: { navigation in
                    if navigation == "Back" && webView.canGoBack {
                        webView.goBack()
                    } else if navigation == "Next" && webView.canGoForward {
                        webView.goForward()
                    } else if navigation == "Back" && !webView.canGoBack {
                        self.parent.viewModel.showBkashWebViewPublisher.send(false)
                        self.parent.viewModel.showLoader.send(false)
                    }
                })
            }
            
            func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
                if let host = navigationAction.request.url?.host {
                    if host == "pacecloud.com" {
                        let response = navigationAction.request.description.description.split(separator: "?")[1].split(separator: "=")
                        if response[0] == "paymentStatus" && response[1] == "true" {
                            parent.viewModel.showFosterWebViewPublisher.send(false)
                            parent.viewModel.checkFosterStatus()
                        } else if response[0] == "paymentStatus" && response[1] == "false" {
                            parent.viewModel.showFosterWebViewPublisher.send(false)
                            print("FAILURE")
                        }
                        
                        decisionHandler(.cancel)
                        return
                    }
                }
                
                decisionHandler(.allow)
            }
        }
    }
    
    var rechargeFosterWebView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    self.viewModel.fosterWebViewNavigationPublisher.send("Back")
                }) {
                    HStack {
                        Image(systemName: "arrow.turn.up.left")
                            .font(.system(size: 18, weight: .ultraLight))
                            .imageScale(.large)
                            .accessibility(label: Text("Close Recharge Confirmation Dialog"))
                            .foregroundColor(.gray)
                        Text("Back")
                    }
                }
                Spacer()
                Divider()
                Spacer()
                Button(action: {
                    self.viewModel.fosterWebViewNavigationPublisher.send("Next")
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 18, weight: .ultraLight))
                            .imageScale(.large)
                            .accessibility(label: Text("Close Recharge Confirmation Dialog"))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }.frame(height: 36)
            Divider()
            FosterWebView(viewModel: self.viewModel)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.white)
    }
    
    var rechargeBKashWebView: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(action: {
                    self.viewModel.bkashWebViewNavigationPublisher.send("Back")
                }) {
                    HStack {
                        Image(systemName: "arrow.turn.up.left")
                            .font(.system(size: 18, weight: .ultraLight))
                            .imageScale(.large)
                            .accessibility(label: Text("Close Recharge Confirmation Dialog"))
                            .foregroundColor(.gray)
                        Text("Back")
                    }
                }
                Spacer()
                Divider()
                Spacer()
                Button(action: {
                    self.viewModel.bkashWebViewNavigationPublisher.send("Next")
                }) {
                    HStack {
                        Text("Next")
                        Image(systemName: "arrow.turn.up.right")
                            .font(.system(size: 18, weight: .ultraLight))
                            .imageScale(.large)
                            .accessibility(label: Text("Close Recharge Confirmation Dialog"))
                            .foregroundColor(.gray)
                    }
                }
                Spacer()
            }.frame(height: 36)
            Divider()
            BKashWebView(viewModel: self.viewModel)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        .background(Color.white)
    }
    
    var headerView: some View {
        VStack(spacing: 4) {
            Button(action: {
                self.showRechargeDialog = true
            }) {
                HStack{
                    Spacer()
                    Text("Recharge")
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.bottom, 8)
                .background(Colors.greenTheme)
                .cornerRadius(2)
                .frame(width: 200)
            }.padding(.top, 10)
            Spacer()
        }
        .padding(.leading, 20)
        .padding(.trailing, 20)
        .navigationBarTitle(Text("Balance Inquiry"), displayMode: .inline)
        .navigationBarItems(leading: refreshButton, trailing: signoutButton)
    }

    var body: some View {
        NavigationView {
            ZStack {
                headerView
                    
                if showRechargeDialog {
                    rechargeAmountDialog
                }
                
                if showRechargeConfDialog {
                    rechargeConfDialog
                }
                
                if showFosterWebView {
                    rechargeFosterWebView
                }
                
                if showBkashWebView {
                    rechargeBKashWebView
                }

                if showSuccessToast {
                    VStack {
                        Spacer()
                        SuccessToast(message: self.successMessage).onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation() {
                                    self.showSuccessToast = false
                                    self.successMessage = ""
                                }
                            }
                        }.padding(.all, 20)
                    }
                }

                if showErrorToast {
                    VStack {
                        Spacer()
                        ErrorToast(message: self.errorMessage).onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                withAnimation() {
                                    self.showErrorToast = false
                                    self.errorMessage = ""
                                }
                            }
                        }.padding(.all, 20)
                    }
                }

                if showLoader {
                    SpinLoaderView()
                }
            }
            .onReceive(self.viewModel.showFosterWebViewPublisher.receive(on: RunLoop.main)) { shouldShow in
                self.showFosterWebView = shouldShow
            }
            .onReceive(self.viewModel.showBkashWebViewPublisher.receive(on: RunLoop.main)) { shouldShow in
                self.showBkashWebView = shouldShow
                self.showLoader = true
            }
            .onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { shouldShow in
                self.showLoader = shouldShow
            }
            .onReceive(self.viewModel.errorToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                self.showErrorToast = shouldShow
                self.errorMessage = message
            }
            .onReceive(self.viewModel.successToastPublisher.receive(on: RunLoop.main)) { (shouldShow, message) in
                self.showSuccessToast = shouldShow
                self.successMessage = message
            }.navigationBarTitle(Text("Billing"), displayMode: .inline)
                .navigationBarItems(leading: refreshButton, trailing: signoutButton)
        }
    }
}

extension Billing.BKashWebView.Coordinator: WKScriptMessageHandler {
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
//            else if let body = message.body as? String {
//                if let parameters = ParametersHandler.decodeParameters(inString: body) {
//                    delegate?.didReceiveParameters(parameters: parameters)
//                }
//            }
        }
    }
}

struct Billing_Previews: PreviewProvider {
    static var previews: some View {
        Billing().environmentObject(UserData())
    }
}
