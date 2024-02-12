//
//  RootView.swift
// Portal
//
//  Created by farid on 8/9/22.
//

import SwiftUI

struct RootView: View {
    private var viewModel = RootViewViewModel()
    
    var body: some View {
        switch viewModel.state {
        case .empty:
            NoAccountRootView()
        case .account:
            Mainview()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
