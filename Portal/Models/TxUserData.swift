//
//  TxUserData.swift
//  Portal
//
//  Created by farid on 4/28/23.
//

import Foundation

struct TxUserData {
    let notes: String?
    let labels: [TxLabel]
    let price: Decimal
    
    init(notes: String? = nil, labels: [TxLabel]? = [], price: Decimal) {
        self.notes = notes
        self.labels = labels ?? []
        self.price = price
    }
    
    init(data: TxData) {
        notes = data.notes
        labels = data.labels
        price = data.assetUSDPrice as Decimal
    }
}
