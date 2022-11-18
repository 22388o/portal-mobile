//
//  ReviewTransactionView.swift
// Portal
//
//  Created by farid on 26/8/22.
//

import SwiftUI
import PortalUI
import Factory
import BitcoinDevKit

struct ReviewTransactionView: View {
    @FocusState private var isFocused: Bool
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var viewModel: SendViewViewModel = Container.sendViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text("Recipient")
                    .font(.Main.fixed(.monoBold, size: 14))
                    .foregroundColor(Palette.grayScaleAA)
                
                Text(viewModel.to)
                    .font(.Main.fixed(.monoRegular, size: 16))
                    .foregroundColor(Palette.grayScaleF4)
            }
            .padding(.vertical, 16)
            
            Divider()
            
            Button {
                withAnimation {
                    viewModel.editingAmount.toggle()
                }
            } label: {
                ZStack(alignment: .trailing) {
                    VStack {
                        HStack(alignment: .top, spacing: 16) {
                            Text("Amount")
                                .font(.Main.fixed(.monoBold, size: 14))
                                .foregroundColor(Palette.grayScaleAA)
                            
                            Spacer()
                            
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                VStack(alignment: .trailing, spacing: 6) {
                                    Text(viewModel.exchanger.baseAmount.value)
                                        .font(.Main.fixed(.monoBold, size: 32))
                                        .foregroundColor(viewModel.exchanger.amountIsValid ? Palette.grayScaleEA : Color(red: 1, green: 0.349, blue: 0.349))
                                        .frame(height: 26)
                                    
                                    Text(viewModel.exchanger.quoteAmount.value)
                                        .font(.Main.fixed(.monoMedium, size: 16))
                                        .foregroundColor(Palette.grayScale6A)
                                    
                                }
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(viewModel.exchanger.base.code.lowercased())
                                        .font(.Main.fixed(.monoRegular, size: 18))
                                        .foregroundColor(Palette.grayScale6A)
                                    
                                    Text(viewModel.exchanger.quote.code.lowercased())
                                        .font(.Main.fixed(.monoMedium, size: 12))
                                        .foregroundColor(Palette.grayScale6A)
                                }
                                .padding(.bottom, 2)
                            }
                        }
                        
                        if !viewModel.exchanger.amountIsValid {
                            HStack(spacing: 6) {
                                Spacer()
                                Text("Not enough funds.")
                                    .font(.Main.fixed(.monoMedium, size: 12))
                                Text("Tap to Edit")
                                    .font(.Main.fixed(.monoSemiBold, size: 12))
                            }
                            .foregroundColor(Color(red: 1, green: 0.349, blue: 0.349))
                        }
                    }
                    .padding(.vertical, 16)
                    
                    Asset.chevronRightIcon
                        .foregroundColor(Palette.grayScale4A)
                        .offset(x: 18)
                }
            }
            
            Divider()
            
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Fees")
                        .font(.Main.fixed(.monoBold, size: 14))
                        .foregroundColor(Palette.grayScaleAA)
                    Text(viewModel.fee.description)
                        .font(.Main.fixed(.monoRegular, size: 14))
                        .foregroundColor(Color(red: 0.191, green: 0.858, blue: 0.418))
                }
                
                Spacer()
                
                if let fees = viewModel.recomendedFees {
                    VStack {
                        HStack(spacing: 6) {
                            Text((Double(fees.fee(viewModel.fee))/100_000_000).formattedString(.btc, decimals: 8))
                                .font(.Main.fixed(.monoBold, size: 16))
                                .foregroundColor(Palette.grayScaleEA)
                            
                            Text("btc/vByte")
                                .font(.Main.fixed(.monoMedium, size: 11))
                                .foregroundColor(Palette.grayScale6A)
                                .frame(width: 34)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                } else {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            .padding(.vertical, 16)
            
            Divider()
            
            Spacer()
            
            NavigationLink(
                destination:
                    TransactionDetailsView(
                        coin: .bitcoin(),
                        tx: viewModel.unconfirmedTx != nil ? viewModel.unconfirmedTx! : BitcoinDevKit.TransactionDetails.mockedConfirmed
                    ),
                isActive: $viewModel.txSent
            ) {
                EmptyView()
            }
        }
        .navigationBarHidden(true)
    }
}

struct ReviewTransactionView_Previews: PreviewProvider {
    static var previews: some View {
        let _ = Container.sendViewModel.register { SendViewViewModel.mocked }
        ReviewTransactionView()
            .padding(.top, 40)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}