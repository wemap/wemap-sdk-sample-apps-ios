//
//  SampleToast.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 04/09/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import SwiftUI

/**
 What `ToastHelper` is to the UIKit samples, for the SwiftUI ones.

 A failure reported through a callback and nothing else — an itinerary that could not be computed leaves the
 screen looking exactly like one nobody has asked anything of yet — so a sample that only `print`s the error
 shows nothing whatsoever to the person holding the phone. Which is also the answer to "what should my app
 do here": put it on screen. It stays on for `UIConstants.Delay.long`, the same as the UIKit samples give an
 error.
 */
private struct SampleToast: ViewModifier {

    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            Color.black.opacity(0.7),
                            in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                        )
                        .padding(24)
                        .transition(.opacity)
                        // Keyed on the message, so a second failure restarts the countdown instead of being
                        // taken off screen by the first one's.
                        .task(id: message) {
                            let delay = UIConstants.Delay.long
                            try? await Task.sleep(nanoseconds: UInt64(delay * Double(NSEC_PER_SEC)))
                            self.message = nil
                        }
                }
            }
            .animation(.default, value: message)
    }
}

extension View {

    /** Shows `message` over the bottom of this view until it clears itself. */
    func sampleToast(_ message: Binding<String?>) -> some View {
        modifier(SampleToast(message: message))
    }
}
