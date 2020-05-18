//
//  LoginViewModel.swift
//  Pace Cloud
//
//  Created by rgl on 7/10/19.
//  Copyright © 2019 royalgreen. All rights reserved.
//

import Foundation
import Combine

class LoginViewModel: NSObject, ObservableObject, URLSessionTaskDelegate {
    //For login
    @Published var username: String = ""
    @Published var password: String = ""
    
    //For signup
//    @Published var firstName: String = ""
//    @Published var lastName: String = ""
//    @Published var email: String = ""
//    @Published var mobile: String = ""
//    @Published var signUpPassword: String = ""
//    @Published var signUpConfPassword: String = ""
//    @Published var companyName = ""
    
//    @Published var showSignupModal = false {
//        willSet {
//            signUpModalValuePublisher.send(newValue)
//        }
//    }
//    var signUpModalValuePublisher = PassthroughSubject<Bool, Never>()
    
    private var loginSubscriber: AnyCancellable? = nil
//    private var signupSubscriber: AnyCancellable? = nil
//    private var numberInputChecker: AnyCancellable!
//    private var validMobileDigits = CharacterSet(charactersIn: "1234567890+")
    
    var showLoginLoader = PassthroughSubject<Bool, Never>()
    var loginStatusPublisher = PassthroughSubject<Bool, Never>()
    var errorToastPublisher = PassthroughSubject<(Bool, String), Never>()
    var successToastPublisher = PassthroughSubject<(Bool, String), Never>()
    
    let config = URLSessionConfiguration.default
    
    var session: URLSession {
        get {
            config.timeoutIntervalForResource = 5
            config.waitsForConnectivity = true
            return URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue());
        }
    }
    
