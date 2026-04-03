import SwiftUI
import SwiftData

// MARK: - Sub-views

private struct AppointmentDateTimeCard: View {
    @Binding var date: Date
    @Binding var time: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Appointment Details")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            DatePicker("Date", selection: $date, in: Calendar.current.startOfDay(for: Date())..., displayedComponents: .date)
                .font(.poppins(.regular, size: 15))

            Divider()

            DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                .font(.poppins(.regular, size: 15))
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

private struct AppointmentHospitalCard: View {
    @Binding var hospitalName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Hospital")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            TextField("Enter your hospital name here", text: $hospitalName)
                .font(.poppins(.regular, size: 15))
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

private struct AppointmentDoctorCard: View {
    @Binding var doctorName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Doctor's Name")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            TextField("Enter doctor's name", text: $doctorName)
                .font(.poppins(.regular, size: 15))
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

private struct AppointmentNotesCard: View {
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

private struct AppointmentFormSaveButton: View {
    let discipline: String
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
                .background(discipline.isEmpty ? PastelTheme.dark.opacity(0.4) : PastelTheme.dark)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(PressDownButtonStyle())
        .disabled(discipline.isEmpty)
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
}

// MARK: - Main View

struct AppointmentFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let appointment: Appointment?

    @State private var date: Date
    @State private var time: Date
    @State private var discipline: String
    @State private var notes: String
    @State private var hospitalName: String
    @State private var doctorName: String
    @State private var status: String

    init(appointment: Appointment? = nil) {
        self.appointment = appointment
        _date = State(initialValue: appointment?.date ?? Date())
        _time = State(initialValue: appointment?.time ?? Date())
        _discipline = State(initialValue: appointment?.discipline ?? "")
        _notes = State(initialValue: appointment?.notes ?? "")
        _hospitalName = State(initialValue: appointment?.hospitalName ?? "")
        _doctorName = State(initialValue: appointment?.doctorName ?? "")
        _status = State(initialValue: appointment?.status ?? "upcoming")
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    AppointmentDateTimeCard(date: $date, time: $time)

                    // Department
                    DisciplinePicker(selection: $discipline)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    AppointmentHospitalCard(hospitalName: $hospitalName)

                    AppointmentDoctorCard(doctorName: $doctorName)

                    // Status
                    StatusPicker(selection: $status)
                        .padding()
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                    AppointmentNotesCard(notes: $notes)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.immediately)

            AppointmentFormSaveButton(discipline: discipline, action: save)
                .padding(.top, 10)
        }
        .ignoresSafeArea(.keyboard)
        .onTapGesture { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        .background(PastelTheme.gradient.ignoresSafeArea())
        .navigationTitle(appointment == nil ? "New Appointment" : "Edit Appointment")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func save() {
        if let appointment {
            appointment.date = date
            appointment.time = time
            appointment.discipline = discipline
            appointment.notes = notes
            appointment.hospitalName = hospitalName
            appointment.doctorName = doctorName
            appointment.status = status
        } else {
            let newAppointment = Appointment(
                date: date,
                time: time,
                discipline: discipline,
                notes: notes,
                hospitalName: hospitalName,
                doctorName: doctorName,
                status: status
            )
            modelContext.insert(newAppointment)
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AppointmentFormView()
    }
    .modelContainer(for: Appointment.self, inMemory: true)
}
