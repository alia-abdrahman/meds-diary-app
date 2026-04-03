import SwiftUI

struct DisciplinePicker: View {
    @Binding var selection: String
    @State private var isExpanded = false
    @State private var customText = ""
    @State private var showCustomField = false

    private let disciplines = [
        "Psychiatry", "Pulmonology", "D&G", "Medical", "Surgery",
        "Orthopaedics", "ENT", "Ophthalmology", "Dermatology", "Paediatrics",
        "Cardiology", "Neurology", "Endocrinology"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Department")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            if selection.isEmpty && !isExpanded {
                Text("Please select a department")
                    .font(.poppins(.medium, size: 13))
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 0) {
                // Header / toggle button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(displayLabel)
                            .font(.poppins(.regular, size: 15))
                            .foregroundStyle(selection.isEmpty ? .secondary : PastelTheme.dark)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(PastelTheme.dark)
                            .rotationEffect(.degrees(isExpanded ? -180 : 0))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: isExpanded ? 0 : 10))
                }
                .buttonStyle(.plain)

                // Dropdown list
                if isExpanded {
                    Divider()
                        .background(PastelTheme.light)

                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(disciplines, id: \.self) { discipline in
                                dropdownRow(discipline)
                            }
                            dropdownRow("Other", isOther: true)
                        }
                    }
                    .frame(maxHeight: 220)
                    .background(.white)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))

            if showCustomField {
                TextField("Custom department", text: customTextBinding)
                    .font(.poppins(.regular, size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))
            }
        }
    }

    private var customTextBinding: Binding<String> {
        Binding(
            get: { customText },
            set: { newValue in
                customText = newValue
                selection = newValue
            }
        )
    }

    private var displayLabel: String {
        if showCustomField {
            return customText.isEmpty ? "Other" : customText
        }
        return selection.isEmpty ? "Select department" : selection
    }

    private func dropdownRow(_ label: String, isOther: Bool = false) -> some View {
        let isSelected = isOther ? showCustomField : (selection == label && !showCustomField)
        return Button {
            if isOther {
                showCustomField = true
                selection = customText
            } else {
                showCustomField = false
                selection = label
            }
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded = false
            }
        } label: {
            HStack {
                Text(label)
                    .font(.poppins(.regular, size: 15))
                    .foregroundStyle(PastelTheme.dark)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(PastelTheme.primary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(isSelected ? PastelTheme.light.opacity(0.4) : .white)
        }
        .buttonStyle(.plain)
    }
}
