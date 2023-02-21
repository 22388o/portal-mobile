//
//  QRCodeGeneratorView.swift
// Portal
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import PortalUI
import PopupView

struct QRCodeGeneratorView: View {
    let rootView: Bool
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var navigation: NavigationStack
    @StateObject var viewModel: ReceiveViewModel
    
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    ZStack {
                        HStack {
                            PButton(config: rootView ? .onlyIcon(Asset.xIcon) : .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                                if rootView {
                                    presentationMode.wrappedValue.dismiss()
                                } else {
                                    navigation.pop()
                                }
                            }
                            .frame(width: 20)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 25)
                        
                        Text("Receive")
                            .frame(width: 300, height: 62)
                            .font(.Main.fixed(.monoBold, size: 16))
                    }
                    .animation(nil, value: false)
                    
                    ScrollView {
                        HStack {
                            if let coin = viewModel.selectedItem?.viewModel.coin {
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack(spacing: 8) {
                                        CoinImageView(
                                            size: 24,
                                            url: coin.icon,
                                            placeholderForegroundColor: Color.gray
                                        )
                                        Text(coin.name)
                                            .font(.Main.fixed(.monoBold, size: 22))
                                            .foregroundColor(Palette.grayScaleF4)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            if let coin = viewModel.selectedItem?.viewModel.coin, coin.type == .bitcoin {
                                Button {
                                    viewModel.showNetworkSelector.toggle()
                                } label: {
                                    HStack(spacing: 6.8) {
                                        Asset.helpIcon
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                            .foregroundColor(Palette.grayScale8A)
                                            
                                        Text(viewModel.qrAddressType.title)
                                            .font(.Main.fixed(.monoBold, size: 16))
                                            .foregroundColor(Palette.grayScaleCA)
                                        
                                        Asset.chevronLeftIcon
                                            .resizable()
                                            .frame(width: 5, height: 9)
                                            .foregroundColor(Palette.grayScale8A)
                                            .rotationEffect(.degrees(270))
                                            .padding(.leading, 2)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)
                        
                        if viewModel.qrAddressType == .onChain {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("You’ll need to wait for 3 confirmation, to be able to use these funds.")
                                        .multilineTextAlignment(.leading)
                                        .font(.Main.fixed(.monoBold, size: 12))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                }
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Palette.grayScale4A, lineWidth: 1)
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundColor(Palette.grayScale2A)
                                    }
                                )
                                .padding(.horizontal, 24)
                                
                                HStack {
                                    Text("Send more than 0.00002 BTC and up to 0.039 BTC to this address. A setup fee of 0.4% will be applied for > 0.00086 BTC")
                                        .multilineTextAlignment(.leading)
                                        .font(.Main.fixed(.monoBold, size: 12))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                }
                                .background(
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Palette.grayScale4A, lineWidth: 1)
                                        RoundedRectangle(cornerRadius: 12)
                                            .foregroundColor(Palette.grayScale2A)
                                    }
                                )
                                .padding(.horizontal, 24)
                            }
                            .padding(.bottom, 16)
                        }
                        
                        if let qr = viewModel.qrCode {
                            Image(uiImage: qr)
                                .interpolation(.none)
                                .resizable()
                                .cornerRadius(12)
                                .frame(width: geo.size.width - 80, height: geo.size.width - 80)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                                .frame(width: geo.size.width - 80, height: geo.size.width - 80)
                        }
                        
                        VStack(spacing: 10) {
                            Button {
                                viewModel.showFullQRCodeString.toggle()
                            } label: {
                                Text(viewModel.displayedString)
                                    .multilineTextAlignment(.leading)
                                    .font(.Main.fixed(.monoRegular, size: 14))
                                    .foregroundColor(Palette.grayScaleAA)
                            }
                            
                            HStack(spacing: 10) {
                                PButton(config: .labelAndIconLeft(label: "Copy", icon: Asset.copyIcon), style: .outline, size: .medium, color: Palette.grayScaleEA, enabled: true) {
                                    viewModel.copyToClipboard()
                                }
                                
                                PButton(config: .labelAndIconLeft(label: "Share", icon: Asset.arrowUprightIcon), style: .outline, size: .medium, color: Palette.grayScaleEA, enabled: true) {
                                    viewModel.share()
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.top, 16)
                        .padding(.bottom, 10)
                        
                        VStack(spacing: 0) {
                            Divider()
                                .frame(height: 1)
                            if let exchanger = viewModel.exchanger {
                                AmountView(exchanger: exchanger)
                            }
                            Divider()
                                .frame(height: 1)
                            DescriptionView()
                            Divider()
                                .frame(height: 1)
                            
                            switch viewModel.qrAddressType {
                            case .lightning, .unified:
                                ExpirationView()
                                Divider()
                                    .frame(height: 1)
                            default:
                                EmptyView()
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .sheet(item: $viewModel.sharedAddress) { address in
            ActivityShareView(text: address.text)
        }
        //Confirmation message on copy from clipboard action
        .popup(isPresented: $viewModel.showConfirmationOnCopy) {
            HStack {
                ZStack {
                    Circle()
                        .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                    Asset.checkIcon
                        .resizable()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.black)
                }
                .frame(width: 32, height: 32)
                .padding(.horizontal, 12)
                
                Text("Address copied!")
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(.white)
                Spacer()
            }
            .frame(width: 300, height: 56)
            .background(Color(red: 0.165, green: 0.165, blue: 0.165))
            .cornerRadius(16)
        } customize: {
            $0.autohideIn(2).type(.floater()).position(.top).animation(.spring()).closeOnTapOutside(true)
        }
        //Amount field
        .popup(isPresented: $viewModel.editingAmount) {
            if let exchanger = viewModel.exchanger {
                AmountEditorView(title: "Add Amount", exchanger: exchanger) {
                    viewModel.editingAmount.toggle()
                } onSaveAction: { amount in
                    viewModel.editingAmount.toggle()
                }
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .padding(.bottom, 32)
            } else {
                EmptyView()
            }
        } customize: {
            $0.type(.toast).position(.bottom).closeOnTapOutside(false).backgroundColor(.black.opacity(0.5))
        }
        //Description field
        .popup(isPresented: $viewModel.editingDescription) {
            TextEditorView(
                title: "Description",
                placeholder: "Write a payment description",
                initialText: viewModel.description,
                onCancelAction: {
                    viewModel.editingDescription.toggle()
                }, onSaveAction: { description in
                    withAnimation {
                        viewModel.description = description
                    }
                    viewModel.editingDescription.toggle()
                }
            )
            .cornerRadius(20, corners: [.topLeft, .topRight])
            .padding(.bottom, 32)
        } customize: {
            $0.type(.toast).position(.bottom).closeOnTapOutside(false).backgroundColor(.black.opacity(0.5))
        }
        //Network Selector popup
        .popup(isPresented: $viewModel.showNetworkSelector) {
            QRCodeAddressTypeView(coin: .bitcoin(), addressType: $viewModel.qrAddressType, onDismiss: {
                viewModel.showNetworkSelector.toggle()
            })
        } customize: {
            $0.type(.toast).position(.bottom).closeOnTapOutside(true).backgroundColor(.black.opacity(0.5))
        }
        //QRCodeFullStringView
        .popup(isPresented: $viewModel.showFullQRCodeString) {
            QRCodeFullStringView(
                string: viewModel.receiveAddress,
                addressType: viewModel.qrAddressType,
                onCopy: {
                    viewModel.showFullQRCodeString.toggle()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        viewModel.copyToClipboard()
                    }
                },
                onDismiss: {
                    viewModel.showFullQRCodeString.toggle()
                }
            )
        } customize: {
            $0.type(.toast).position(.bottom).closeOnTapOutside(true).backgroundColor(.black.opacity(0.5))
        }
    }
    
    private func AmountView(exchanger: Exchanger) -> some View {
        Group {
            if exchanger.baseAmountDecimal == 0 {
                Button {
                    withAnimation {
                        viewModel.editingAmount.toggle()
                    }
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Amount", icon: Asset.pencilIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                            withAnimation {
                                viewModel.editingAmount.toggle()
                            }
                        }
                        .frame(width: 125)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                    .padding(.horizontal, 24)
                }
            } else {
                Button {
                    withAnimation {
                        viewModel.editingAmount.toggle()
                    }
                } label: {
                    AmountValueView(exchanger: exchanger)
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                }
            }
        }
    }
    
    private func ExpirationView() -> some View {
        Button {
            viewModel.editingAmount.toggle()
        } label: {
            ZStack(alignment: .trailing) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Expiration")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                    
                    Spacer()
                    
                    Text("23:59:59")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(.white)
                }
                
                Asset.chevronRightIcon
                    .foregroundColor(Palette.grayScale4A)
                    .offset(x: 20)
            }
            .frame(height: 62)
        }
    }
    
    private func DescriptionView() -> some View {
        Group {
            if viewModel.description.isEmpty {
                Button {
                    viewModel.editingDescription.toggle()
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Description", icon: Asset.pencilIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                            viewModel.editingDescription.toggle()
                        }
                        .frame(width: 170)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                    .padding(.horizontal, 24)
                }
            } else {
                Button {
                    viewModel.editingDescription.toggle()
                } label: {
                    EditableTextFieldView(description: "Description", text: viewModel.description)
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                }
            }
        }
    }
}

import Factory

struct QRCodeGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.walletManager.register { WalletManager.mocked }
        let _ = Container.adapterManager.register { AdapterManager.mocked }
        
        QRCodeGeneratorView(rootView: true, viewModel: ReceiveViewModel.mocked)
    }
}