//
//  SupportTicketDetail.swift
//  PacENeT iOS
//
//  Created by Md. Yamin on 4/9/20.
//  Copyright © 2020 royalgreen. All rights reserved.
//

import SwiftUI

struct SupportTicketDetail: View {
    @ObservedObject var viewModel: SupportViewModel
    @State var item: SupportTicket
    @State var newMessage = ""
    @State var textFieldHeight: CGFloat = 30
    @State var showChoise = false
    @State var showChoiseBackGround = false
    var options = ["Camera", "Gallery", "File"]
    @State private var selectedOption = 0
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var image: Image?
    @State private var imageName: String?
    @State private var imageSize: String?
    @State private var showLoader = false
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                List(viewModel.ticketDetailList, id: \.ispTicketConversationId) { dataItem in
                    if dataItem.ispUserId != nil && dataItem.ispUserId != 0 {
                        HStack {
                            Spacer()
                            Text("\(dataItem.ticketComment ?? "")")
                                .foregroundColor(.white)
                                .padding()
                                .background(ChatBubble(fillColor: .blue, topLeft: 10, topRight: 10, bottomLeft: 10, bottomRight: 2))
                                .scaleEffect(x: 1, y: -1, anchor: .center)
                                .padding(.leading, 60)
                        }
                    } else {
                        HStack {
                            Text("\(dataItem.ticketComment ?? "")")
                                .foregroundColor(.white)
                                .padding()
                                .background(ChatBubble(fillColor: .green, topLeft: 2, topRight: 10, bottomLeft: 10, bottomRight: 10))
                                .scaleEffect(x: 1, y: -1, anchor: .center)
                                .padding(.trailing, 60)
                            Spacer()
                        }
                    }
                }
                .navigationBarTitle(Text("Conversation"), displayMode: .inline)
                .scaleEffect(x: 1, y: -1, anchor: .center)
                .offset(x: 0, y: 1)
                .onAppear {
                    self.viewModel.getTicketDetail(ispTicketId: self.item.ispTicketId ?? 0)
                }
                
                Divider().padding(.top, 16)
                
                if image != nil {
                    HStack {
                        image?.resizable().frame(width: 50, height: 40).scaledToFit()
                        VStack(alignment: .leading) {
                            Text(imageName ?? "Unknown")
                                .lineLimit(1).font(.callout)
                            Text("Size: \(imageSize ?? "N/A")").font(.caption).foregroundColor(.gray)
                        }
                        Spacer()
                        Button(action: {
                            if self.viewModel.choosenImage != nil {
                                self.viewModel.choosenImage = nil
                                self.inputImage = nil
                                self.image = nil
                                self.imageName = nil
                                self.imageSize = nil
                            }
                        }) {
                            Image(systemName: "multiply.circle.fill")
                            .font(.system(size: 18, weight: .regular))
                            .imageScale(.large)
                            .foregroundColor(.gray)
                        }
                    }.padding(.leading, 12).padding(.trailing, 12).padding(.top, 12)
                }

                HStack(spacing: 0) {
                    Button(action: {
                        print("Attachment")
                        withAnimation {
                            if self.showChoise == false && self.viewModel.choosenImage == nil {
                                self.showChoise = true
                            }
                        }
                    }) {
                        Image(systemName: "paperclip")
                        .rotationEffect(Angle(degrees: -45), anchor: .center)
                        .font(.system(size: 18, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.blue)
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                    MultilineTextField(hint: "message", text: self.$newMessage, minHeight: self.textFieldHeight, maxHeight: 100, heightThatFits: self.$textFieldHeight)
                        .frame(minHeight: self.textFieldHeight, maxHeight: self.textFieldHeight)
                        .padding(.leading, 0)
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    Button(action: {
                        if self.newMessage != "" {
                            self.viewModel.sendNewMessage(newMessage: self.newMessage, ispTicketId: self.item.ispTicketId ?? 0)
                            self.newMessage = ""
                        }
                    }) {
                        Image(systemName: "paperplane.fill")
                        .rotationEffect(Angle(degrees: 45), anchor: .center)
                        .font(.system(size: 18, weight: .regular))
                        .imageScale(.large)
                        .foregroundColor(.blue)
                        .padding(.leading, 0)
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 16)
                    }
                }.onReceive(self.viewModel.showLoader.receive(on: RunLoop.main)) { shouldShow in
                    self.showLoader = shouldShow
                }
            }.modifier(ViewModifierOnKeyboardAppear())
            
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
                        
