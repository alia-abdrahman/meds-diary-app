import SwiftUI
import SwiftData

struct MedicineDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let medicine: Medicine

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
                    if !medicine.dosage.isEmpty {
                        detailRow("Dosage", value: medicine.displayDosage, icon: "pills.fill")
                    }

                    if medicine.stock > 0 {
                        detailRow("Stock", value: "\(medicine.stock) pills", icon: "cross.case.fill")
                    }

                    detailRow("Frequency", value: medicine.frequency, icon: "clock.fill")

                    detailRow("Status", value: medicine.isActive ? "Active" : "Inactive", icon: medicine.isActive ? "checkmark.seal.fill" : "xmark.seal.fill")

                    if !medicine.reminderTimes.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Reminders", systemImage: "bell.fill")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            ForEach(medicine.reminderTimes, id: \.self) { time in
                                Text(timeFormatter.string(from: time))
                                    .font(.poppins(.regular, size: 15))
                                    .padding(.leading, 28)
                            }
                        }
                    }

                    if !medicine.notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Notes", systemImage: "note.text")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            Text(medicine.notes)
                                .font(.poppins(.regular, size: 15))
                                .padding(.leading, 28)
                        }
                    }

                    if let imageData = medicine.imageData, let uiImage = UIImage(data: imageData) {
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
                    medicine.toggleTakenToday()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: medicine.isTakenToday ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 20))
                        Text(medicine.isTakenToday ? "Taken Today" : "Mark as Taken")
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
                        Text("Delete Medicine")
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
        .navigationTitle(medicine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MedicineFormView(medicine: medicine)
                } label: {
                    Text("Edit")
                }
            }
        }
        .alert("Delete Medicine", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                notificationManager.cancelReminders(for: medicine)
                modelContext.delete(medicine)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(medicine.name)?")
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
