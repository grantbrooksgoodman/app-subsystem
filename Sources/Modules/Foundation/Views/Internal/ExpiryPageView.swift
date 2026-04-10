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
            Task.delayed(by: .milliseconds(1500)) {
                await BuildExpiryAlert.shared.present()
            }
        }
    }
}