                        Picker(selection: $selectedOption, label: Text("From:")) {
                                ForEach(0 ..< options.count) {
                                    Text(self.options[$0])
                                    
                                }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .padding(.bottom, 40)
                    }
                    .background(ChatBubble(fillColor: .white, topLeft: 10, topRight: 10, bottomLeft: 0, bottomRight: 0))
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
            if self.showLoader {
                SpinLoaderView()
            }
        }.onDisappear() {
            self.viewModel.choosenImage = nil
        }
        .onAppear {
            UITableView.appearance().tableFooterView = UIView()
            UITableView.appearance().separatorStyle = .none
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: saveImage) {
            ImagePicker(image: self.$inputImage, imageName: self.$imageName)
        }
    }
    
    func saveImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)

        if let jpegData = inputImage.jpegData(compressionQuality: 0), let imageName = imageName {
            imageSize = "\(Double(jpegData.count) / 1000.0) KB"
            viewModel.choosenImage = ImageData(image: jpegData, name: imageName, size: imageSize ?? "N/A")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Environment(\.presentationMode) var presentationMode
    @Binding var image: UIImage?
    @Binding var imageName: String?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let fileUrl = info[.imageURL] as? URL {
                parent.imageName = fileUrl.lastPathComponent // get file Name
                print(fileUrl.pathExtension) // get file extension
            }
            
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        // User cancelled image selection
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct MultilineTextField: UIViewRepresentable {
    @Binding var text: String
    var hint: String = ""
    var minHeight: CGFloat
    var maxHeight: CGFloat
    @Binding var heightThatFits: CGFloat
    
    init(hint: String, text: Binding<String>, minHeight: CGFloat, maxHeight: CGFloat, heightThatFits: Binding<CGFloat>) {
        self.hint = hint
        self._text = text
        self.minHeight = minHeight
        self.maxHeight = maxHeight
        self._heightThatFits = heightThatFits
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal) // Prevent from shrinking horizontally
        view.delegate = context.coordinator
        view.backgroundColor = UIColor(white: 0.0, alpha: 0.025)
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor.tertiaryLabel.cgColor
        view.font = UIFont.systemFont(ofSize: 16.0, weight: .light)
        view.layer.cornerRadius = 6
        view.isScrollEnabled = true
        view.isEditable = true
        view.isUserInteractionEnabled = true
        view.text = hint
        view.textColor = UIColor.lightGray
        return view
    }

    func resizeHeightToFit(view: UIView) {
        let requiredHeight = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        if requiredHeight > minHeight && requiredHeight <= maxHeight && $heightThatFits.wrappedValue != requiredHeight {
            DispatchQueue.main.async { // Publish updated value through main thread
                self.$heightThatFits.wrappedValue = requiredHeight
            }
        } else if requiredHeight <= minHeight && $heightThatFits.wrappedValue != minHeight {
            DispatchQueue.main.async { // Publish updated value through main thread
                self.$heightThatFits.wrappedValue = self.minHeight
            }
        }
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != self.text && uiView.textColor != UIColor.lightGray {
            uiView.text = self.text
        }
        resizeHeightToFit(view: uiView)
    }
    
    class Coordinator : NSObject, UITextViewDelegate {
        
        var parent: MultilineTextField
        
        init(_ uiTextView: MultilineTextField) {
            self.parent = uiTextView
        }
        
        func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
            if textView.textColor == UIColor.lightGray {
                 textView.text = ""
                 textView.textColor = UIColor.black
             }
            return true
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // For multistage text input (e.g. Chinese, Japanese)
            if textView.markedTextRange == nil {
                parent.text = textView.text ?? String()
            } else {
                self.parent.text = textView.text
            }
            parent.resizeHeightToFit(view: textView)
        }
    }
}

struct ChatBubble: View {
    var fillColor: Color = .blue
    var topLeft: CGFloat = 0.0
    var topRight: CGFloat = 0.0
    var bottomLeft: CGFloat = 0.0
    var bottomRight: CGFloat = 0.0

    var body: some View {
        GeometryReader { geometry in
            Path { path in

                let width = geometry.size.width
                let height = geometry.size.height

                // You can not exceed view boundary
                let topRight = min(min(self.topRight, height/2), width/2)
                let topLeft = min(min(self.topLeft, height/2), width/2)
                let bottomLeft = min(min(self.bottomLeft, width/2), width/2)
                let bottomRight = min(min(self.bottomRight, height/2), width/2)

                // Start point of the shape
                path.move(to: CGPoint(x: width / 2.0, y: 0))
                // Add top straight Line
                path.addLine(to: CGPoint(x: width - topRight, y: 0))
                // Add topRight rounding curve
                path.addArc(center: CGPoint(x: width - topRight, y: topRight), radius: topRight, startAngle: Angle(degrees: -90), endAngle: Angle(degrees: 0), clockwise: false)
                // Add right side straight line
                path.addLine(to: CGPoint(x: width, y: height - bottomRight))
                // Add bottomRight rounding curve
                path.addArc(center: CGPoint(x: width - bottomRight, y: height - bottomRight), radius: bottomRight, startAngle: Angle(degrees: 0), endAngle: Angle(degrees: 90), clockwise: false)
                // Add bottom straight line
                path.addLine(to: CGPoint(x: bottomLeft, y: height))
                // Add bottomLeft rounding curve
                path.addArc(center: CGPoint(x: bottomLeft, y: height - bottomLeft), radius: bottomLeft, startAngle: Angle(degrees: 90), endAngle: Angle(degrees: 180), clockwise: false)
                // Add left side straight line
                path.addLine(to: CGPoint(x: 0, y: topLeft))
                // Add topLeft rounding curve
                path.addArc(center: CGPoint(x: topLeft, y: topLeft), radius: topLeft, startAngle: Angle(degrees: 180), endAngle: Angle(degrees: 270), clockwise: false)
            }
            .fill(self.fillColor)
        }
    }
}

//struct SupportTicketDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        SupportTicketDetail()
//    }
//}
