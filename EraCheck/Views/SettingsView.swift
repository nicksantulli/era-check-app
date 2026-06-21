import SwiftUI
import UIKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var purchases = PurchaseManager.shared

    var body: some View {
        NavigationView {
            List {
                Section {
                    Button(action: { Task { await purchases.purchase() } }) {
                        HStack {
                            Text("Remove Ads")
                            Spacer()
                            if purchases.isLoadingProduct || purchases.isPurchasing {
                                ProgressView()
                            } else {
                                Text(purchases.displayPrice ?? "$0.99")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .disabled(purchases.isLoadingProduct || purchases.isPurchasing || purchases.isProUnlocked)

                    Button(action: { Task { await purchases.restore() } }) {
                        HStack {
                            Text("Restore Purchases")
                            Spacer()
                            if purchases.isPurchasing && purchases.purchaseErrorMessage == nil {
                                ProgressView()
                            }
                        }
                    }
                } header: {
                    Text("Entitlements")
                }

                Section {
                    Button("Privacy & Data") { openUrl("https://dudleyapps.com/privacy") }
                    Button("More Dudley Apps") { openUrl("https://dudleyapps.com") }
                }

                Section {
                    HStack {
                        Text("App version")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")
                    }
                    HStack {
                        Text("Build")
                        Spacer()
                        Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
                    }
                }

                if let error = purchases.purchaseErrorMessage {
                    Section {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func openUrl(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}
