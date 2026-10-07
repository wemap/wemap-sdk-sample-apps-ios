//
//  SampleFailureAlert.swift
//  MapExample
//
//  Created by Evgenii Khrushchev on 07/09/2026.
//  Copyright © 2026 Wemap SAS. All rights reserved.
//

import SwiftUI

/**
 A failure a sample is asking the user about, and the action that answers it.

 The widgets' `ItineraryFormFailure` is not kept as-is: an alert shows a *message* rather than an error, and
 the retry it offers has to be the one that came with the failure being shown — pairing the two here is what
 stops the button outliving the failure it belongs to.
 */
struct SampleFailure {

    let message: String
    let retry: @MainActor () -> Void
}

/**
 Asks the user whether to try the failed thing again.

 The other half of what `SampleToast` is for. A failure carrying a retry is a **question**, and a question
 belongs in an alert: it cannot be missed, and it is answered before the map or the form can be touched —
 which matters here, because a widget's retry is only good while the question is unchanged, so a fading
 toast would carry the way back off screen and leave a form with both ends filled, no line, and nothing to
 press. A failure with nothing to re-ask is only news, and news goes on the toast.
 */
private struct SampleFailureAlert: ViewModifier {

    @Binding var failure: SampleFailure?

    /**
     `alert(_:isPresented:presenting:actions:message:)` wants a `Bool` binding of its own even when handed a
     value to present, so the failure is made to serve as one — and answering the alert clears it.
     */
    private var isPresented: Binding<Bool> {
        Binding(
            get: { failure != nil },
            set: { isPresented in
                if !isPresented {
                    failure = nil
                }
            }
        )
    }

    func body(content: Content) -> some View {
        content
            .alert("Itinerary", isPresented: isPresented, presenting: failure) { failure in
                Button("Retry") { failure.retry() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text($0.message)
            }
    }
}

extension View {

    /** Asks about `failure` for as long as there is one, offering the retry it carries. */
    func sampleFailureAlert(_ failure: Binding<SampleFailure?>) -> some View {
        modifier(SampleFailureAlert(failure: failure))
    }
}
