import SwiftUI
import SwiftData

struct SupplementDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let supplement: Supplement

    @State private var showingDeleteConfirmation = false

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Details card
                VStack(alignment: .leading, spacing: 14) {
                    if !supplement.dosage.isEmpty {
                        detailRow("Dosage", value: supplement.displayDosage, icon: "pills.fill")
                    }

                    if supplement.stock > 0 {
                        detailRow("Stock", value: "\(supplement.stock) pills", icon: "cross.case.fill")
                    }

                    detailRow("Frequency", value: supplement.frequency, icon: "clock.fill")

                    detailRow("Status", value: supplement.isActive ? "Active" : "Inactive", icon: supplement.isActive ? "checkmark.seal.fill" : "xmark.seal.fill")

                    if !supplement.reminderTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Reminders", systemImage: "bell.fill")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            ForEach(supplement.reminderTimes, id: \.self) { time in
                                Text(timeFormatter.string(from: time))
                                    .font(.poppins(.regular, size: 15))
                                    .padding(.leading, 28)
                            }
                        }
                    }

                    if !supplement.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Notes", systemImage: "note.text")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            Text(supplement.notes)
                                .font(.poppins(.regular, size: 15))
                                .padding(.leading, 28)
                        }
                    }

                    if let imageData = supplement.imageData, let uiImage = UIImage(data: imageData) {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Image", systemImage: "photo.fill")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, maxHeight: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .cardStyle()

                // Mark as taken button
                Button {
                    supplement.toggleTakenToday()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: supplement.isTakenToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                        Text(supplement.isTakenToday ? "Taken Today" : "Mark as Taken")
                            .font(.poppins(.semiBold, size: 16))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(PastelTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)

                // Delete button
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete Supplement")
                    }
                    .font(.poppins(.medium, size: 15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            .padding()
        }
        .background(PastelTheme.gradient.ignoresSafeArea())
        .navigationTitle(supplement.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SupplementFormView(supplement: supplement)
                } label: {
                    Text("Edit")
                }
            }
        }
        .alert("Delete Supplement", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                notificationManager.cancelReminders(for: supplement)
                modelContext.delete(supplement)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(supplement.name)?")
        }
    }

    private func detailRow(_ label: String, value: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Label(label, systemImage: icon)
                .font(.poppins(.medium, size: 14))
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(.poppins(.regular, size: 15))
        }
    }
}
