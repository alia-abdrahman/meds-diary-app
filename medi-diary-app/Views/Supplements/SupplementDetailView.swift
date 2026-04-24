import SwiftUI
import SwiftData

struct SupplementDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    @Query(sort: \Medicine.name) private var allMedicines: [Medicine]
    @Query(sort: \Supplement.name) private var allSupplements: [Supplement]
    @Query(sort: \MoodEntry.date) private var moodEntries: [MoodEntry]

    let supplement: Supplement

    @State private var showingDeleteConfirmation = false
    @State private var showingFullImage = false
    @State private var showMoodCheckIn = false
    @State private var takenBounce = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // MARK: - Header
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(PastelTheme.dark)
                            .frame(width: 40, height: 40)
                            .background(PastelTheme.light.opacity(0.6))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(supplement.name)
                        .font(.poppins(.bold, size: 20))
                        .foregroundStyle(.primary)

                    Spacer()

                    NavigationLink {
                        SupplementFormView(supplement: supplement)
                    } label: {
                        Text("Edit")
                            .font(.poppins(.medium, size: 15))
                            .foregroundStyle(PastelTheme.dark)
                    }
                }
                .padding(.top, 8)

                // MARK: - Image
                if let imageData = supplement.imageData, let uiImage = UIImage(data: imageData) {
                    Button {
                        showingFullImage = true
                    } label: {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity, maxHeight: 200)
                            .clipped()
                            .contentShape(Rectangle())
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }

                // MARK: - Details Card
                VStack(spacing: 0) {
                    if supplement.stock > 0 {
                        detailRow(
                            icon: "shippingbox.fill",
                            iconColor: PastelTheme.dark,
                            iconBg: PastelTheme.primary.opacity(0.2),
                            label: "Stock",
                            value: supplement.stock <= 5
                                ? "Time to refill\n\(supplement.stock) pill\(supplement.stock == 1 ? "" : "s") left"
                                : "\(supplement.stock) pills",
                            valueColor: supplement.stock <= 5 ? .orange : .primary
                        )
                        Divider().padding(.horizontal, 16)
                    }

                    if !supplement.dosage.isEmpty {
                        detailRow(
                            icon: "pills.fill",
                            iconColor: PastelTheme.dark,
                            iconBg: PastelTheme.primary.opacity(0.2),
                            label: "Dosage",
                            value: supplement.displayDosage,
                            valueColor: .primary
                        )
                        Divider().padding(.horizontal, 16)
                    }

                    detailRow(
                        icon: "calendar",
                        iconColor: PastelTheme.dark,
                        iconBg: PastelTheme.primary.opacity(0.2),
                        label: "Frequency",
                        value: supplement.frequency,
                        valueColor: .primary
                    )

                    Divider().padding(.horizontal, 16)

                    let isActive = supplement.isActive
                    detailRow(
                        icon: "checkmark.circle.fill",
                        iconColor: isActive ? PastelTheme.green : PastelTheme.gray,
                        iconBg: (isActive ? PastelTheme.green : PastelTheme.gray).opacity(0.2),
                        label: "Status",
                        value: isActive ? "Active" : "Paused",
                        valueColor: isActive ? PastelTheme.green : .secondary
                    )

                    Divider().padding(.horizontal, 16)

                    let streak = StreakManager.itemStreak(takenDates: supplement.takenDates)
                    detailRow(
                        icon: "flame.fill",
                        iconColor: .orange,
                        iconBg: Color.orange.opacity(0.15),
                        label: "Streak",
                        value: streak > 0 ? "\(streak) day\(streak == 1 ? "" : "s")" : "No streak",
                        valueColor: streak > 0 ? .orange : .secondary
                    )
                }
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Mark as Taken
                Button {
                    let wasTaken = supplement.isTakenToday
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                        supplement.toggleTakenToday()
                        takenBounce = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        takenBounce = false
                    }
                    if !wasTaken { checkMoodPrompt() }
                    Task {
                        await notificationManager.scheduleAllReminders(medicines: allMedicines, supplements: allSupplements)
                    }
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: supplement.isTakenToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                            .contentTransition(.symbolEffect(.replace))
                        Text(supplement.isTakenToday ? "Taken Today" : "Mark as Taken")
                            .font(.poppins(.semiBold, size: 16))
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(supplement.isTakenToday ? PastelTheme.green : PastelTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .scaleEffect(takenBounce ? 1.03 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.6), value: takenBounce)
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.25), value: supplement.isTakenToday)

                // MARK: - Delete Button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                        Text("Delete Supplement")
                            .font(.poppins(.medium, size: 15))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .padding(.bottom, 10)
        }
        .scrollContentBackground(.hidden)
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(PastelTheme.gradient.ignoresSafeArea())
        .fullScreenCover(isPresented: $showingFullImage) {
            if let imageData = supplement.imageData, let uiImage = UIImage(data: imageData) {
                ZStack {
                    Color.black.ignoresSafeArea()

                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .ignoresSafeArea()
                }
                .overlay(alignment: .topTrailing) {
                    Button {
                        showingFullImage = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.white.opacity(0.8))
                            .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showMoodCheckIn) {
            MoodCheckInView()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .alert("Delete Supplement", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                modelContext.delete(supplement)
                Task {
                    let allMedicines = (try? modelContext.fetch(FetchDescriptor<Medicine>())) ?? []
                    let allSupplements = (try? modelContext.fetch(FetchDescriptor<Supplement>())) ?? []
                    await notificationManager.scheduleAllReminders(medicines: allMedicines, supplements: allSupplements)
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(supplement.name)?")
        }
    }

    // MARK: - Detail Row

    private func detailRow(icon: String, iconColor: Color, iconBg: Color, label: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 10) {
            Circle()
                .fill(iconBg)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(iconColor)
                )

            Text(label)
                .font(.poppins(.medium, size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private func checkMoodPrompt() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let hasMoodToday = moodEntries.contains { calendar.startOfDay(for: $0.date) == today }
        guard !hasMoodToday else { return }

        let activeMeds = allMedicines.filter(\.isActive)
        let activeSupps = allSupplements.filter(\.isActive)
        guard !activeMeds.isEmpty || !activeSupps.isEmpty else { return }

        if activeMeds.allSatisfy(\.isTakenToday) && activeSupps.allSatisfy(\.isTakenToday) {
            showMoodCheckIn = true
        }
    }
}
