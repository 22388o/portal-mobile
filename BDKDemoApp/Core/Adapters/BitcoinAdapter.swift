//
//  BitcoinAdapter.swift
//  BDKDemoApp
//
//  Created by farid on 9/19/22.
//

import Foundation
import Combine
import BitcoinDevKit

class ProgressHandler: BitcoinDevKit.Progress {
    func update(progress: Float, message: String?) {
        print("progress: \(progress), message: \(message ?? "-")")
    }
}

final class BitcoinAdapter {
    enum BtcAdapterError: Error {
        case dbNotFound
        
        var descriptioin: String {
            switch self {
            case .dbNotFound:
                return "DB not found"
            }
        }
    }
        
    private let stateUpdatedSubject = PassthroughSubject<Void, Never>()
    private let balanceUpdatedSubject = PassthroughSubject<Void, Never>()
    private let transactionsSubject = CurrentValueSubject<[BitcoinDevKit.Transaction], Never>([])
    
    private let wallet: BitcoinDevKit.Wallet
    private let blockchain: BitcoinDevKit.Blockchain
    private let updateTimer = RepeatingTimer(timeInterval: 60)
    private let progressHandler = ProgressHandler()
    private let networkQueue = DispatchQueue(label: "com.portal.network.layer.queue", qos: .userInitiated)
    
    private var adapterState: AdapterState = .empty
    private var balanceSats: UInt64 = 0
    
    init(wallet: Wallet) throws {
        let account = wallet.account
        let fingerprint = account.extendedKey.fingerprint
        let xprv = account.extendedKey.xprv
                
        let descriptor = "wpkh([\(fingerprint)/84'/0'/0']\(xprv)/*)"
        let changeDescriptor = "wpkh([\(fingerprint)/84'/0'/1']\(xprv)/*)"
        
        if let dbPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).last?.absoluteString {
            let sqliteConfig = SqliteDbConfiguration(path: dbPath + "portal.sqlite" + "\(account.id)")
            let dbConfig = DatabaseConfig.sqlite(config: sqliteConfig)
            let electrum = ElectrumConfig(url: "ssl://electrum.blockstream.info:60002", socks5: nil, retry: 5, timeout: nil, stopGap: 10)
            let blockchainConfig = BlockchainConfig.electrum(config: electrum)
            
            self.blockchain = try Blockchain(config: blockchainConfig)
            
            self.wallet = try BitcoinDevKit.Wallet(
                descriptor: descriptor,
                changeDescriptor: changeDescriptor,
                network: Network.testnet,
                databaseConfig: dbConfig
            )
            
            adapterState = .loaded
            
            self.loadCache()
            
            self.updateTimer.eventHandler = { [weak self] in
                self?.sync()
            }
        } else {
            throw BtcAdapterError.dbNotFound
        }
    }
    
    private func loadCache() {
        do {
            try fetchBalance()
            try fetchTransactions()
        } catch {
            update(state: .failed(error))
        }
    }
    
    private func sync() {
        guard adapterState != .empty, adapterState != .syncing else { return }
        
        print("Syncing btc network...")
        
        update(state: .syncing)
        
        networkQueue.async {
            do {
                try self.wallet.sync(blockchain: self.blockchain, progress: self.progressHandler)
            } catch {
                DispatchQueue.main.async {
                    print("Btc network synced error: \(error)")
                    self.update(state: .failed(error))
                }
            }
            
            do {
                try self.fetchBalance()
                try self.fetchTransactions()

                DispatchQueue.main.async {
                    print("Btc network synced...")
                    self.update(state: .synced)
                }
            } catch {
                DispatchQueue.main.async {
                    print("Btc network synced error: \(error)")
                    self.update(state: .failed(error))
                }
            }
        }
    }
    
    private func fetchBalance() throws {
        balanceSats = try wallet.getBalance()
        balanceUpdatedSubject.send()
    }
    
    private func fetchTransactions() throws {
        update(txs:
            try wallet.getTransactions().sorted(by: {
                switch $0 {
                case .confirmed(_, let confirmation_a):
                    switch $1 {
                    case .confirmed(_, let confirmation_b):
                        return confirmation_a.timestamp > confirmation_b.timestamp
                    default:
                        return false
                    }
                default:
                    switch $1 {
                    case .unconfirmed(_):
                        return true
                    default:
                        return false
                    }
                } })
        )
    }
    
    private func update(state: AdapterState) {
        adapterState = state
        stateUpdatedSubject.send()
    }
    
    private func update(txs: [BitcoinDevKit.Transaction]) {
        DispatchQueue.main.async {
            self.transactionsSubject.send(txs)
        }
    }
}

extension BitcoinAdapter: ISendAdapter {
    func send(to: String, amount: String, completion: @escaping (String?, Error?) -> Void) {
        do {
            let walletBalance = try wallet.getBalance()
            let satAmountDouble = (Double(amount) ?? 0) * 100_000_000
            let satAmountInt = UInt64(satAmountDouble)
            if walletBalance >= satAmountInt {
                let psbt = try TxBuilder().addRecipient(address: to, amount: satAmountInt).enableRbf().finish(wallet: wallet)
                let finalized = try wallet.sign(psbt: psbt)
                print("Tx id: \(psbt.txid())")

                if finalized {
                    print("Tx id: \(psbt.txid())")
                    try blockchain.broadcast(psbt: psbt)
                    sync()
                    completion(psbt.txid(), nil)
                }
            } else {
                completion(nil, SendFlowError.insufficientAmount)
            }
        } catch {
            completion(nil, error)
        }
    }
}

extension BitcoinAdapter: IAdapter {
    func start() {
        updateTimer.resume()
    }
    
    func stop() {
        updateTimer.suspend()
    }
    
    func refresh() {
        sync()
    }
    
    var debugInfo: String {
        "Btc adapter debug"
    }
}

extension BitcoinAdapter: IBalanceAdapter {
    var state: AdapterState {
        adapterState
    }
    
    var balance: Decimal {
        Decimal(balanceSats)/100_000_000
    }
    
    var balanceStateUpdated: AnyPublisher<Void, Never> {
        stateUpdatedSubject.eraseToAnyPublisher()
    }
    
    var balanceUpdated: AnyPublisher<Void, Never> {
        balanceUpdatedSubject.eraseToAnyPublisher()
    }
}

extension BitcoinAdapter: IDepositAdapter {
    var receiveAddress: String {
        do {
            let addressInfo = try wallet.getAddress(addressIndex: AddressIndex.lastUnused)
            print("======================================================")
            print("btc receive address: \(addressInfo.address)")
            print("======================================================")
            return addressInfo.address
        } catch {
            return "ERROR"
        }
    }
}

extension BitcoinAdapter: ITransactionsAdapter {
    var transactionRecords: AnyPublisher<[Transaction], Never> {
        transactionsSubject.eraseToAnyPublisher()
    }
}

