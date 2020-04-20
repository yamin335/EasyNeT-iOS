//
//  SupportTicketEntry.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/11/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct ImageRow: View {
    @State var item: ImageData
    @ObservedObject var viewModel: SupportViewModel
    var body: some View {
        HStack {
            Image(uiImage: UIImage(data: item.data)!).resizable().frame(width: 50, height: 40).scaledToFit()
            VStack(alignment: .leading) {
                Text(item.name)
                    .lineLimit(1).font(.callout)
                Text("Size: \(item.size)").font(.caption).foregroundColor(.gray)
            }
            
            Image(systemName: "multiply.circle.fill")
                .font(.system(size: 18, weight: .regular))
                .imageScale(.large)
                .foregroundColor(.gray)
                .onTapGesture {
                    let firstIndex = self.viewModel.choosenImageList.firstIndex(where: { $0 == self.item })
                    guard let index = firstIndex else {
                        return
                    }
                    self.viewModel.choosenImageList.remove(at: index)
                    self.viewModel.objectWillChange.send(true)
                }
        }
    }
}

struct SupportTicketEntry: View {
    @Environment(\.presentationMode) var presentation
    @State private var selectedOption = 0
    @State private var subject = ""
    @ObservedObject var viewModel: SupportViewModel
    @State var description = ""
    @State var textFieldHeight: CGFloat = 150
    var options = ["Camera", "Gallery", "File"]
    @State private var selectedChoiseOption = 0
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var image: Image?
    @State private var imageName: String?
    @State private var imageSize: String?
    @State private var images = [Image]()
    @State private var imageNames = [String]()
    @State private var imageSizes = [String]()
    @State var showChoise = false
    @State var showChoiseBackGround = false
    
    var submit: some View {
        Button(action: {
            self.viewModel.saveNewTicket(ticketSummary: self.subject, ticketDescription: self.description, ispTicketCategoryId: self.viewModel.ticketCategoryList[self.selectedOption].ispTicketCategoryId)
        }) {
            Text("Submit")
                .foregroundColor(.blue)
        }
    }
    var body: some View {
        ZStack {
            VStack {
                VStack {
                    Picker(selection: $selectedOption, label: Text("Category").frame(minWidth: 75)) {
                        ForEach(self.viewModel.ticketCategoryList, id: \.ispTicketCategoryId) { data in
                            Text(data.ticketCategory ?? "Unknown Category")
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                }.frame(height: 150)
                    .padding(.leading, 20)
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 0) {
                        Text("Subject").font(.headline).padding(.leading, 20)
                        Text("*").font(.headline).foregroundColor(.red)
                    }
                    TextField("Subject", text: $subject)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading, 20).padding(.trailing, 20)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 0) {
                        Text("Description").font(.headline).padding(.leading, 20)
                        Text("*").font(.headline).foregroundColor(.red)
                    }
                    MultilineTextField(hint: "Description in detail", text: self.$description, minHeight: self.textFieldHeight, maxHeight: 200, heightThatFits: self.$textFieldHeight)
                        .frame(minHeight: self.textFieldHeight, maxHeight: self.textFieldHeight)
                        .padding(.leading, 20).padding(.trailing, 20)
                }.padding(.top)
                
                HStack {
                    Button(action: {
                        print("Attachment")
                        withAnimation {
                            if self.showChoise == false && self.viewModel.choosenImage == nil {
                                self.showChoise = true
                            }
                        }
                    }) {
                        HStack {
                            Image(systemName: "paperclip")
                                .rotationEffect(Angle(degrees: -45), anchor: .center)
                                .font(.system(size: 18, weight: .regular))
                                .imageScale(.large)
                                .foregroundColor(.blue)
                                .padding(.leading, 12)
                                .padding(.trailing, 8)
                                .padding(.top, 14)
                                .padding(.bottom, 12)
                            
                            Text("Attach File")
                                .font(.system(size: 16))
                                .font(.body)
                                .foregroundColor(.blue)
                                .padding(.trailing, 16)
                                .padding(.top, 10)
                                .padding(.bottom, 10)
                        }
                        .overlay (
                            RoundedRectangle(cornerRadius: 4, style: .circular)
                                .stroke(Color.gray, lineWidth: 0.5)
                        )
                            .padding(.leading, 20)
                            .padding(.trailing, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 10)
                        
                    }
                    Spacer()
                }
                
                List(self.viewModel.choosenImageList, id: \.self) { item in
                    ImageRow(item: item, viewModel: self.viewModel)
                }
            }
            
            if showChoiseBackGround {
                VStack {
                    Rectangle().background(Color.black).blur(radius: 0.5, opaque: false).opacity(0.3)
                }
                .zIndex(1)
                .transition(.asymmetric(insertion: .opacity, removal: .opacity)).animation(.default)
                .onTapGesture {
                    withAnimation {
                        self.showChoise = false
                        self.showChoiseBackGround = false
                    }
                }
            }
            
            if showChoise {
                VStack() {
                    Spacer()
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation {
                                    if self.showChoise == true {
                                        self.showChoise = false
                                        self.showChoiseBackGround = false
                                    }
                                }
                            }) {
                                Text("Cancel")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.blue)
                                    .padding(.leading, 20)
                            }
                            Spacer()
                            Text("Choose From").font(.title).padding()
                            Spacer()
                            Button(action: {
                                withAnimation {
                                    if self.showChoise == true {
                                        self.showChoise = false
                                        self.showChoiseBackGround = false
                                    }
                                }
                                self.showingImagePicker = true
                            }) {
                                Text("Done")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.blue)
                                    .padding(.trailing, 20)
                            }
                        }
                        
                        Picker(selection: $selectedChoiseOption, label: Text("From:")
                            .frame(minWidth: 100)) {
                                ForEach(0 ..< options.count) {
                                    Text(self.options[$0])
                                    
                                }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                    .background(Color.white)
                }
                .zIndex(2)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .onAppear {
                    withAnimation {
                        self.showChoiseBackGround = true
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom))).animation(.default)
            }
            
        }.onReceive(self.viewModel.newEntryPublisher.receive(on: RunLoop.main)) { value in
            if value {
                self.presentation.wrappedValue.dismiss()
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: saveImage) {
            ImagePicker(image: self.$inputImage, imageName: self.$imageName)
        }
        .navigationBarTitle(Text("New Ticket")).navigationBarItems(trailing: submit)
    }
    func saveImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)

        if let jpegData = inputImage.jpegData(compressionQuality: 0), let imageName = imageName {
            imageSize = "\(Double(jpegData.count) / 1000.0) KB"
            viewModel.choosenImageList.append(ImageData(image: jpegData, name: imageName, size: imageSize ?? "N/A"))
            viewModel.objectWillChange.send(true)
        }
    }
}

struct SupportTicketEntry_Previews: PreviewProvider {
    static var previews: some View {
        SupportTicketEntry(viewModel: SupportViewModel())
    }
}
