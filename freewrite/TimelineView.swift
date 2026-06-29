// Swift 5.0
//
//  TimelineView.swift
//  freewrite
//

import SwiftUI

struct TimelineView: View {
    let entries: [HumanEntry]
    let colorScheme: ColorScheme
    let onSelectEntry: (HumanEntry) -> Void
    let onDismiss: () -> Void

    private struct MonthGroup: Identifiable {
        let id: String // "yyyy-MM"
        let title: String // e.g. "February 2025"
        let entries: [HumanEntry]
    }

    private var monthGroups: [MonthGroup] {
        let timestampFormatter = DateFormatter()
        timestampFormatter.locale = Locale(identifier: "en_US_POSIX")
        timestampFormatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"

        let monthTitleFormatter = DateFormatter()
        monthTitleFormatter.dateFormat = "MMMM yyyy"

        let monthKeyFormatter = DateFormatter()
        monthKeyFormatter.dateFormat = "yyyy-MM"

        // Parse dates from filenames using the canonical pattern [yyyy-MM-dd-HH-mm-ss]
        var entriesWithDates: [(entry: HumanEntry, date: Date)] = []
        let pattern = #"\[(\d{4}-\d{2}-\d{2}-\d{2}-\d{2}-\d{2})\]"#

        for entry in entries {
            let filename = entry.filename
            if let range = filename.range(of: pattern, options: .regularExpression) {
                let matched = String(filename[range])
                // Strip surrounding brackets
                let inner = String(matched.dropFirst().dropLast())
                if let date = timestampFormatter.date(from: inner) {
                    entriesWithDates.append((entry: entry, date: date))
                }
            }
        }

        // Sort oldest-first for the timeline
        entriesWithDates.sort { $0.date < $1.date }

        // Group by month preserving insertion order
        var groups: [String: (title: String, entries: [HumanEntry])] = [:]
        var orderedKeys: [String] = []

        for (entry, date) in entriesWithDates {
            let key = monthKeyFormatter.string(from: date)
            if groups[key] == nil {
                groups[key] = (title: monthTitleFormatter.string(from: date), entries: [])
                orderedKeys.append(key)
            }
            groups[key]!.entries.append(entry)
        }

        return orderedKeys.map { key in
            MonthGroup(
                id: key,
                title: groups[key]!.title,
                entries: groups[key]!.entries
            )
        }
    }

    private var textColor: Color {
        colorScheme == .light
            ? Color(red: 0.20, green: 0.20, blue: 0.20)
            : Color(red: 0.9, green: 0.9, blue: 0.9)
    }

    var body: some View {
        ZStack {
            Color(colorScheme == .light ? NSColor.white : NSColor.black)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Timeline")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(textColor)

                    Spacer()

                    Button(action: onDismiss) {
                        Text("Close")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)

                Divider()

                if monthGroups.isEmpty {
                    VStack {
                        Spacer()
                        Text("No entries yet.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(monthGroups) { group in
                                // Month section header
                                Text(group.title)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)
                                    .padding(.top, 20)
                                    .padding(.bottom, 8)

                                ForEach(group.entries) { entry in
                                    Button(action: {
                                        onSelectEntry(entry)
                                        onDismiss()
                                    }) {
                                        HStack(spacing: 12) {
                                            Text(entry.date)
                                                .font(.system(size: 13))
                                                .foregroundColor(.secondary)
                                                .frame(width: 54, alignment: .leading)

                                            Text(entry.previewText.isEmpty ? "Empty entry" : entry.previewText)
                                                .font(.system(size: 13))
                                                .foregroundColor(textColor)
                                                .lineLimit(1)

                                            Spacer()

                                            if entry.entryType == .video {
                                                Image(systemName: "video.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 8)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .onHover { hovering in
                                        if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
                                    }
                                }
                            }

                            // Bottom padding
                            Spacer()
                                .frame(height: 24)
                        }
                    }
                    .scrollIndicators(.never)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .preferredColorScheme(colorScheme)
    }
}
