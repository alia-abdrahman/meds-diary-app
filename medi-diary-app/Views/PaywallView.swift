import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedProduct: Product?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            PastelTheme.gradient.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - App Icon
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 28))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        .padding(.top, 50)

                    // MARK: - Title & Subtitle
                    Text("Meds Diary Premium")
                        .font(.poppins(.bold, size: 28))
                        .foregroundStyle(.primary)
                        .padding(.top, 20)

                    Text("Upgrade to Premium and take full control\nof your health.")
                        .font(.poppins(.regular, size: 15))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)

                    // MARK: - Features
                    VStack(spacing: 0) {
                        featureRow(icon: "calendar", title: "Unlimited appointments")
                        Divider().padding(.horizontal, 16)
                        featureRow(icon: "pill.fill", title: "Unlimited medicines")
                        Divider().padding(.horizontal, 16)
                        featureRow(icon: "leaf.fill", title: "Unlimited supplements")
                        Divider().padding(.horizontal, 16)
                        featureRow(icon: "person.2.fill", title: "Unlimited care recipients")
                        Divider().padding(.horizontal, 16)
                        featureRow(icon: "icloud.fill", title: "iCloud sync across all devices")
                    }
                    .padding(.top, 24)
                    .padding(.horizontal, 24)

                    // MARK: - Plan Options
                    planOptionsSection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)

                    // MARK: - Bottom Actions
                    bottomSection
                        .padding(.top, 24)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }

            // MARK: - Close Button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36, height: 36)
                    .background(.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 12)
            .padding(.trailing, 20)
        }
        .task {
            await subscriptionManager.loadProducts()
            if selectedProduct == nil {
                selectedProduct = subscriptionManager.products.first
            }
        }
        .onChange(of: subscriptionManager.tier) { _, newTier in
            if newTier == .premium {
                dismiss()
            }
        }
    }

    // MARK: - Feature Row

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(PastelTheme.dark)
                .frame(width: 36, height: 36)
                .background(PastelTheme.primary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(title)
                .font(.poppins(.medium, size: 15))
                .foregroundStyle(.primary)

            Spacer()
        }
        .padding(.vertical, 12)
    }

    // MARK: - Plan Options

    private var planOptionsSection: some View {
        VStack(spacing: 12) {
            if subscriptionManager.isLoading {
                ProgressView()
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
            } else if subscriptionManager.products.isEmpty {
                Text("Products unavailable")
                    .font(.poppins(.regular, size: 14))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 40)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(subscriptionManager.products, id: \.id) { product in
                    PlanOptionCard(
                        product: product,
                        isSelected: selectedProduct?.id == product.id,
                        showDiscount: product.id.contains("yearly")
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedProduct = product
                        }
                    }
                }
            }
        }
    }

    // MARK: - Bottom Section

    private var bottomSection: some View {
        VStack(spacing: 12) {
            if let error = subscriptionManager.errorMessage {
                Text(error)
                    .font(.poppins(.regular, size: 13))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Button {
                guard let product = selectedProduct else { return }
                Task { await subscriptionManager.purchase(product) }
            } label: {
                Text("Continue")
                    .font(.poppins(.semiBold, size: 18))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(PastelTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(selectedProduct == nil || subscriptionManager.isLoading)
            .opacity(selectedProduct == nil ? 0.5 : 1.0)
            .buttonStyle(PressDownButtonStyle())

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchase")
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(PastelTheme.dark)
            }
            .padding(.top, 4)

            Text("Subscriptions automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your Apple ID settings.")
                .font(.poppins(.regular, size: 11))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
    }
}

// MARK: - Plan Option Card

private struct PlanOptionCard: View {
    let product: Product
    let isSelected: Bool
    let showDiscount: Bool
    let onTap: () -> Void

    private var durationLabel: String {
        if product.id.contains("monthly") {
            return "1 month"
        } else if product.id.contains("yearly") {
            return "1 year"
        } else {
            return "One-time purchase"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.displayName)
                        .font(.poppins(.semiBold, size: 16))
                        .foregroundStyle(.primary)

                    Text(durationLabel)
                        .font(.poppins(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.poppins(.bold, size: 18))
                    .foregroundStyle(isSelected ? PastelTheme.dark : .primary)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(PastelTheme.dark)
                }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? PastelTheme.dark : Color.gray.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if showDiscount {
                    Text("30% OFF")
                        .font(.poppins(.bold, size: 10))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(x: -12, y: -10)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
