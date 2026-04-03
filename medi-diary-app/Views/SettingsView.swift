import SwiftUI

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(SubscriptionManager.self) private var subscriptionManager

    @State private var showPaywall = false

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(authManager.userEmail ?? "No email")
                        .font(.poppins(.semiBold, size: 16))
                        .foregroundStyle(.white)

                    HStack {
                        Spacer()
                        Text(subscriptionManager.tier == .premium ? "Premium" : "Basic")
                            .font(.poppins(.semiBold, size: 13))
                            .foregroundStyle(PastelTheme.dark)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(PastelTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if subscriptionManager.tier == .free {
                Section {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundStyle(PastelTheme.primary)
                            Text("Upgrade to Premium")
                                .foregroundStyle(PastelTheme.dark)
                        }
                    }
                }
            }

            Section("Data") {
                HStack {
                    Image(systemName: subscriptionManager.tier == .premium ? "icloud.fill" : "icloud.slash")
                        .foregroundStyle(subscriptionManager.tier == .premium ? PastelTheme.primary : .secondary)
                    Text("iCloud Sync")
                    Spacer()
                    Text(subscriptionManager.tier == .premium ? "Active" : "Inactive")
                        .font(.poppins(.medium, size: 15))
                        .foregroundStyle(subscriptionManager.tier == .premium ? PastelTheme.primary : .secondary)
                        .onTapGesture {
                            if subscriptionManager.tier == .free {
                                showPaywall = true
                            }
                        }
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(appVersion)
                        .foregroundStyle(.secondary)
                }

                Link("Privacy Policy", destination: URL(string: "https://codedancoffee-stone.vercel.app/privacy-policy")!)

                Link("Terms of Service", destination: URL(string: "https://codedancoffee-stone.vercel.app/terms")!)
            }

            Section {
                Button("Sign Out", role: .destructive) {
                    authManager.signOut()
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(PastelTheme.gradient.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthenticationManager())
    .environment(SubscriptionManager())
}
