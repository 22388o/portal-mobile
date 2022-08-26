//
//  SendFromView.swift
//  BDKDemoApp
//
//  Created by farid on 7/25/22.
//

import SwiftUI
import Combine
import PortalUI
import Factory

struct SendFromView: View {
    @Binding var item: QRCodeItem?
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel = Container.sendViewModel()
    
    init(qrItem: Binding<QRCodeItem?>) {
        UITableView.appearance().backgroundColor = .clear
        self._item = qrItem
    }
    
    var body: some View {
        ZStack {
            Color(red: 10/255, green: 10/255, blue: 10/255).ignoresSafeArea()
            
            VStack(spacing: 0) {
                ZStack {
                    HStack {
                        PButton(config: .onlyIcon(Asset.xIcon), style: .free, size: .big, enabled: true) {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .frame(width: 20)
                        
                        Spacer()
                    }
                    
                    Text("Send")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .frame(height: 62)
                }
                
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                        
                        ScrollView {
                            VStack {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.walletItems) { item in
                                        WalletItemView(item: item)
                                            .padding(.horizontal)
                                            .contentShape(Rectangle())
                                            .onTapGesture {
                                                withAnimation {
                                                    viewModel.selectedItem = item
                                                }
                                            }
                                        Divider()
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color(red: 42/255, green: 42/255, blue: 42/255), lineWidth: 1)
                                )
                            }
                        }
                        .frame(height: CGFloat(viewModel.walletItems.count) * 68)
                        
                        NavigationLink(
                            destination: SendView(viewModel: viewModel),
                            isActive: $viewModel.goToSend
                        ) {
                            EmptyView()
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
        }
        .navigationBarHidden(true)
//        .onAppear {
//            print(item)
//            viewModel.set(item: item)
//        }
        .alert(isPresented: $viewModel.showSuccessAlet) {
            Alert(title: Text("\(viewModel.amount) sat sent!"),
                  message: Text("to: \(viewModel.to)"),
                  dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(title: Text("Send error"),
                  message: Text("\(viewModel.sendError.debugDescription)"),
                  dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $viewModel.qrScannerOpened, onDismiss: {
            
        }) {
            QRCodeScannerView { item in
                viewModel.qrCodeItem = item
                
                switch item.type {
                case .bip21(let address, let amount, _):
                    viewModel.to = address
                    guard let _amount = amount else { return }
                    viewModel.amount = _amount
                default:
                    break
                }
            }
        }
    }
}

struct SendFromView_Previews: PreviewProvider {
    static var previews: some View {
        SendFromView(qrItem: .constant(nil))
            .environmentObject(AccountViewModel.mocked())
    }
}