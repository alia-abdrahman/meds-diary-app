import SwiftUI
import SwiftData
import PhotosUI

// MARK: - Sub-views

private struct MedicineDetailsCard: View {
    @Binding var name: String
    @Binding var dosage: String
    @Binding var stock: String
    @Binding var frequency: String
    let frequencies: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Medicine Details")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            TextField("Name", text: $name)
                .font(.poppins(.regular, size: 15))
                .padding(.vertical, 8)

            Divider()

            TextField("Dosage (e.g. 500mg)", text: $dosage)
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

private struct MedicineRemindersCard: View {
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

private struct MedicineNotesCard: View {
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

private struct MedicineImageCard: View {
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

private struct MedicineActiveToggleCard: View {
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

private struct MedicineFormSaveButton: View {
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

struct MedicineFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager

    let medicine: Medicine?

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

    init(medicine: Medicine? = nil) {
        self.medicine = medicine
        _name = State(initialValue: medicine?.name ?? "")
        _dosage = State(initialValue: medicine?.dosage ?? "")
        _frequency = State(initialValue: medicine?.frequency ?? "Daily")
        _reminderTimes = State(initialValue: medicine?.reminderTimes ?? [])
        _notes = State(initialValue: medicine?.notes ?? "")
        _isActive = State(initialValue: medicine?.isActive ?? true)
        let stockValue = medicine?.stock ?? 0
        _stock = State(initialValue: stockValue > 0 ? "\(stockValue)" : "")
        _imageData = State(initialValue: medicine?.imageData)
        if let data = medicine?.imageData {
            _cachedImage = State(initialValue: UIImage(data: data))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    MedicineDetailsCard(
                        name: $name,
                        dosage: $dosage,
                        stock: $stock,
                        frequency: $frequency,
                        frequencies: frequencies
                    )

                    MedicineRemindersCard(reminderTimes: $reminderTimes)

                    MedicineNotesCard(notes: $notes)

                    MedicineImageCard(
                        selectedPhoto: $selectedPhoto,
                        imageData: $imageData,
                        cachedImage: cachedImage
                    )

                    MedicineActiveToggleCard(isActive: $isActive)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)

            MedicineFormSaveButton(name: name, action: save)
                .padding(.top, 10)
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .background(PastelTheme.gradient.ignoresSafeArea())
        .navigationTitle(medicine == nil ? "New Medicine" : "Edit Medicine")
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
        let savedMedicine: Medicine
        if let medicine {
            medicine.name = name
            medicine.dosage = dosage
            medicine.frequency = frequency
            medicine.reminderTimes = reminderTimes
            medicine.notes = notes
            medicine.isActive = isActive
            medicine.stock = Int(stock) ?? 0
            medicine.imageData = imageData
            savedMedicine = medicine
        } else {
            savedMedicine = Medicine(
                name: name,
                dosage: dosage,
                frequency: frequency,
                reminderTimes: reminderTimes,
                notes: notes,
                isActive: isActive,
                stock: Int(stock) ?? 0
            )
            savedMedicine.imageData = imageData
            modelContext.insert(savedMedicine)
        }

        Task {
            await notificationManager.requestAuthorization()
            await notificationManager.scheduleMedicineReminders(for: savedMedicine)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        MedicineFormView()
    }
    .modelContainer(for: Medicine.self, inMemory: true)
    .environment(NotificationManager())
}
