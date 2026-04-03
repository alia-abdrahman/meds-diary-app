import SwiftUI

struct StatusPicker: View {
    @Binding var selection: String
    @State private var isExpanded = false

    private let options = ["upcoming", "attended", "missed", "cancelled"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Status")
                .font(.poppins(.semiBold, size: 15))
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                // Header / toggle button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    HStack {
                        Text(selection.capitalized)
                            .font(.poppins(.regular, size: 15))
                            .foregroundStyle(PastelTheme.dark)
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

                    VStack(spacing: 0) {
                        ForEach(options, id: \.self) { option in
                            Button {
                                selection = option
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isExpanded = false
                                }
                            } label: {
                                HStack {
                                    Text(option.capitalized)
                                        .font(.poppins(.regular, size: 15))
                                        .foregroundStyle(PastelTheme.dark)
                                    Spacer()
                                    if selection == option {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(PastelTheme.primary)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 11)
                                .background(selection == option ? PastelTheme.light.opacity(0.4) : .white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(PastelTheme.light, lineWidth: 1))
        }
    }
}
