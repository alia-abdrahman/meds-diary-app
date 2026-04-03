import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Sub-views

private struct SupplementDetailsCard: View {
    @Binding var name: String
    @Binding var dosage: String
    @Binding var stock: String
    @Binding var frequency: String
    let frequencies: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supplement Details")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            TextField("Name", text: $name)
                .font(.poppins(.regular, size: 15))
                .padding(.vertical, 8)

            Divider()

            TextField("Dosage (e.g. 1000mg)", text: $dosage)
                .font(.poppins(.regular, size: 15))
                .padding(.vertical, 8)

            Divider()

            TextField("Stock (number of pills)", text: $stock)
                .font(.poppins(.regular, size: 15))
                .keyboardType(.numberPad)
                .padding(.vertical, 8)

            Divider()

            Picker("Frequency", selection: $frequency) {
                ForEach(frequencies, id: \.self) { Text($0) }
            }
            .font(.poppins(.regular, size: 15))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct SupplementRemindersCard: View {
    @Binding var reminderTimes: [Date]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Reminders")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            ReminderTimePicker(reminderTimes: $reminderTimes)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct SupplementNotesCard: View {
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            TextField("Notes", text: $notes, axis: .vertical)
                .font(.poppins(.regular, size: 15))
                .lineLimit(3...6)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(PastelTheme.light.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct SupplementImageCard: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var imageData: Data?
    let cachedImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Image")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            if let uiImage = cachedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity, maxHeight: 200)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        imageData = nil
                        selectedPhoto = nil
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 28, height: 28)
                            .background(Color(white: 0.35))
                            .clipShape(Circle())
                    }
                    .offset(x: -4, y: 4)
                }
            }

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                HStack {
                    Image(systemName: "camera.fill")
                    Text(imageData != nil ? "Change Photo" : "Upload Photo")
                }
                .font(.poppins(.medium, size: 15))
                .foregroundStyle(PastelTheme.dark)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(PastelTheme.light.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct SupplementActiveToggleCard: View {
    @Binding var isActive: Bool

    var body: some View {
        HStack {
            Toggle("Active", isOn: $isActive)
                .font(.poppins(.regular, size: 15))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct SupplementFormSaveButton: View {
    let name: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            Text("Save")
                .font(.poppins(.semiBold, size: 16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(name.isEmpty ? PastelTheme.dark.opacity(0.4) : PastelTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressDownButtonStyle())
        .disabled(name.isEmpty)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Main View

struct SupplementFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let supplement: Supplement?

    @State private var name: String
    @State private var dosage: String
    @State private var frequency: String
    @State private var reminderTimes: [Date]
    @State private var notes: String
    @State private var isActive: Bool
    @State private var stock: String
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var cachedImage: UIImage?

    private let frequencies = ["Daily", "2x Daily", "3x Daily", "Weekly", "As Needed"]

    init(supplement: Supplement? = nil) {
        self.supplement = supplement
        _name = State(initialValue: supplement?.name ?? "")
        _dosage = State(initialValue: supplement?.dosage ?? "")
        _frequency = State(initialValue: supplement?.frequency ?? "Daily")
        _reminderTimes = State(initialValue: supplement?.reminderTimes ?? [])
        _notes = State(initialValue: supplement?.notes ?? "")
        _isActive = State(initialValue: supplement?.isActive ?? true)
        let stockValue = supplement?.stock ?? 0
        _stock = State(initialValue: stockValue > 0 ? "\(stockValue)" : "")
        _imageData = State(initialValue: supplement?.imageData)
        if let data = supplement?.imageData {
            _cachedImage = State(initialValue: UIImage(data: data))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    SupplementDetailsCard(
                        name: $name,
                        dosage: $dosage,
                        stock: $stock,
                        frequency: $frequency,
                        frequencies: frequencies
                    )

                    SupplementRemindersCard(reminderTimes: $reminderTimes)

                    SupplementNotesCard(notes: $notes)

                    SupplementImageCard(
                        selectedPhoto: $selectedPhoto,
                        imageData: $imageData,
                        cachedImage: cachedImage
                    )

                    SupplementActiveToggleCard(isActive: $isActive)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)

            SupplementFormSaveButton(name: name, action: save)
                .padding(.top, 10)
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .background(PastelTheme.gradient.ignoresSafeArea())
        .navigationTitle(supplement == nil ? "New Supplement" : "Edit Supplement")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    imageData = data
                }
            }
        }
        .onChange(of: imageData) { _, newValue in
            if let newValue {
                cachedImage = UIImage(data: newValue)
            } else {
                cachedImage = nil
            }
        }
    }

    private func save() {
        let savedSupplement: Supplement
        if let supplement {
            supplement.name = name
            supplement.dosage = dosage
            supplement.frequency = frequency
            supplement.reminderTimes = reminderTimes
            supplement.notes = notes
            supplement.isActive = isActive
            supplement.stock = Int(stock) ?? 0
            supplement.imageData = imageData
            savedSupplement = supplement
        } else {
            savedSupplement = Supplement(
                name: name,
                dosage: dosage,
                frequency: frequency,
                reminderTimes: reminderTimes,
                notes: notes,
                isActive: isActive,
                stock: Int(stock) ?? 0
            )
            savedSupplement.imageData = imageData
            modelContext.insert(savedSupplement)
        }

        Task {
            await notificationManager.requestAuthorization()
            await notificationManager.scheduleSupplementReminders(for: savedSupplement)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        SupplementFormView()
    }
    .modelContainer(for: Supplement.self, inMemory: true)
    .environment(NotificationManager())
}
