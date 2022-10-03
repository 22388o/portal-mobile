//
//  TextFieldAlert.swift
//  BDKDemoApp
//
//  Created by farid on 10/3/22.
//

import Combine
import SwiftUI

struct TextFieldAlert {
    // MARK: Properties
    let title: String
    let message: String?
    let onAcionButton: (String?) -> ()
    @Binding var text: String?
    var isPresented: Binding<Bool>? = nil
    
    // MARK: Modifiers
    func dismissable(_ isPresented: Binding<Bool>) -> TextFieldAlert {
        TextFieldAlert(title: title, message: message, onAcionButton: onAcionButton, text: $text, isPresented: isPresented)
    }
}

extension TextFieldAlert: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = TextFieldAlertViewController
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<TextFieldAlert>) -> UIViewControllerType {
        TextFieldAlertViewController(title: title, message: message, text: $text, onAcionButton: onAcionButton, isPresented: isPresented)
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType,
                                context: UIViewControllerRepresentableContext<TextFieldAlert>) {
        // no update needed
    }
}
