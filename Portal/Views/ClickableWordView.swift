//
//  ClickableWordView.swift
//  Portal
//
//  Created by farid on 11/29/22.
//

import SwiftUI
import PortalUI

struct ClickableWordView: View {
    let index: Int
    let word: String
    
    var body: some View {
        HStack(spacing: 2) {
            HStack {
                Text("\(index)")
                    .font(.Main.fixed(.monoBold, size: 18))
            }
            .frame(width: 46, height: 46)
            .background(Palette.grayScale2A)
            .cornerRadius(12, corners: [.topLeft, .bottomLeft])
            
            HStack {
                Text(word)
                    .font(.Main.fixed(.monoBold, size: 18))
            }
            .frame(width: 112, height: 46)
            .background(Palette.grayScale2A)
            .cornerRadius(12, corners: [.topRight, .bottomRight])
        }
        .frame(height: 46)
    }
}

struct ClickableWordView_Previews: PreviewProvider {
    static var previews: some View {
        ClickableWordView(index: 1, word: "Test")
    }
}
