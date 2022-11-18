//
//  QRCodeReaderView.swift
// Portal
//
//  Created by farid on 8/29/22.
//

import SwiftUI
import Factory

enum QRScannerConfig {
    case send(Coin), universal
}

struct QRCodeReaderView: View {
    @State private var goToSend = false
    
    @Environment(\.presentationMode) private var presentation
    private(set) var completion: (QRCodeItem) -> ()
    private let config: QRScannerConfig
    
    init(config: QRScannerConfig, block: @escaping (QRCodeItem) -> () = { _ in } ) {
        self.config = config
        completion = block
    }
    
    var body: some View {
        NavigationView {
            VStack {
                QRCodeScannerView(config: config) { item in
                    switch config {
                    case .universal:
                        let vm = Container.sendViewModel()
                        vm.qrCodeItem = item
                        goToSend.toggle()
                    case .send:
                        completion(item)
                        presentation.wrappedValue.dismiss()
                    }
                } onClose: {
                    presentation.wrappedValue.dismiss()
                }
                
                NavigationLink(
                    destination: SendView(),
                    isActive: $goToSend
                ) {
                    EmptyView()
                }
            }
        }
        .navigationBarHidden(true)
    }
}