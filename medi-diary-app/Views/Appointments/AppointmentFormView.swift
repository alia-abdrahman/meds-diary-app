import SwiftUI
import SwiftData

struct AppointmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(NotificationManager.self) private var notificationManager
    @Environment(PersonContext.self) private var personContext

    let appointment: Appointment?

    @State private var date: Date
    @State private var time: Date
    @State private var discipline: String
    @State private var notes: String
    @State private var hospitalName: String
    @State private var doctorName: String
    @State private var status: String
    @State private var showUnsavedAlert = false

    private let initialDiscipline: String
    private let initialNotes: String
    private let initialHospitalName: String
    private let initialDoctorName: String
    private let initialStatus: String
    private let initialDate: Date
    private let initialTime: Date

    private var hasChanges: Bool {
        discipline != initialDiscipline ||
        notes != initialNotes ||
        hospitalName != initialHospitalName ||
        doctorName != initialDoctorName ||
        status != initialStatus ||
        Calendar.current.compare(date, to: initialDate, toGranularity: .minute) != .orderedSame ||
        Calendar.current.compare(time, to: initialTime, toGranularity: .minute) != .orderedSame
    }

    private var isEditing: Bool { appointment != nil }

    init(appointment: Appointment? = nil) {
        self.appointment = appointment
        let dateVal = appointment?.date ?? Date()
        let timeVal = appointment?.time ?? Date()
        let disciplineVal = appointment?.discipline ?? ""
        let notesVal = appointment?.notes ?? ""
        let hospitalVal = appointment?.hospitalName ?? ""
        let doctorVal = appointment?.doctorName ?? ""
        let statusVal = appointment?.status ?? "upcoming"

        _date = State(initialValue: dateVal)
        _time = State(initialValue: timeVal)
        _discipline = State(initialValue: disciplineVal)
        _notes = State(initialValue: notesVal)
        _hospitalName = State(initialValue: hospitalVal)
        _doctorName = State(initialValue: doctorVal)
        _status = State(initialValue: statusVal)

        initialDate = dateVal
        initialTime = timeVal
        initialDiscipline = disciplineVal
        initialNotes = notesVal
        initialHospitalName = hospitalVal
        initialDoctorName = doctorVal
        initialStatus = statusVal
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

                    Text(isEditing ? "Edit Appointment" : "New Appointment")
                        .font(.poppins(.bold, size: 20))
                        .foregroundStyle(.primary)

                    Spacer()

                    // Invisible spacer to balance the back button
                    Color.clear.frame(width: 40, height: 40)
                }
                .padding(.top, 8)

                // MARK: - Appointment Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Appointment Details")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(.primary)

                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Text("Date")
                            .font(.poppins(.medium, size: 14))
                            .foregroundStyle(.primary)

                        Spacer()

                        DatePicker("", selection: $date, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                            .labelsHidden()
                            .font(.poppins(.regular, size: 14))
                    }

                    Divider()

                    HStack(spacing: 10) {
                        Image(systemName: "clock")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                            .frame(width: 24)

                        Text("Time")
                            .font(.poppins(.medium, size: 14))
                            .foregroundStyle(.primary)

                        Spacer()

                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .labelsHidden()
                            .font(.poppins(.regular, size: 14))
                    }
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Department
                VStack(alignment: .leading, spacing: 8) {
                    Label("Department", systemImage: "stethoscope")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(.primary)

                    DisciplinePicker(selection: $discipline)
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Hospital
                VStack(alignment: .leading, spacing: 8) {
                    Label("Hospital", systemImage: "building.2")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(.primary)

                    TextField("Enter hospital name", text: $hospitalName)
                        .font(.poppins(.regular, size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Doctor's Name
                VStack(alignment: .leading, spacing: 8) {
                    Label("Doctor's Name", systemImage: "person")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(.primary)

                    TextField("Enter doctor\u{2019}s name", text: $doctorName)
                        .font(.poppins(.regular, size: 15))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Notes
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Label("Notes", systemImage: "doc.text")
                            .font(.poppins(.semiBold, size: 15))
                            .foregroundStyle(.primary)

                        Text("(Optional)")
                            .font(.poppins(.regular, size: 13))
                            .foregroundStyle(.secondary)
                    }

                    TextField("Add any notes about this appointment", text: $notes, axis: .vertical)
                        .font(.poppins(.regular, size: 15))
                        .lineLimit(3...6)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .background(Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))
                }
                .padding()
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                // MARK: - Status
                VStack(alignment: .leading, spacing: 10) {
                    Label("Status", systemImage: "square.grid.2x2")
                        .font(.poppins(.semiBold, size: 15))
                        .foregroundStyle(.primary)

                    HStack(spacing: 0) {
                        statusSegment("Upcoming", value: "upcoming")
                        statusSegment("Completed", value: "attended")
                        statusSegment("Cancelled", value: "cancelled")
                    }
                    .background(PastelTheme.light.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))
                }
                .padding()
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
            Button {
                save()
            } label: {
                Text("Save")
                    .font(.poppins(.semiBold, size: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(discipline.isEmpty ? PastelTheme.dark.opacity(0.4) : PastelTheme.dark)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(PressDownButtonStyle())
            .disabled(discipline.isEmpty)
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
    }

    // MARK: - Status Segment

    private func statusSegment(_ label: String, value: String) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                status = value
            }
        } label: {
            Text(label)
                .font(.poppins(.medium, size: 13))
                .foregroundStyle(status == value ? PastelTheme.dark : .secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(status == value ? .white : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save

    private func save() {
        let savedAppointment: Appointment
        if let appointment {
            appointment.date = date
            appointment.time = time
            appointment.discipline = discipline
            appointment.notes = notes
            appointment.hospitalName = hospitalName
            appointment.doctorName = doctorName
            appointment.status = status
            savedAppointment = appointment
        } else {
            savedAppointment = Appointment(
                date: date,
                time: time,
                discipline: discipline,
                notes: notes,
                hospitalName: hospitalName,
                doctorName: doctorName,
                status: status
            )
            savedAppointment.personId = personContext.activePersonID
            modelContext.insert(savedAppointment)
        }

        let personName: String? = {
            guard let id = savedAppointment.personId,
                  let person = (try? modelContext.fetch(FetchDescriptor<Person>()))?.first(where: { $0.id == id }) else {
                return nil
            }
            let allPeople = (try? modelContext.fetch(FetchDescriptor<Person>())) ?? []
            return allPeople.count > 1 ? person.displayName : nil
        }()

        Task {
            await notificationManager.requestAuthorization()
            await notificationManager.scheduleAppointmentReminders(for: savedAppointment, personName: personName)
        }

        dismiss()
    }
}

#Preview {
    NavigationStack {
        AppointmentFormView()
    }
    .modelContainer(for: [Appointment.self, Person.self], inMemory: true)
    .environment(NotificationManager())
    .environment(PersonContext())
}