//    var validatedUsername: AnyPublisher<Bool, Never> {
//        return $username
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { username in
////                print("username called and value is: \(username)")
//                guard !username.isEmpty else { return false }
//                return true
//            }
//            .eraseToAnyPublisher()
//    }
//    
//    var validatedPassword: AnyPublisher<Bool, Never> {
//        return $password
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { password in
////                print("password called and value is: \(password)")
//                guard !password.isEmpty else { return false }
//                return true
//            }
//            .eraseToAnyPublisher()
//    }
    
    var validatedCredentials: AnyPublisher<Bool, Never> {
        return Publishers.CombineLatest($username, $password)
            .debounce(for: 0.2, scheduler: RunLoop.main)
            .receive(on: RunLoop.main) // <<—— run on main thread
            .map { username, password in
                guard !username.isEmpty, !password.isEmpty else { return false }
                return true
        }
        .eraseToAnyPublisher()
    }
    
//    var validatedFirstName: AnyPublisher<String?, Never> {
//        return $firstName
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { firstName in
////                print("firstname called")
//                let regexPattern = "^(?=[A-Za-z]).*"
//                let range = firstName.range(of: regexPattern, options: .regularExpression)
//                if firstName.isEmpty {
//                    return "~empty~"
//                } else if range == nil {
//                    return nil
//                } else {
//                    return firstName
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedLastName: AnyPublisher<String?, Never> {
//        return $lastName
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { lastName in
//                let regexPattern = "^(?=[A-Za-z]).*"
//                let range = lastName.range(of: regexPattern, options: .regularExpression)
//                if lastName.isEmpty {
//                    return "~empty~"
//                } else if range == nil {
//                    return nil
//                } else {
//                    return lastName
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedFirstNameAndLastName: AnyPublisher<(String, String)?, Never> {
//        return Publishers.CombineLatest(validatedFirstName, validatedLastName)
//            .map { validatedFirstName, validatedLastName in
//                guard let firstName = validatedFirstName, let lastName = validatedLastName, firstName != "~empty~", lastName != "~empty~" else { return nil }
//                return (firstName, lastName)
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedMobile: AnyPublisher<String?, Never> {
//        return $mobile
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { mobile in
//                let regexPattern = "^(?=\\d)\\d{11}(?!\\d)"
//                let range = mobile.range(of: regexPattern, options: .regularExpression)
//                if mobile.isEmpty {
//                    return "~empty~"
//                } else if range == nil {
//                    return nil
//                } else {
//                    return mobile
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedEmail: AnyPublisher<String?, Never> {
//        return $email
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { email in
//                let regexPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{1,64}"
//                let range = email.range(of: regexPattern, options: .regularExpression)
//                if email.isEmpty {
//                    return "~empty~"
//                } else if range == nil {
//                    return nil
//                } else {
//                    return email
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedSignupPassword: AnyPublisher<String?, Never> {
//        return $signUpPassword
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { password in
//                if password.isEmpty {
//                    return "~empty~"
//                } else {
//                    return password
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedConfSignupPassword: AnyPublisher<String?, Never> {
//        return $signUpConfPassword
//            .debounce(for: 0.2, scheduler: RunLoop.main)
//            .removeDuplicates()
//            .map { confirmPassword in
//                if confirmPassword.isEmpty {
//                    return "~empty~"
//                } else {
//                    return confirmPassword
//                }
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var validatedBothSignupPassword: AnyPublisher<String?, Never> {
//        return Publishers.CombineLatest(validatedSignupPassword, validatedConfSignupPassword)
//            .receive(on: RunLoop.main) // <<—— run on main thread
//            .map { validatedSignupPassword, validatedConfSignupPassword in
//                if validatedSignupPassword == "~empty~" || validatedConfSignupPassword == "~empty~" {
//                    return "~empty~"
//                }
//                guard let password = validatedSignupPassword, let repeatPassword = validatedConfSignupPassword,
//                    password != "~empty~", repeatPassword != "~empty~", password == repeatPassword else { return nil }
////                print("Password: \(password)")
//                return password
//        }
//        .eraseToAnyPublisher()
//    }
//
//    var isSignupFormValid: AnyPublisher<Bool?, Never> {
//        return Publishers.CombineLatest4(validatedFirstNameAndLastName, validatedMobile, validatedEmail, validatedBothSignupPassword)
//            .receive(on: RunLoop.main) // <<—— run on main thread
//            .map { validatedFirstNameAndLastName, validatedMobile, validatedEmail, validatedPassword in
////                print("Name: \(validatedFirstNameAndLastName ?? ("not set", "not set")), Mobile: \(validatedMobile ?? "not set"), Email: \(validatedEmail ?? "not set"), Password: \(validatedPassword ?? "not set")")
//                guard let _ = validatedFirstNameAndLastName, let mobile = validatedMobile,
//                    let email = validatedEmail, let password = validatedPassword, mobile != "~empty~", email != "~empty~", password != "~empty~" else { return nil }
////                print("Name: \(name), Mobile: \(mobile), Email: \(email), Password: \(password)")
//                return true
//
//            }
//            .eraseToAnyPublisher()
//    }
    
//    override init() {
//        super.init()
//        numberInputChecker = $mobile.sink { val in
//            //check if the new string contains any invalid characters
//            if val.rangeOfCharacter(from: self.validMobileDigits.inverted) != nil {
//                //clean the string (do this on the main thread to avoid overlapping with the current ContentView update cycle)
//                DispatchQueue.main.async {
//                    self.mobile = String(self.mobile.unicodeScalars.filter {
//                        self.validMobileDigits.contains($0)
//                    })
//                }
//            }
//        }
//    }
    
    deinit {
//        numberInputChecker.cancel()
        loginSubscriber?.cancel()
//        signupSubscriber?.cancel()
    }
   
    func urlSession(_ session: URLSession, taskIsWaitingForConnectivity task: URLSessionTask) {
        // waiting for connectivity, update UI, etc.
        self.errorToastPublisher.send((true, "Please turn on your internet connection!"))
    }

    func doLogIn() {
        self.loginSubscriber = self.executeLoginApiCall()?
            .sink(receiveCompletion: { completion in
                switch completion {
                    case .finished:
                        break
                    case .failure(let error):
                        self.errorToastPublisher.send((true, error.localizedDescription))
                }
            }, receiveValue: { loginResponse in
                
                if loginResponse.resdata.loggeduser == nil {
                    self.errorToastPublisher.send((true, loginResponse.resdata.message ?? "Something wrong, please try again!"))
                } else {
                    self.loginStatusPublisher.send(true)
                    UserLocalStorage.saveUserCredentials(userCredentials: UserCredentials(userName: self.username, password: self.password, loggedUser: loginResponse.resdata.loggeduser))
                }
            })
    }
    
    func executeLoginApiCall() -> AnyPublisher<LoginResponse, Error>? {
        let jsonObject = ["userName": self.username, "userPass": self.password]
        let jsonArray = [jsonObject]
        if !JSONSerialization.isValidJSONObject(jsonArray) {
            print("Problem in parameter creation...")
            return nil
        }
        
        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
        
        guard let jsonData = tempJson else {
            print("Problem in parameter creation...")
            return nil
        }
        
        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"/api/ispportal/loginportalusers") else {
            print("Problem in UrlComponent creation...")
            return nil
        }
        
        guard let url = urlComponents.url else {
            return nil
        }
        
        //Request type
        var request = getCommonUrlRequest(url: url)
        request.httpMethod = "POST"
        
        //Setting headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //Setting body for POST request
        request.httpBody = jsonData
        
        return session.dataTaskPublisher(for: request)
            .handleEvents(receiveSubscription: { _ in
                self.showLoginLoader.send(true)
            }, receiveOutput: { _ in
                self.showLoginLoader.send(false)
            }, receiveCompletion: { _ in
                self.showLoginLoader.send(false)
            }, receiveCancel: {
                self.showLoginLoader.send(false)
            })
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw NetworkApiService.APIFailureCondition.InvalidServerResponse
                }
            
                return data
        }
        .retry(1)
        .decode(type: LoginResponse.self, decoder: JSONDecoder())
        .receive(on: RunLoop.main)
        .eraseToAnyPublisher()
    }
    
//    func doSignUp() {
//        self.signupSubscriber = self.executeSignupApiCall()?
//            .sink(receiveCompletion: { completion in
//                switch completion {
//                    case .finished:
//                        break
//                    case .failure(let error):
//                        self.errorToastPublisher.send((true, error.localizedDescription))
//                        print(error.localizedDescription)
////                        fatalError(error.localizedDescription)
//                }
//            }, receiveValue: { signupResponse in
////                print(signupResponse)
//                if let resstate = signupResponse.resdata.resstate {
//                    if resstate == true {
//                        self.successToastPublisher.send((true, signupResponse.resdata.message ?? ""))
//                        self.showSignupModal = false
//                    } else {
//                        self.errorToastPublisher.send((true, signupResponse.resdata.message ?? ""))
//                    }
//                }
//            })
//    }
    
//    func executeSignupApiCall() -> AnyPublisher<DefaultResponse, Error>? {
//
//        let jsonObject = ["cloudUserId": 0, "firstName": self.firstName,
//                          "lastName": self.lastName,
//                          "password": self.signUpPassword,
//                          "emailAddr": self.email,
//                          "companyName": self.companyName,
//                          "phoneNumber": "",
//                          "externalId": "",
//                          "amount": 0,
//                          "conpassword": self.signUpConfPassword,
//                          "activationProfileId": 0,
//                          "activationProfileName": "",
//                          "deploystartVM": true,
//                          "username": nil,
//                          "type": nil,
//                          "accountSource": nil  ,
//                          "VmPackage": []] as [String : Any?]
//        let jsonArray = [jsonObject]
//
//        if !JSONSerialization.isValidJSONObject(jsonArray) {
//            print("Problem in parameter creation...")
//            return nil
//        }
//
//        let tempJson = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
//        guard let jsonData = tempJson else {
//            print("Problem in parameter creation...")
//            return nil
//        }
//
//        guard let urlComponents = URLComponents(string: NetworkApiService.webBaseUrl+"register") else {
//            print("Problem in UrlComponent creation...")
//            return nil
//        }
//
//        guard let url = urlComponents.url else {
//            return nil
//        }
//
//        //Request type
//        var request = getCommonUrlRequest(url: url)
//        request.httpMethod = "POST"
//
//        //Setting headers
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        //Setting body for POST request
//        request.httpBody = jsonData
//
//        return URLSession.shared.dataTaskPublisher(for: request)
//            .handleEvents(receiveSubscription: { _ in
//                self.showLoginLoader.send(true)
//            }, receiveOutput: { _ in
//                self.showLoginLoader.send(false)
//            }, receiveCompletion: { _ in
//                self.showLoginLoader.send(false)
//            }, receiveCancel: {
//                self.showLoginLoader.send(false)
//            })
//            .tryMap { data, response -> Data in
//                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//                    throw NetworkApiService.APIFailureCondition.InvalidServerResponse
//                }
//                return data
//        }
//        .retry(1)
//        .decode(type: DefaultResponse.self, decoder: JSONDecoder())
//        .receive(on: RunLoop.main)
//        .eraseToAnyPublisher()
//    }
}
