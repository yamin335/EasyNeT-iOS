//
//  ContactView.swift
//  Pace Cloud
//
//  Created by rgl on 2/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI
import MessageUI
import UIKit

struct ContactView: View {
    @Environment(\.presentationMode) var presentation
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var showMailView = false
    @State var mailAlert = false
    @State var tel = "+88-09603-111999"
    @State var phone1 = "+88-01777706745"
    @State var phone2 = "+88-01777706746"
    @State var mail = "support@royalgreen.net"
    @State var web = "https://pacenet.net/"
    
    var headerView: some View {
        VStack {
            Image("pace_net")
                .resizable()
                .frame(width: 120, height: 120)
                .padding(.top, 20)
            Text("114, Motijheel (Level 9 & 17), Dhaka, 1000")
                .font(.subheadline)
                .foregroundColor(Colors.color2)
                .padding(.top, 10)
        }.padding(.bottom, 20)
    }
    
    var telephoneView: some View {
        HStack {
            Button(action: {
                guard let url = URL(string: "tel://\(self.tel)"),
                    UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(Colors.greenTheme)
                    
                    VStack(alignment: .leading) {
                        Text(tel)
                            .font(.callout)
                            .foregroundColor(Colors.color2)
                        Text("Telephone")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
            }
            Spacer()
        }.padding(.leading, 20)
    }
    
    var phone1View: some View {
        HStack {
            Button(action: {
                guard let url = URL(string: "tel://\(self.phone1)"),
                    UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(Colors.greenTheme)
                    
                    VStack(alignment: .leading) {
                        Text(phone1)
                            .font(.callout)
                            .foregroundColor(Colors.color2)
                        Text("Mobile")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Button(action: {
                let sms: String = "sms:\(self.phone1)&body=Hi, I am"
                guard let stringUrl = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {return}
                guard let url = URL(string: stringUrl), UIApplication.shared.canOpenURL(url) else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(Colors.color4)
                .padding(.trailing, 25)
                .padding(.leading, 20)
            }
        }.padding(.leading, 20)
    }
    
    var phone2View: some View {
        HStack {
            Button(action: {
                guard let url = URL(string: "tel://\(self.phone2)"),
                    UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(Colors.greenTheme)
                    
                    VStack(alignment: .leading) {
                        Text(phone2)
                            .font(.callout)
                            .foregroundColor(Colors.color2)
                        Text("Mobile")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
            Button(action: {
                let sms: String = "sms:\(self.phone2)&body=Hi, I am"
                guard let stringUrl = sms.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {return}
                guard let url = URL(string: stringUrl), UIApplication.shared.canOpenURL(url) else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 28, weight: .ultraLight))
                .foregroundColor(Colors.color4)
                .padding(.trailing, 25)
                .padding(.leading, 20)
            }
        }.padding(.leading, 20)
    }
    
    var emailView: some View {
        HStack {
            Button(action: {
                MFMailComposeViewController.canSendMail() ? self.showMailView.toggle() : self.mailAlert.toggle()
            }) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(Colors.color3)
                    
                    VStack(alignment: .leading) {
                        Text(mail)
                            .font(.callout)
                            .foregroundColor(Colors.color2)
                        Text("Email")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }.padding(.leading, 20)
    }
    
    var webView: some View {
        HStack {
            Button(action: {
                guard let webURL = URL(string: self.web), UIApplication.shared.canOpenURL(webURL) else {return}
                //redirect to safari
                UIApplication.shared.open(webURL as URL, options: [:], completionHandler: nil)
            }) {
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 28, weight: .ultraLight))
                        .foregroundColor(Colors.color4)
                    
                    VStack(alignment: .leading) {
                        Text("www.pacenet.net")
                            .font(.callout)
                            .foregroundColor(Colors.color2)
                        Text("Web")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
            }
            Spacer()
        }.padding(.leading, 20)
    }
    
    var body: some View {
        VStack {
            Group {
                headerView
                Divider().padding(.leading, 20)
                telephoneView
                Divider().padding(.leading, 20)
                phone1View
                Divider().padding(.leading, 20)
            }
            
            Group {
                phone2View
                Divider().padding(.leading, 20)
                emailView
                Divider().padding(.leading, 20)
                webView
                Divider().padding(.leading, 20)
            }
            
//            HStack(spacing: 3) {
//                Image("icons8_facebook_circled_36")
//                    .resizable()
//                    .frame(width: 36, height: 36)
//                VStack(alignment: .leading) {
//                    Text("www.facebook.com/Royalgreenbd")
//                        .font(.callout)
//                        .foregroundColor(Colors.color2)
//                    Text("Facebook")
//                        .font(.caption)
//                        .foregroundColor(.gray)
//                }
//                Spacer()
//            }.padding(.top, 5)
//                .padding(.leading, 17)
//                .onTapGesture {
//                let screenName = "Royalgreenbd"
//                let appURL = NSURL(string: "facebook://user?screen_name=\(screenName)")!
//                let webURL = NSURL(string: "https://facebook.com/\(screenName)")!
//
//                if UIApplication.shared.canOpenURL(appURL as URL) {
//                    if #available(iOS 10.0, *) {
//                        UIApplication.shared.open(appURL as URL, options: [:], completionHandler: nil)
//                    } else {
//                        UIApplication.shared.openURL(appURL as URL)
//                    }
//                } else {
//                    //redirect to safari because the user doesn't have facebook app
//                    if #available(iOS 10.0, *) {
//                        UIApplication.shared.open(webURL as URL, options: [:], completionHandler: nil)
//                    } else {
//                        UIApplication.shared.openURL(webURL as URL)
//                    }
//                }
//            }
            
            Spacer()
        }
        .alert(isPresented:$mailAlert) {
            Alert(title: Text("Please configure your mail first"), dismissButton: .cancel(Text("OK")))
        }
        .sheet(isPresented: $showMailView) {
            MailView(result: self.$result, recipients: [self.mail])
        }
        .navigationBarTitle(Text("Contact Us"))
    }
    
    func mailComposeController(controller: MFMailComposeViewController,
                               didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        // Check the result or perform other tasks.
        
        // Dismiss the mail compose view controller.
        controller.dismiss(animated: true, completion: nil)
    }
}

struct ContactView_Previews: PreviewProvider {
    static var previews: some View {
        ContactView()
    }
}
