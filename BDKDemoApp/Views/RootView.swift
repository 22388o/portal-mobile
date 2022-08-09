//
//  RootView.swift
//  BDKDemoApp
//
//  Created by farid on 8/9/22.
//

import SwiftUI

struct RootView: View {
    @StateObject private var viewModel = RootViewViewModel()
    
    var body: some View {
        if viewModel.hasAccount {
            HostingTabBarView()
        } else {
            NoAccountView()
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}