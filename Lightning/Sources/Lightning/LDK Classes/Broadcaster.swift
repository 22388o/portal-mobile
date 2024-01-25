//
//  Broadcaster.swift
//  Conforms to the `BroadcasterInterface` protocol, which establishes behavior for broadcasting
//  a transaction to the Bitcoin network.
//
//  Created by Jurvis on 9/5/22.
//

import Foundation
import LightningDevKit
import BitcoinDevKit

class Broadcaster: BroadcasterInterface {
    private let rpcInterface: RpcChainManager
    
    init(rpcInterface: RpcChainManager) {
        self.rpcInterface = rpcInterface
        super.init()
    }
    
    override func broadcastTransactions(txs: [[UInt8]]) {
        Task {
            for tx in txs {
                let transaction = try Transaction(transactionBytes: tx)
                let expectedTxId = transaction.txid()
                let transactionDict = try await rpcInterface.getTransactionWithId(id: expectedTxId)
                
                guard transactionDict.keys.isEmpty else {
                    break
                }
                
                let resultTxId = try await self.rpcInterface.submitTransaction(transaction: transaction.serialize())
                print("Submitted tx with id: \(resultTxId)")
                
                guard expectedTxId == resultTxId else {
                    fatalError("Expected txId: \(expectedTxId), result: \(resultTxId)")
                }
            }
        }
    }
}
