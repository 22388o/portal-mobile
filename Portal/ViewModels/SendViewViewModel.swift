//
//  SendViewViewModel.swift
// Portal
//
//  Created by farid on 25/8/22.
//

import Foundation
import Factory
import Combine
import LocalAuthentication.LAError
import SwiftUI
import PortalUI

enum UserInputResult {
    case btcOnChain(address: String), lightningInvoice(amount: String), ethOnChain(address: String)
}

class SendViewViewModel: ObservableObject {
    private var sendService: ISendAssetService?
    private var subscriptions = Set<AnyCancellable>()
    private(set) var walletItems: [WalletItem]  = []
    
    @Published var receiverAddress = String()
    @Published var coin: Coin?
    @Published var qrCodeItem: QRCodeItem?
    @Published var clipboardIsEmpty = false
    @Published var feeRate: TxFees = .normal
    @Published var amountIsValid: Bool = true
    @Published var showFeesPicker = false
    
    @Published private(set) var balanceString = String()
    @Published private(set) var valueString = String()
    @Published private(set) var useAllFundsEnabled = true
    
    @Published private(set) var unconfirmedTx: TransactionRecord?
    @Published private(set) var recomendedFees: RecomendedFees?
    @Published private(set) var exchanger: Exchanger?
    @Published private(set) var sendError: Error?
    @Published var confirmSigning = false

    @Injected(Container.accountViewModel) private var account
    @Injected(Container.marketData) private var marketData
    @Injected(Container.settings) private var settings
    
    var fiatCurrency: FiatCurrency {
        settings.fiatCurrency
    }
    
    var signingTxProtected: Bool {
        settings.pincodeEnabled || settings.biometricsEnabled
    }
        
