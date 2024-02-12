//
//  NavigationStackView.swift
//  Portal
//
//  Created by farid on 12/1/22.
//

import SwiftUI
import Combine

enum Screen {
    typealias DismissAction = () -> (Void)
    typealias Identifier = String
    
    case noAccount
    case account(account: Account)
    case send(item: WalletItem)
    case receive(item: WalletItem)
    case accountBackup
    case securitySettings
    case setSecuritySettings
    case setPinCode
    case assetDetails(item: WalletItem)
    case createAccount
    case devUtility
    case restoreAccount
    case restoreConfirmation(viewModel: RestoreAccountViewModel)
    case nameAccount(words: [String]?)
    case recoveryPhrase(viewModel: RecoveryPhraseViewModel)
    case recoveryPhraseTest(viewModel: RecoveryPhraseViewModel)
    case recoveryWarning(viewModel: RecoveryPhraseViewModel)
    case transactionDetails(coin: Coin, tx: TransactionRecord)
    case setupSecuritySettings
    
    case sendSelectAsset(viewModel: SendViewViewModel)
    case sendSetRecipient(viewModel: SendViewViewModel)
    case sendSetAmount(viewModel: SendViewViewModel)
    case sendReviewTxView(viewModel: SendViewViewModel)
    
    case receiveGenerateQRCode(viewModel: ReceiveViewModel)
    
    case createChannelView(peer: Peer)
    case awaitsFundingChannelView(peer: Peer)
}

extension Screen {
    var id: Identifier {
        switch self {
        case .noAccount:
            return "no_account_ID"
        case .account:
            return "account_ID"
        case .send:
            return "send_ID"
        case .receive:
            return "receive_ID"
        case .createAccount:
            return "create_account_ID"
        case .restoreAccount:
            return "restore_account_ID"
        case .restoreConfirmation:
            return "restore_confirmation_ID"
        case .nameAccount:
            return "name_account_ID"
        case .accountBackup:
            return "account_backup_ID"
        case .assetDetails:
            return "asset_details_ID"
        case .recoveryPhrase:
            return "recovery_phrase_ID"
        case .recoveryPhraseTest:
            return "recovery_phrase_ID"
        case .recoveryWarning:
            return "recovery_warning_ID"
        case .transactionDetails:
            return "transaction_details_ID"
        case .sendSelectAsset:
            return "send_select_asset_ID"
        case .sendSetRecipient:
            return "send_set_recipient_ID"
        case .sendSetAmount:
            return "send_set_amount_ID"
        case .sendReviewTxView:
            return "send_review_tx_ID"
        case .receiveGenerateQRCode:
            return "receive_generate_qr_code_ID"
        case .securitySettings:
            return "security_settings_ID"
        case .setSecuritySettings:
            return "set_security_settings_ID"
        case .setPinCode:
            return "set_pincode_ID"
        case .setupSecuritySettings:
            return "set_security_settings_ID"
        case .devUtility:
            return "dev_utility_ID"
        case .createChannelView:
            return "create_channel_ID"
        case .awaitsFundingChannelView:
            return "awaits_funding_channel_ID"
        }
    }
}

protocol NavigationConfigurator {
    var defaultAnimation: Animation { get }
    func configure(_ screen: Screen) -> ViewElement?
}

extension NavigationConfigurator {
    var defaultAnimation: Animation { Animation.easeInOut(duration: 0.2) }
}

struct NavigationStackView<Root>: View where Root: View {
    private var navigationStack: NavigationStack
    
    private let rootViewID = "Root"
    private let rootView: Root
    private let defaultTransitions = NavigationTransition.defaultTransitions
    private let rootViewtransitions: (push: AnyTransition, pop: AnyTransition)
    
    init(
        transitionType: NavigationTransition = .default,
        configurator: NavigationConfigurator,
        rootView: Root
    ) {
        self.rootView = rootView
        self.navigationStack = NavigationStack(configurator: configurator)
        
        switch transitionType {
        case .none:
            self.rootViewtransitions = (.identity, .identity)
        case .custom(let transition):
            self.rootViewtransitions = (transition, transition)
        default:
            self.rootViewtransitions = defaultTransitions
        }
    }
    
    public var body: some View {
        VStack {
            let navigationType = navigationStack.navigationType

            if let currentView = navigationStack.currentView {
                let popTransition = currentView.popTransition
                let pushTransition = currentView.pushTransition
                
                currentView.wrappedElement
                    .id(currentView.id)
                    .transition(navigationType == .push ? pushTransition : popTransition)
            } else {
                rootView
                    .id(rootViewID)
                    .transition(navigationType == .push ? rootViewtransitions.push : rootViewtransitions.pop)
            }
        }
        .environment(navigationStack)
    }
}

