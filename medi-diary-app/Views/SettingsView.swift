import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(SubscriptionManager.self) private var subscriptionManager
    @Environment(\.modelContext) private var modelContext

    @State private var showPaywall = false
    @State private var showDeleteConfirmation = false
    @State private var showShareSheet = false

    private func deleteAccount() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        do {
            try modelContext.delete(model: Medicine.self)
            try modelContext.delete(model: Supplement.self)
            try modelContext.delete(model: Appointment.self)
            try modelContext.delete(model: MoodEntry.self)
            try modelContext.delete(model: Person.self)
            try modelContext.save()
        } catch {
            print("Failed to delete data: \(error)")
        }

        UserDefaults.standard.removeObject(forKey: "activePersonID")
        authManager.deleteAccountData()
    }

    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Header
                Text("Settings")
                    .font(.poppins(.bold, size: 28))
                    .foregroundStyle(.primary)
                    .padding(.top, 8)

                // MARK: - Account Card
                HStack(spacing: 14) {
                    Circle()
                        .fill(PastelTheme.primary.opacity(0.4))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(authManager.userEmail ?? "No email")
                            .font(.poppins(.semiBold, size: 15))
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        Text("Manage your account")
                            .font(.poppins(.regular, size: 13))
                            .foregroundStyle(.white.opacity(0.8))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text(subscriptionManager.tier == .premium ? "Premium" : "Basic")
                            .font(.poppins(.semiBold, size: 13))
                            .foregroundStyle(PastelTheme.dark)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(PastelTheme.dark)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white)
                    .clipShape(Capsule())
                }
                .padding()
                .background(PastelTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 14))

                // MARK: - Upgrade to Premium
                if subscriptionManager.tier == .free {
                    Button {
                        showPaywall = true
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(PastelTheme.dark)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Upgrade to Premium")
                                    .font(.poppins(.semiBold, size: 15))
                                    .foregroundStyle(.primary)
                                Text("Unlock all premium features")
                                    .font(.poppins(.regular, size: 13))
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - People
                sectionLabel("PEOPLE")

                NavigationLink {
                    ManagePeopleView()
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(PastelTheme.dark)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Care Recipients")
                                .font(.poppins(.semiBold, size: 15))
                                .foregroundStyle(.primary)
                            Text("Manage yourself and loved ones")
                                .font(.poppins(.regular, size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                // MARK: - Data
                sectionLabel("DATA")

                Button {
                    if subscriptionManager.tier == .free {
                        showPaywall = true
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: subscriptionManager.tier == .premium ? "icloud.fill" : "icloud.slash")
                            .font(.system(size: 20))
                            .foregroundStyle(subscriptionManager.tier == .premium ? PastelTheme.dark : .secondary)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("iCloud Sync")
                                .font(.poppins(.semiBold, size: 15))
                                .foregroundStyle(.primary)
                            Text("Keep your data safe across devices")
                                .font(.poppins(.regular, size: 13))
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(subscriptionManager.tier == .premium ? "Active" : "Inactive")
                            .font(.poppins(.medium, size: 13))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(PastelTheme.light.opacity(0.4))
                            .clipShape(Capsule())

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)

                // MARK: - About
                sectionLabel("ABOUT")

                VStack(spacing: 0) {
                    HStack {
                        Text("Version")
                            .font(.poppins(.medium, size: 15))
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(appVersion)
                            .font(.poppins(.regular, size: 15))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)

                    Divider().padding(.horizontal, 16)

                    Link(destination: URL(string: "https://codedancoffee-stone.vercel.app/privacy-policy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .font(.poppins(.medium, size: 15))
                                .foregroundStyle(PastelTheme.dark)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    Divider().padding(.horizontal, 16)

                    Link(destination: URL(string: "https://codedancoffee-stone.vercel.app/terms")!) {
                        HStack {
                            Text("Terms of Service")
                                .font(.poppins(.medium, size: 15))
                                .foregroundStyle(PastelTheme.dark)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Support
                sectionLabel("SUPPORT")

                VStack(spacing: 0) {
                    Button {
                        showShareSheet = true
                    } label: {
                        settingsRow(icon: "square.and.arrow.up", iconColor: PastelTheme.dark, label: "Share App")
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.horizontal, 16)

                    Link(destination: URL(string: "https://buymeacoffee.com/codedancoffee")!) {
                        HStack(spacing: 12) {
                            Text("☕")
                                .font(.system(size: 16))

                            Text("Buy Me a Coffee")
                                .font(.poppins(.medium, size: 15))
                                .foregroundStyle(.primary)

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }

                    Divider().padding(.horizontal, 16)

                    Link(destination: URL(string: "https://apps.apple.com/app/id6761620429")!) {
                        settingsRow(icon: "star.fill", iconColor: Color(red: 1.0, green: 0.75, blue: 0.0), label: "Rate Us")
                    }
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Account Actions
                VStack(spacing: 0) {
                    Button {
                        authManager.signOut()
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16))
                                .foregroundStyle(.red)
                            Text("Sign Out")
                                .font(.poppins(.medium, size: 15))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.horizontal, 16)

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundStyle(.red)
                            Text("Delete Account")
                                .font(.poppins(.medium, size: 15))
                                .foregroundStyle(.red)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                Text("Deleting your account will permanently remove all your data including medicines, supplements, and appointments.")
                    .font(.poppins(.regular, size: 12))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding()
            .padding(.bottom, 10)
        }
        .scrollContentBackground(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .background(PastelTheme.gradient.ignoresSafeArea())
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showShareSheet) {
            let appURL = URL(string: "https://apps.apple.com/app/id6761620429")!
            let shareText = "Check out Meds Diary \u{2013} an app to track your medicines, supplements, and appointments."
            ActivityViewController(activityItems: [shareText, appURL])
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("Are you sure? This will permanently delete all your data and cannot be undone.")
        }
    }

    // MARK: - Section Label

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.poppins(.medium, size: 12))
            .foregroundStyle(.secondary)
            .padding(.top, 4)
    }

    // MARK: - Settings Row

    private func settingsRow(icon: String, iconColor: Color, label: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(iconColor)

            Text(label)
                .font(.poppins(.medium, size: 15))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        SettingsView()
    }
    .environment(AuthenticationManager())
    .environment(SubscriptionManager())
}
