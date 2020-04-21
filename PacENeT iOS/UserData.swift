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
    @Published var selectedTabItem = 0
    @Published var isLoggedIn = false
    @Published var shouldShowSplash = true
}

struct UserLocalStorage {
    private static let userDefault = UserDefaults.standard
    
    static func saveLoggedUserData(loggedUserData: LoggedUserData) {
        let encoder = JSONEncoder()
        if let encodedUserData = try? encoder.encode(loggedUserData) {
            userDefault.set(encodedUserData, forKey: "loggedUserData")
        }
    }
    
    static func getLoggedUserData() -> LoggedUserData? {
        var loggedUserData: LoggedUserData? = nil
        if let userData = userDefault.object(forKey: "loggedUserData") as? Data {
            let decoder = JSONDecoder()
            if let decodedUserData = try? decoder.decode(LoggedUserData.self, from: userData) {
                loggedUserData = decodedUserData
            }
        }
        return loggedUserData
    }
    
    static func clearLoggedUserData(){
        userDefault.removeObject(forKey: "loggedUserData")
    }
    
    static func saveUserCredentials(userCredentials: UserCredentials) {
        let encoder = JSONEncoder()
        if let encodedLoggedUser = try? encoder.encode(userCredentials.loggedUser) {
            userDefault.set(userCredentials.userName, forKey: "userNameCreden")
            userDefault.set(userCredentials.password, forKey: "passwordCreden")
            userDefault.set(encodedLoggedUser, forKey: "loggedUserCreden")
        }
    }
    
    static func getUserCredentials() -> UserCredentials {
        var loggedUser: LoggedUser? = nil
        if let decodedLoggedUser = userDefault.object(forKey: "loggedUserCreden") as? Data {
            let decoder = JSONDecoder()
            if let loadedLoggedUser = try? decoder.decode(LoggedUser.self, from: decodedLoggedUser) {
                loggedUser = loadedLoggedUser
            }
        }
        return UserCredentials(userName: userDefault.value(forKey: "userNameCreden") as? String ?? "", password: userDefault.value(forKey: "passwordCreden") as? String ?? "", loggedUser: loggedUser)
    }
    
    static func clearUserCredentials(){
        userDefault.removeObject(forKey: "userNameCreden")
        userDefault.removeObject(forKey: "passwordCreden")
        userDefault.removeObject(forKey: "loggedUserCreden")
    }
}

struct UserCredentials {
    let userName: String
    let password: String
    let loggedUser: LoggedUser?
    
    init(userName: String, password: String, loggedUser: LoggedUser?) {
        self.userName = userName
        self.password = password
        self.loggedUser = loggedUser
    }
}