    var fee: String {
        guard let coin = coin, let recomendedFees = recomendedFees, let sendService = sendService else { return String() }
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            return ((sendService.fee.double)/100_000_000).formattedString(.coin(coin), decimals: 8)
        case .ethereum, .erc20:
            return recomendedFees.fee(feeRate).double.formattedString(.coin(coin), decimals: 8)
        }
    }
    
    var showFees: Bool {
        guard let exchanger = exchanger, amountIsValid else {
            return false
        }
        return exchanger.baseAmountDecimal > 0 && sendService?.fee != 0
    }
    
    init() {
        subscribeForUpdates()
    }
    
    private func subscribeForUpdates() {
        $coin
            .sink { [weak self] newCoin in
                guard let self = self, let coin = newCoin else { return }
                
                self.syncSendService(coin: coin)
                self.syncExchanger(coin: coin)
            }
            .store(in: &subscriptions)
        
        $receiverAddress
            .sink { [unowned self] address in
                self.sendService?.receiverAddress.send(address)
                guard sendError != nil else { return }
                withAnimation {
                    self.sendError = nil
                }
            }
            .store(in: &subscriptions)
        
        account
            .$items
            .sink { items in
                self.walletItems = items
            }
            .store(in: &subscriptions)
        
        marketData
            .onMarketDataUpdate
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self, let sendService = self.sendService, let coin = self.coin else { return }
                
                switch coin.type {
                case .bitcoin:
                    self.valueString = (sendService.balance * self.marketData.lastSeenBtcPrice * self.fiatCurrency.rate).double.usdFormatted()
                case .lightningBitcoin:
                    fatalError("not implemented")
                case .ethereum, .erc20:
                    self.valueString = (sendService.balance * self.marketData.lastSeenEthPrice * self.fiatCurrency.rate).double.usdFormatted()
                }
            }
            .store(in: &subscriptions)
        
        $feeRate
            .sink { [unowned self] rate in
                self.sendService?.feeRateType.send(rate)
            }
            .store(in: &subscriptions)
    }
    
    private func syncExchanger(coin: Coin) {
        let price: Decimal
        
        switch coin.type {
        case .bitcoin, .lightningBitcoin:
            price = marketData.lastSeenBtcPrice
        case .ethereum, .erc20:
            price = marketData.lastSeenEthPrice
        }
        
        exchanger = Exchanger(
            base: coin,
            quote: .fiat(fiatCurrency),
            price: price
        )
        
        guard let exchanger = exchanger, let sendService = self.sendService else { return }
        
        exchanger.$baseAmountDecimal
            .sink { [weak self] amount in
                guard let self = self else { return }
                
                withAnimation {
                    self.amountIsValid = amount <= sendService.spendable
                    self.useAllFundsEnabled = (amount != sendService.spendable)
                }
                
                guard self.amountIsValid, amount > 0, sendService.amount.value != amount else { return }
                sendService.amount.send(amount)
            }
            .store(in: &subscriptions)
    }
    
    private func syncSendService(coin: Coin) {
        let adapterManager: IAdapterManager = Container.adapterManager()
        let walletManager: IWalletManager = Container.walletManager()

        guard
            let wallet = walletManager.activeWallets.first(where: { $0.coin == coin }),
            let adapter = adapterManager.adapter(for: wallet)
        else {
            fatalError("coudn't fetch dependencies")
        }

        switch coin.type {
        case .bitcoin:
            guard let sendAdapter = adapter as? ISendBitcoinAdapter else {
                fatalError("coudn't fetch dependencies")
            }
            
            sendService = SendBTCService(sendAdapter: sendAdapter)
            
            if let service = sendService {
                balanceString = String(describing: service.spendable)
                valueString = (service.balance * marketData.lastSeenBtcPrice * fiatCurrency.rate).double.usdFormatted()
            }
        case .lightningBitcoin:
            fatalError("not implemented yet")
        case .ethereum, .erc20:
            guard let sendAdapter = adapter as? ISendEthereumAdapter else {
                fatalError("coudn't fetch dependencies")
            }
            
            let feeRateProvider = Container.feeRateProvider()
            let ethFeeRateProvider = EthereumFeeRateProvider(feeRateProvider: feeRateProvider)
            
            let ethManager = Container.ethereumKitManager()
            sendService = SendETHService(coin: coin, sendAdapter: sendAdapter, feeRateProvider: ethFeeRateProvider, manager: ethManager)
            
            if let service = sendService {
                balanceString = String(describing: service.spendable)
                valueString = (service.balance * marketData.lastSeenEthPrice * fiatCurrency.rate).double.usdFormatted()
            }
        }
        
        sendService?.recomendedFees.sink { [weak self] fees in
            self?.recomendedFees = fees
        }
        .store(in: &subscriptions)
    }
                
    func validateInput() throws -> UserInputResult {
        guard let sendService = sendService else {
            throw SendFlowError.addressIsntValid
        }
        return try sendService.validateUserInput()
    }
    
    func updateError() {
        sendError = SendFlowError.addressIsntValid
    }
    
    func send() async -> Bool {
        guard let service = sendService else {
            withAnimation {
                self.sendError = SendFlowError.error("Send service is nil")
            }
            return false
        }
        do {
            let transaction = !useAllFundsEnabled ? try await service.sendMax() : try await service.send()
            DispatchQueue.main.async {
                self.unconfirmedTx = transaction
            }
            return true
        } catch {
            withAnimation {
                self.sendError = error
            }
            return false
        }
    }
    
    func clearRecipient() {
        coin = nil
        receiverAddress = String()
        sendError = nil
    }
    
    func clearAmount() {
        exchanger?.amount.string = String()
        useAllFundsEnabled = true
        sendError = nil
    }
        
    func pasteFromClipboard() {
        let pasteboard = UIPasteboard.general
        if let pastboardString = pasteboard.string {
            receiverAddress = pastboardString
        } else {
            clipboardIsEmpty.toggle()
        }
    }
        
    func useAllFunds() {
        guard let sendService = sendService, let exchanger = exchanger else { return }
        let spendable = sendService.spendable
        
        switch exchanger.side {
        case .base:
            exchanger.amount.string = String(describing: spendable)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
                let spendable = sendService.spendable
                exchanger.amount.string = String(describing: spendable)
            }
        case .quote:
            exchanger.amount.string = String(describing: spendable * exchanger.price)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.125) {
                let spendable = sendService.spendable
                exchanger.amount.string = String(describing: spendable * exchanger.price)
            }
        }
    }
    
    func hasAmount(item: QRCodeItem) -> Bool {
        switch item.type {
        case .bip21(let address, let amount, _):
            receiverAddress = address
            if let amount = amount {
                exchanger?.amount.string = amount
                return true
            }
            return false
        case .eth(let address, let amount, _):
            receiverAddress = address
            if let amount = amount {
                exchanger?.amount.string = amount
                return true
            }
            return false
        case .bolt11(let invoice):
            receiverAddress = invoice
            do {
                let result = try validateInput()
                switch result {
                case .lightningInvoice(let amount):
                    exchanger?.amount.string = amount
                    return true
                default:
                    return false
                }
            } catch {
                return false
            }
        default:
            return false
        }
    }
}

extension SendViewViewModel {
    enum SendStep {
        case selectAsset, recipient, amount, review, signing, sent
    }
    
    static var mocked: SendViewViewModel {
        let vm = SendViewViewModel()
        vm.walletItems = [WalletItem.mockedBtc]
        vm.coin = .bitcoin()
        vm.receiverAddress = "tb1q3ds30e5p59x9ryee4e2kxz9vxg5ur0tjsv0ug3"
        vm.balanceString = "0.000124"
        vm.valueString = "12.93"
        vm.exchanger?.amount.string = "0.0000432"
        return vm
    }
}
