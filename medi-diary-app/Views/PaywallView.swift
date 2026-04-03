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
                VStack(alignment: .leading, spacing: 0) {
                    // App icon
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(30)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 26)

                    // Title
                    Text("Meds Diary Premium")
                        .font(.poppins(.bold, size: 28))
                        .foregroundStyle(PastelTheme.dark)
                        .padding(.top, 16)

                    // Features
                    featuresSection
                        .padding(.top, 24)

                    // Plan options
                    planOptionsSection
                        .padding(.top, 28)

                    // Bottom actions
                    bottomSection
                        .padding(.top, 28)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PastelTheme.dark.opacity(0.6))
                    .frame(width: 32, height: 32)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
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

    // MARK: - Features

    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            featureRow(icon: "calendar", title: "Unlimited appointments")
            featureRow(icon: "pill.fill", title: "Unlimited medicines")
            featureRow(icon: "leaf.fill", title: "Unlimited supplements")
            featureRow(icon: "icloud.fill", title: "iCloud sync across all devices")
        }
    }

    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(PastelTheme.dark)
                .frame(width: 24)

            Text(title)
                .font(.poppins(.medium, size: 15))
                .foregroundStyle(PastelTheme.dark)
        }
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
                    .background(
                        LinearGradient(
                            colors: [PastelTheme.primary, PastelTheme.dark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
            .disabled(selectedProduct == nil || subscriptionManager.isLoading)
            .opacity(selectedProduct == nil ? 0.5 : 1.0)
            .buttonStyle(PressDownButtonStyle())

            Button {
                Task { await subscriptionManager.restorePurchases() }
            } label: {
                Text("Restore Purchase")
                    .font(.poppins(.medium, size: 14))
                    .foregroundStyle(PastelTheme.dark.opacity(0.7))
            }
        }
    }
}

// MARK: - Plan Option Card

private struct PlanOptionCard: View {
    let product: Product
    let isSelected: Bool
    let showDiscount: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(product.displayName)
                    .font(.poppins(.medium, size: 16))
                    .foregroundStyle(isSelected ? PastelTheme.dark : .primary.opacity(0.7))

                Spacer()

                Text(product.displayPrice)
                    .font(.poppins(.bold, size: 18))
                    .foregroundStyle(isSelected ? PastelTheme.dark : .primary.opacity(0.7))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? PastelTheme.primary : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) {
                if showDiscount {
                    Text("30% off")
                        .font(.poppins(.semiBold, size: 11))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.red)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .offset(x: -16, y: -12)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environment(SubscriptionManager())
}
