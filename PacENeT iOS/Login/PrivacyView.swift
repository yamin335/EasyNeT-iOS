//
//  PrivacyView.swift
//  Pace Cloud
//
//  Created by rgl on 2/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI

struct PrivacyView: View {
    @Environment(\.presentationMode) var presentation
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
        
                Group {
                    Text("The PacENeT Privacy Policy was updated on April 22, 2020.").font(.footnote).fontWeight(.semibold).padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("Please read carefully and familiarize yourself with this Privacy Policy to use our PacENeT application and contact us at support@royalgreen.net if you have any questions.").font(.caption).fontWeight(.light)
                        .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("This privacy policy sets out how PacENeT collects uses, discloses, stores and protects any information that you gave when you subscribe to use our service(s) and application(s). PacENeT is committed to ensure that your private data that we collect and use is protected and we do not share any of your information to any other third parties. We may ask you to provide certain information depending on the contents and services you use so that we can identify you and provide you appropriate service.").font(.caption).fontWeight(.light).fixedSize(horizontal: false, vertical: true).padding(.leading, 16).padding(.trailing, 16).padding(.top, 8)
                }
                
                Group {
                    Text("Collection and Use of Personal Information").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("What personal information we collect are listed here:").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("When you register an account to get PacENeT services, you may have to provide us some of your personal information including your name, organization name, address, email address, phone number, date of birth, National Identity Number, your passport size photograph.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("We may collect your location information, device identity to identify you concisely to provide our services.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("When you log in to PacENeT we provide an authentication number along with your user ID and other information that is saved to your device to let you use PacENeT app securely for entire session and during log out we erase all data that we provided during login.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("During your monthly bill payment our payment gateways require your debit / credit card information or your mobile banking information to successfully complete online bill payment.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("When you make conversation with our support team generally you have to send text but you may share photos taken either from your device’s camera or storage to our support team. You may also share any kind of document or media files that describe your problems with our services. All these document and media file sharing depends on your intention, we do not automatically collect any document, media or other types of files from your device without your intention and consent.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                }
                
                Group {
                    Text("How we use your personal information").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("We may use your personal information for the following purposes with your consent:").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("We may use your personal information to verify your identity, verify your bill payments and provide your specific services that you bought from us.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("We may use your email, phone, device identity and other information to periodically notify you about service updates, changes, purchases, billings, dues, payments and your other activities through notifications, emails, messages, phone calls and other communicative ways that you allowed by subscriptions.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                }
                
                Group {
                    Text("Collection and Use of Non-Personal Information").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("We may collect some non-personal information and store it to provide you standard quality services. Non- personal information that we collect are listed here:").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("We may collect, use and store your text messages, documents, media files that you shared with us in different times and purposes.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("We may collect your location information to keep logs of your signing activities and secure your signing in by making alerts to you.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                }
                
                Group {
                    Text("Controlling Your Personal Information").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("You may choose to restrict the collection or use of your personal information in the following ways:").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("Whenever you are asked to fill in a form on the application, look for the fields properly that you want or do not want the information to be used by our services.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("If you have previously agreed to us using your personal information for service purposes, you may change your mind at any time by writing to us.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                }
                
                Group {
                    Text("Use of Third Party Library or SDKs").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("We integrated following third-party libraries into PacENeT application:").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    HStack(alignment: .top) {
                        Text("•").font(.footnote).fontWeight(.bold)
                        .padding(.leading, 24)
                        Text("Charts: https://github.com/danielgindi/Charts - for showing various statistics within a chart.").font(.caption).fontWeight(.light).padding(.trailing, 16)
                        Spacer()
                    }
                }
                
                Group {
                    Text("Protection of Your Information").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("PacENeT is committed to ensure the security of your data that you provided. In order to prevent unauthorized access or disclosure, we store your data in our server which complies all standard security parameters.").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    
                    Text("Your Privacy Rights").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("We do not share, sell, disclose, distribute or lease any of your personal information to any other third parties unless we have your consent and permission or required by law to do so. You may request any time to correct, erase or permanently remove all of your information that you provided us and if you do so we are obliged to process your request. You can take any actions with legal law against us if we violate any part of this privacy policy.").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    
                    Text("Privacy Queries").font(.footnote).fontWeight(.semibold)
                    .padding(.leading, 16).padding(.trailing, 16).padding(.top, 16)
                    Text("If you do not understand or agree with the privacy policy we strongly recommend you not to download, install and use PacENeT application. If you have any suggestions or queries about this privacy policy, please contact with us. PacENeT may change this privacy policy from time to time by updating this privacy policy. You should check this privacy policy to ensure that you are not with any inconsistency with any updates of this privacy policy. This privacy policy is effective from April 22, 2020.").font(.caption).fontWeight(.light).padding(.leading, 16).padding(.trailing, 16)
                    
                    HStack {
                        Spacer()
                        Text("All Rights Reserved. Copyright ©2020, Royal Green Ltd.")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.top, 36).padding(.bottom, 16)
                        Spacer()
                    }
                }
            }
            .navigationBarTitle(Text("Privacy Policy"))
        }
    }
}

struct PrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        PrivacyView()
    }
}
