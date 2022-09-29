//
//  ReceiveView.swift
//  BDKDemoApp
//
//  Created by farid on 7/22/22.
//

import SwiftUI
import PortalUI

struct ReceiveView: View {
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject var viewModel: ReceiveViewModel
    
    init(coin: Coin) {
        viewModel = ReceiveViewModel.config(coin: coin)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                HStack {
                    PButton(config: .onlyIcon(Asset.caretLeftIcon), style: .free, size: .medium, enabled: true) {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .frame(width: 20)
                    
                    Spacer()
                }
                
                Text("Receive")
                    .font(.Main.fixed(.monoBold, size: 16))
                    .foregroundColor(Color(red: 1, green: 1, blue: 1))
                    .frame(height: 62)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Account/Asset")
                    .font(.Main.fixed(.monoBold, size: 16))
                HStack(spacing: 6) {
                    Asset.btcIcon
                        .resizable()
                        .frame(width: 16, height: 16)
                    Text("Bitcoin")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Color(red: 1, green: 1, blue: 1))
                    
                    HStack(spacing: 6) {
                        Text("on")
                            .font(.Main.fixed(.monoMedium, size: 14))
                        Asset.chainIcon
                        Text("Chain")
                            .font(.Main.fixed(.monoMedium, size: 14))
                        Spacer()
                    }
                    .foregroundColor(Palette.grayScale6A)
                }
                .padding(15)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Palette.grayScale1A)
                )
                
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay {
                            Image(uiImage: viewModel.qrCode)
                                .interpolation(.none)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 250, height: 250)
                        }
                        .frame(width: 260, height: 260)
                        .padding(.top, 24)
                        .padding(.horizontal, 55)
                        .padding(.bottom, 16)
                    
                    Asset.portalQrIcon
                        .resizable()
                        .frame(width: 65, height: 65)
                }
                
                Text(viewModel.receiveAddress.groupedByThreeFromLeft.uppercased())
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .padding(.horizontal, 55)
                
                Spacer()
                
                HStack(spacing: 8) {
                    PButton(config: .onlyLabel("Share"), style: .filled, size: .big, enabled: true) {
                        
                    }
                    PButton(config: .onlyLabel("Copy"), style: .filled, size: .big, enabled: true) {
                        viewModel.copyToClipboard()
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .navigationBarHidden(true)
        .filledBackground(BackgroundColorModifier(color: Palette.grayScale0A))
        .onAppear(perform: {
            viewModel.generateQRCode()
        })
    }
}

struct ReceiveView_Previews: PreviewProvider {
    static var previews: some View {
        ReceiveView(coin: .bitcoin())
    }
}
