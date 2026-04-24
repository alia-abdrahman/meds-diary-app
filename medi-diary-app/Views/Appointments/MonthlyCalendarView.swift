import SwiftUI

struct MonthlyCalendarView: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date?
    let appointmentDates: Set<DateComponents>

    private let calendar = Calendar.current
    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: displayedMonth)
    }

    private var daysInMonth: [DateItem] {
        let range = calendar.range(of: .day, in: .month, for: displayedMonth)!
        let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)

        // Offset for leading blanks (Sunday = 1, so shift to Mon-start: (weekday + 5) % 7)
        let leadingBlanks = (firstWeekday + 5) % 7

        var items: [DateItem] = []

        for _ in 0..<leadingBlanks {
            items.append(DateItem(date: nil))
        }

        for day in range {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)!
            items.append(DateItem(date: date))
        }

        return items
    }

    private var mondayFirstSymbols: [String] {
        // Reorder to Mon, Tue, Wed, Thu, Fri, Sat, Sun
        let symbols = weekdaySymbols
        return Array(symbols[1...]) + [symbols[0]]
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PastelTheme.dark)
                }

                Spacer()

                Text(monthTitle)
                    .font(.poppins(.semiBold, size: 16))
                    .foregroundStyle(PastelTheme.dark)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth)!
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PastelTheme.dark)
                }
            }

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(mondayFirstSymbols, id: \.self) { symbol in
                    Text(String(symbol.prefix(3)))
                        .font(.poppins(.medium, size: 11))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(daysInMonth) { item in
                    if let date = item.date {
                        dayCell(date: date)
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func dayCell(date: Date) -> some View {
        let day = calendar.component(.day, from: date)
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
        let hasAppointment = appointmentDates.contains(calendar.dateComponents([.year, .month, .day], from: date))

        return Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                if isSelected {
                    selectedDate = nil
                } else {
                    selectedDate = date
                }
            }
        } label: {
            VStack(spacing: 3) {
                Text("\(day)")
                    .font(.poppins(isToday ? .bold : .regular, size: 14))
                    .foregroundStyle(
                        isSelected ? .white :
                        isToday ? PastelTheme.dark :
                        .primary
                    )
                    .frame(width: 32, height: 32)
                    .background(
                        Group {
                            if isSelected {
                                Circle().fill(PastelTheme.dark)
                            } else if isToday {
                                Circle().stroke(PastelTheme.dark, lineWidth: 1.5)
                            }
                        }
                    )

                Circle()
                    .fill(hasAppointment ? PastelTheme.primary : .clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
        .frame(height: 40)
    }
}

private struct DateItem: Identifiable {
    let id = UUID()
    let date: Date?
}
