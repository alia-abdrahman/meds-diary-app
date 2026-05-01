import SwiftUI
import SwiftData
import PhotosUI

struct MedicineFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(PersonContext.self) private var personContext

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
    @State private var showCamera = false
    @State private var showUnsavedAlert = false

    private let frequencies = ["Daily", "2x Daily", "3x Daily", "Alternate Days", "Weekly", "As Needed"]

    private let initialName: String
    private let initialDosage: String
    private let initialFrequency: String
    private let initialReminderTimes: [Date]
    private let initialNotes: String
    private let initialIsActive: Bool
    private let initialStock: String
    private let initialImageData: Data?

    private var hasChanges: Bool {
        name != initialName ||
        dosage != initialDosage ||
        frequency != initialFrequency ||
        reminderTimes != initialReminderTimes ||
        notes != initialNotes ||
        isActive != initialIsActive ||
        stock != initialStock ||
        imageData != initialImageData
    }

    private var isEditing: Bool { medicine != nil }

    init(medicine: Medicine? = nil) {
        self.medicine = medicine
        let nameVal = medicine?.name ?? ""
        let dosageVal = medicine?.dosage ?? ""
        let frequencyVal = medicine?.frequency ?? "Daily"
        let reminderVal = medicine?.reminderTimes ?? []
        let notesVal = medicine?.notes ?? ""
        let activeVal = medicine?.isActive ?? true
        let stockValue = medicine?.stock ?? 0
        let stockVal = stockValue > 0 ? "\(stockValue)" : ""
        let imageVal = medicine?.imageData

        _name = State(initialValue: nameVal)
        _dosage = State(initialValue: dosageVal)
        _frequency = State(initialValue: frequencyVal)
        _reminderTimes = State(initialValue: reminderVal)
        _notes = State(initialValue: notesVal)
        _isActive = State(initialValue: activeVal)
        _stock = State(initialValue: stockVal)
        _imageData = State(initialValue: imageVal)
        if let data = imageVal {
            _cachedImage = State(initialValue: UIImage(data: data))
        }

        initialName = nameVal
        initialDosage = dosageVal
        initialFrequency = frequencyVal
        initialReminderTimes = reminderVal
        initialNotes = notesVal
        initialIsActive = activeVal
        initialStock = stockVal
        initialImageData = imageVal
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // MARK: - Header
                    HStack {
                        Button {
                            if hasChanges {
                                showUnsavedAlert = true
                            } else {
                                dismiss()
                            }
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

                        Text(isEditing ? "Edit Medicine" : "New Medicine")
                            .font(.poppins(.bold, size: 20))
                            .foregroundStyle(.primary)

                        Spacer()

                        Color.clear.frame(width: 40, height: 40)
                    }
                    .padding(.top, 8)

                    // MARK: - Medicine Details
                    Text("MEDICINE DETAILS")
                        .font(.poppins(.medium, size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    VStack(spacing: 0) {
                        // Name
                        formRow(icon: "pill.fill", iconColor: PastelTheme.dark, iconBg: PastelTheme.primary.opacity(0.2), label: "Name") {
                            TextField("Medicine name", text: $name)
                                .font(.poppins(.semiBold, size: 15))
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.horizontal, 16)

                        // Dosage
                        formRow(icon: "cross.case.fill", iconColor: PastelTheme.dark, iconBg: PastelTheme.primary.opacity(0.2), label: "Dosage") {
                            TextField("500mg (e.g.)", text: $dosage)
                                .font(.poppins(.semiBold, size: 15))
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.horizontal, 16)

                        // Stock
                        formRow(icon: "cross.case", iconColor: PastelTheme.dark, iconBg: PastelTheme.primary.opacity(0.2), label: "Stock") {
                            TextField("30 pills", text: $stock)
                                .font(.poppins(.semiBold, size: 15))
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }

                        Divider().padding(.horizontal, 16)

                        // Frequency
                        HStack(spacing: 10) {
                            Circle()
                                .fill(PastelTheme.primary.opacity(0.2))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "calendar")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundStyle(PastelTheme.dark)
                                )

                            Text("Frequency")
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(.secondary)

                            Spacer()

                            Picker("", selection: $frequency) {
                                ForEach(frequencies, id: \.self) { Text($0) }
                            }
                            .labelsHidden()
                            .tint(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Active Toggle
                    HStack(spacing: 10) {
                        Circle()
                            .fill((isActive ? PastelTheme.green : PastelTheme.gray).opacity(0.2))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(isActive ? PastelTheme.green : PastelTheme.gray)
                            )

                        Text("Active")
                            .font(.poppins(.medium, size: 14))
                            .foregroundStyle(.secondary)

                        Spacer()

                        Toggle("", isOn: $isActive)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Image
                    VStack(alignment: .leading, spacing: 8) {
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

                        HStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                    Text("Choose Photo")
                                }
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(PastelTheme.dark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }

                            Button {
                                showCamera = true
                            } label: {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Take Photo")
                                }
                                .font(.poppins(.medium, size: 14))
                                .foregroundStyle(PastelTheme.dark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                            }
                        }
                    }

                    // MARK: - Reminder Times
                    Text("REMINDER TIMES")
                        .font(.poppins(.medium, size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(reminderTimes.indices, id: \.self) { index in
                            HStack {
                                DatePicker(
                                    "Reminder \(index + 1)",
                                    selection: $reminderTimes[index],
                                    displayedComponents: .hourAndMinute
                                )
                                .font(.poppins(.regular, size: 15))

                                Button(role: .destructive) {
                                    reminderTimes.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)

                            if index < reminderTimes.count - 1 {
                                Divider().padding(.horizontal, 16)
                            }
                        }

                        if !reminderTimes.isEmpty {
                            Divider().padding(.horizontal, 16)
                        }

                        Button {
                            reminderTimes.append(Date())
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Add Reminder Time")
                                    .font(.poppins(.medium, size: 14))
                            }
                            .foregroundStyle(PastelTheme.dark)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    // MARK: - Notes
                    Text("NOTES (OPTIONAL)")
                        .font(.poppins(.medium, size: 12))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)

                    TextField("Add any notes about this medicine", text: $notes, axis: .vertical)
                        .font(.poppins(.regular, size: 15))
                        .lineLimit(3...6)
                        .padding(14)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
                .padding()
                .padding(.bottom, 10)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollContentBackground(.hidden)

            // MARK: - Save Button
            Button { save() } label: {
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
            .padding(.top, 10)
            .padding(.bottom, 24)
        }
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .background(PastelTheme.gradient.ignoresSafeArea())
        .alert("Unsaved Changes", isPresented: $showUnsavedAlert) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Save") { save() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You have unsaved changes. What would you like to do?")
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                imageData = image.jpegData(compressionQuality: 0.8)
            }
            .ignoresSafeArea()
        }
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

    // MARK: - Form Row

    private func formRow<Content: View>(icon: String, iconColor: Color, iconBg: Color, label: String, @ViewBuilder content: () -> Content) -> some View {
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

            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }

    // MARK: - Save

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
            savedMedicine.personId = personContext.activePersonID
            modelContext.insert(savedMedicine)
        }

        Task {
            await notificationManager.requestAuthorization()
            let allMedicines = (try? modelContext.fetch(FetchDescriptor<Medicine>())) ?? []
            let allSupplements = (try? modelContext.fetch(FetchDescriptor<Supplement>())) ?? []
            let allPeople = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
            await notificationManager.scheduleAllReminders(medicines: allMedicines, supplements: allSupplements, people: allPeople)
        }

        dismiss()
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        MedicineFormView()
    }
    .modelContainer(for: [Medicine.self, Supplement.self, Person.self], inMemory: true)
    .environment(NotificationManager())
    .environment(PersonContext())
}
