//
//  SendETHService.swift
//  Portal
//
//  Created by farid on 1/3/23.
//

import Foundation
import Combine
import BigInt
import EvmKit

class SendETHService: ISendAssetService {
    private let coin: Coin
    private let gasLimitSurchargePercent: Int = 5
    private var transaction: Transaction?
    
    private let sendAdapter: ISendEthereumAdapter
    private let manager: EthereumKitManager
    
    private(set) var feeRateProvider: IFeeRateProvider
    
    private var subscriptions = Set<AnyCancellable>()
    
    var amount = CurrentValueSubject<Decimal, Never>(0)
    var feeRateType = CurrentValueSubject<TxFees, Never>(.normal)
    var receiverAddress = CurrentValueSubject<String, Never>(String())
    var recomendedFees = CurrentValueSubject<RecomendedFees?, Never>(nil)
    
    var balance: Decimal {
        sendAdapter.balance
    }
    
    var spendable: Decimal {
        balance - fee
    }
    
    var fee: Decimal {
        guard let gasData = transaction?.gasData, let significand = Decimal(string: String(gasData.fee)) else {
            return 0
        }
        
        return Decimal(sign: .plus, exponent: -coin.decimal, significand: significand)
    }
    
    init(coin: Coin, sendAdapter: ISendEthereumAdapter, feeRateProvider: IFeeRateProvider, manager: EthereumKitManager) {
        self.coin = coin
        self.sendAdapter = sendAdapter
        self.feeRateProvider = feeRateProvider
        self.manager = manager
        
        Publishers.CombineLatest(amount, receiverAddress)
            .flatMap { amount, address -> AnyPublisher<TransactionData?, Never> in
                if amount == 0 {
                    self.transaction = nil
                    self.recomendedFees.send(nil)
                }
                
                guard
                    let amountToSend = BigUInt(amount.hs.roundedString(decimal: coin.decimal)),
                    amountToSend > 0,
                    let recepientAddress = try? Address(hex: address)
                else {
                    return Just(nil).eraseToAnyPublisher()
                }
                
                let transactionData = sendAdapter.transactionData(amount: amountToSend, address: recepientAddress)
                
                return Just(transactionData).eraseToAnyPublisher()
            }
            .compactMap{ $0 }
            .flatMap { txData in
                feeRateProvider.recommendedFeeRate.flatMap { gasPrice -> AnyPublisher<Transaction, Never> in
                    self.transaction(gasPrice: gasPrice, transactionData: txData)
                }
            }
            .receive(on: RunLoop.main)
            .sink { transaction in
                print("Gas data")
                print(transaction.gasData)
                                
                self.transaction = transaction
                let fees = RecomendedFees(fastestFee: self.fee, halfHourFee: self.fee, hourFee: self.fee)
                self.recomendedFees.send(fees)
            }
            .store(in: &subscriptions)
        
        amount.send(0.00001)
    }
    
    private func transaction(gasPrice: Int, transactionData: TransactionData) -> AnyPublisher<Transaction, Never> {
        adjustedTransactionData(gasPrice: gasPrice, transactionData: transactionData).flatMap { [unowned self] transactionData in
            self.manager.gasLimit(gasPrice: gasPrice, transactionData: transactionData).map { estimatedGasLimit -> Transaction in
                let gasLimit = self.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit)
                
                return Transaction(
                    data: transactionData,
                    gasData: GasData(estimatedGasLimit: estimatedGasLimit, gasLimit: gasLimit, gasPrice: gasPrice)
                )
            }
            .flatMap {
                Just($0)
            }
        }
        .eraseToAnyPublisher()
    }

    private func adjustedTransactionData(gasPrice: Int, transactionData: TransactionData) -> AnyPublisher<TransactionData, Never> {
        if transactionData.input.isEmpty && false/*&& transactionData.value == evmBalance*/ {
            let stubTransactionData = TransactionData(to: transactionData.to, value: 1, input: Data())
            
            return manager.gasLimit(gasPrice: gasPrice, transactionData: stubTransactionData).map { [unowned self] estimatedGasLimit -> TransactionData in
                let gasLimit = self.surchargedGasLimit(estimatedGasLimit: estimatedGasLimit)
                let adjustedValue = transactionData.value - BigUInt(gasLimit) * BigUInt(gasPrice)
                
                return TransactionData(to: transactionData.to, value: adjustedValue, input: Data())
            }
            .flatMap {
                Just($0)
            }
            .eraseToAnyPublisher()
        } else {
            return Just(transactionData).eraseToAnyPublisher()
        }
    }
    
    private func surchargedGasLimit(estimatedGasLimit: Int) -> Int {
        estimatedGasLimit + Int(Double(estimatedGasLimit) / 100.0 * Double(gasLimitSurchargePercent))
    }
    
    func validateAddress() throws {
        _ = try EvmKit.Address.init(hex: receiverAddress.value)
    }
    
    func send() -> Future<String, Error> {
        guard let transaction = transaction else {
            return Future { $0(.failure(SendError.noTransaction)) }
        }
        return sendAdapter.send(tx: transaction)
    }
    
    func sendMax() -> Future<String, Error> {
        send()
    }
    
    func unconfirmedTx(id: String, amount: String) -> TransactionRecord {
        let hash = Data(id.utf8)
        let timestamp = Int(Date().timeIntervalSince1970)
        let unconfirmedTx = EvmKit.Transaction(hash: hash, timestamp: timestamp, isFailed: false)
        return TransactionRecord(transaction: unconfirmedTx, amount: Decimal(string: amount), type: .sent)
    }
}

extension SendETHService {
    enum SendError: Error {
        case noTransaction
        case error(String)
        case unsupportedAccount
    }
    
    struct GasData {
        let estimatedGasLimit: Int
        let gasLimit: Int
        let gasPrice: Int

        var estimatedFee: BigUInt {
            BigUInt(estimatedGasLimit * gasPrice)
        }

        var fee: BigUInt {
            BigUInt(gasLimit * gasPrice)
        }
    }

    struct Transaction {
        let data: TransactionData
        let gasData: GasData

        var totalAmount: BigUInt {
            data.value + gasData.fee
        }
    }

    enum GasPriceType {
        case recommended
        case custom(gasPrice: Int)
    }

    enum GasDataError: Error {
        case noTransactionData
        case insufficientBalance
    }
}
