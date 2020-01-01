//
//  UserData.swift
//  Pace Cloud
//
//  Created by rgl on 1/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import SwiftUI
import Combine

final class UserData: ObservableObject  {
    @Published var isLoggedIn = false
    @Published var shouldShowSplash = true
}

struct UserLocalStorage {
    private static let userDefault = UserDefaults.standard
    static func saveUser(user: User) {
        userDefault.set(user.userID, forKey: "userID")
        userDefault.set(user.userName, forKey: "userName")
        userDefault.set(user.fullName, forKey: "fullName")
        userDefault.set(user.displayName, forKey: "displayName")
        userDefault.set(user.emailAddr, forKey: "emailAddress")
        userDefault.set(user.email, forKey: "email")
        userDefault.set(user.phone, forKey: "phone")
        userDefault.set(user.balance, forKey: "balance")
        userDefault.set(user.profileID, forKey: "profileID")
        userDefault.set(user.srvName, forKey: "srvName")
        userDefault.set(user.unitPrice, forKey: "unitPrice")
        userDefault.set(user.created, forKey: "created")
    }
    
    static func getUser() -> User {
        var user = User()
        
        user.userID = userDefault.value(forKey: "userID") as? Int ?? 0
        user.userName = userDefault.value(forKey: "userName") as? String ?? ""
        user.fullName = userDefault.value(forKey: "fullName") as? String ?? ""
        user.displayName = userDefault.value(forKey: "displayName") as? String ?? ""
        user.emailAddr = userDefault.value(forKey: "emailAddress") as? String ?? ""
        user.email = userDefault.value(forKey: "email") as? String ?? ""
        user.phone = userDefault.value(forKey: "phone") as? String ?? ""
        user.balance = userDefault.value(forKey: "balance") as? Double ?? 0.0
        user.profileID = userDefault.value(forKey: "profileID") as? Int ?? 0
        user.srvName = userDefault.value(forKey: "srvName") as? String ?? ""
        user.unitPrice = userDefault.value(forKey: "unitPrice") as? Double ?? 0.0
        user.created = userDefault.value(forKey: "created") as? String ?? ""
        
        return user
    }
    
    static func clearUser(){
        userDefault.removeObject(forKey: "userID")
        userDefault.removeObject(forKey: "userName")
        userDefault.removeObject(forKey: "fullName")
        userDefault.removeObject(forKey: "displayName")
        userDefault.removeObject(forKey: "emailAddress")
        userDefault.removeObject(forKey: "email")
        userDefault.removeObject(forKey: "phone")
        userDefault.removeObject(forKey: "balance")
        userDefault.removeObject(forKey: "profileID")
        userDefault.removeObject(forKey: "srvName")
        userDefault.removeObject(forKey: "unitPrice")
        userDefault.removeObject(forKey: "created")
    }
    
    static func saveUserCredentials(userCredentials: UserCredentials) {
        userDefault.set(userCredentials.userName, forKey: "userNameCreden")
        userDefault.set(userCredentials.password, forKey: "passwordCreden")
    }
    
    static func getUserCredentials() -> UserCredentials {
        return UserCredentials(userName: userDefault.value(forKey: "userNameCreden") as? String ?? "", password: userDefault.value(forKey: "passwordCreden") as? String ?? "")
    }
    
    static func clearUserCredentials(){
        userDefault.removeObject(forKey: "userNameCreden")
        userDefault.removeObject(forKey: "passwordCreden")
    }
}

struct User {
    var userID: Int?
    var userName, fullName, displayName, emailAddr, email, phone: String?
    var balance: Double?
    var profileID: Int?
    var srvName: String?
    var unitPrice: Double?
    var created: String?
    
    init() {
        self.userID = 0
        self.userName = ""
        self.fullName = ""
        self.displayName = ""
        self.emailAddr = ""
        self.email = ""
        self.phone = ""
        self.balance = 0.0
        self.profileID = 0
        self.srvName = ""
        self.unitPrice = 0.0
        self.created = ""
    }
    
    init(userID: Int?, userName: String?,
         fullName: String?, displayName: String?,
         emailAddr: String?, email: String?,
         phone: String?, balance: Double?,
         profileID: Int?, srvName: String?,
         unitPrice: Double?, created: String?) {
        
        self.userID = userID
        self.userName = userName
        self.fullName = fullName
        self.displayName = displayName
        self.emailAddr = emailAddr
        self.email = email
        self.phone = phone
        self.balance = balance
        self.profileID = profileID
        self.srvName = srvName
        self.unitPrice = unitPrice
        self.created = created
    }
}

struct UserCredentials {
    var userName: String
    var password: String
    
    init(userName: String, password: String) {
        self.userName = userName
        self.password = password
    }
}
