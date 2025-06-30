//
//  ExpiryPageView.swift
//
//  Created by Grant Brooks Goodman.
//  Copyright © NEOTechnica Corporation. All rights reserved.
//

/* Native */
import Foundation
import SwiftUI

/* Proprietary */
import AlertKit

struct ExpiryPageView: View {
    // MARK: - Dependencies

    @Dependency(\.coreKit.gcd) private var coreGCD: CoreKit.GCD

    // MARK: - Init

    init() {}

    // MARK: - View

    var body: some View {
        VStack {
            Text("")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            coreGCD.after(.milliseconds(1500)) {
                Task { await BuildExpiryAlert.shared.present() }
            }
        }
    }
}
