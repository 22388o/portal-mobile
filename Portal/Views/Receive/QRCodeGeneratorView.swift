//
//  QRCodeGeneratorView.swift
// Portal
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import PortalUI

struct QRCodeGeneratorView: View {
    let rootView: Bool
    
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject private var navigation: NavigationStack
    @ObservedObject var viewModel: ReceiveViewModel
    
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
                                VStack {
                                    Text("Address type")
                                        .font(.Main.fixed(.monoRegular, size: 14))
                                        .foregroundColor(Palette.grayScale6A)
                                    Text("Segwit")
                                        .font(.Main.fixed(.monoBold, size: 16))
                                        .foregroundColor(Palette.grayScaleCA)
                                }
                            }
                        }
                        .padding(.horizontal, 40)
                        .padding(.bottom, 16)
                        
                        if let qr = viewModel.qrCode {
                            ZStack {
                                Image(uiImage: qr)
                                    .interpolation(.none)
                                    .resizable()
                                    .cornerRadius(12)
                                
                                Asset.portalQrIcon
                                    .resizable()
                                    .frame(width: 72, height: 72)
                            }
                            .frame(width: geo.size.width - 80)
                            .frame(height: geo.size.width - 80)
                        } else {
                            ProgressView().progressViewStyle(.circular)
                        }
                        
                        VStack(spacing: 10) {
                            Text(viewModel.receiveAddress)
                                .font(.Main.fixed(.monoRegular, size: 14))
                            
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
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                if viewModel.editingAmount, let exchanger = viewModel.exchanger {
                    AmountEditorView(title: "Add Amount", exchanger: exchanger) {
                        withAnimation {
                            viewModel.editingAmount.toggle()
                        }
                    } onSaveAction: { amount in
                        withAnimation {
                            viewModel.editingAmount.toggle()
                        }
                    }
                    .cornerRadius(8)
                    .offset(y: 5)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                } else if viewModel.editingDescription {
                    TextEditorView(
                        title: "Description",
                        placeholder: "Write a payment description",
                        initialText: viewModel.description,
                        onCancelAction: {
                            withAnimation {
                                viewModel.editingDescription.toggle()
                            }
                        }, onSaveAction: { description in
                            withAnimation {
                                viewModel.description = description
                                viewModel.editingDescription.toggle()
                            }
                        }
                    )
                    .cornerRadius(8)
                    .offset(y: 5)
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
                }
            }
        }
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .sheet(item: $viewModel.sharedAddress) { address in
            ActivityShareView(text: address.text)
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
                }
            }
        }
    }
    
    private func DescriptionView() -> some View {
        Group {
            if viewModel.description.isEmpty {
                Button {
                    withAnimation {
                        viewModel.editingDescription.toggle()
                    }
                } label: {
                    HStack {
                        PButton(config: .labelAndIconLeft(label: "Add Description", icon: Asset.pencilIcon), style: .free, size: .small, applyGradient: true, enabled: true) {
                            withAnimation {
                                viewModel.editingDescription.toggle()
                            }
                        }
                        .frame(width: 170)
                        
                        Spacer()
                    }
                    .frame(height: 62)
                    .padding(.horizontal, 24)
                }
            } else {
                Button {
                    withAnimation {
                        viewModel.editingDescription.toggle()
                    }
                } label: {
                    EditableTextFieldView(description: "Description", text: viewModel.description)
                }
            }
        }
    }
}

struct QRCodeGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        QRCodeGeneratorView(rootView: true, viewModel: ReceiveViewModel.mocked)
    }
}