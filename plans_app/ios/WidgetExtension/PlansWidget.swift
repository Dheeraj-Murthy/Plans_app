import WidgetKit
import SwiftUI

// MARK: - Models

struct WidgetTask: Codable {
    let id: String
    let title: String
    let dueDate: Int64?
    let priority: Int
    let isCompleted: Bool
    let projectId: String

    enum CodingKeys: String, CodingKey {
        case id, title, priority, isCompleted, projectId
        case dueDate = "due_date"
    }
}

struct WidgetProject: Codable {
    let id: String
    let name: String
    let colorIndex: Int

    enum CodingKeys: String, CodingKey {
        case id, name
        case colorIndex = "color_index"
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), tasks: [], projects: [], viewTitle: "Inbox")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(loadEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date().addingTimeInterval(900)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    func loadEntry() -> SimpleEntry {
        let ud = UserDefaults(suiteName: "group.com.plansapp")
        let decoder = JSONDecoder()

        let tasks: [WidgetTask] = {
            guard let json = ud?.string(forKey: "widget_tasks_inbox") else { return [] }
            return (try? decoder.decode([WidgetTask].self, from: Data(json.utf8))) ?? []
        }()
        let projects: [WidgetProject] = {
            guard let json = ud?.string(forKey: "widget_projects") else { return [] }
            return (try? decoder.decode([WidgetProject].self, from: Data(json.utf8))) ?? []
        }()

        return SimpleEntry(date: Date(), tasks: tasks, projects: projects, viewTitle: "Inbox")
    }
}

// MARK: - Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let projects: [WidgetProject]
    let viewTitle: String
}

// MARK: - Widget View

struct PlansWidgetEntryView: View {
    var entry: Provider.Entry

    private let accent = Color(red: 124 / 255, green: 109 / 255, blue: 242 / 255)
    private let background = Color(red: 27 / 255, green: 29 / 255, blue: 33 / 255)
    private let textPrimary = Color(red: 0.88, green: 0.88, blue: 0.88)
    private let textMuted = Color(red: 0.55, green: 0.55, blue: 0.55)
    private let emptyColor = Color(red: 0.33, green: 0.33, blue: 0.33)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Spacer().frame(height: 8)
            if entry.tasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .padding(16)
        .containerBackground(background, for: .widget)
    }

    private var header: some View {
        HStack {
            Text(entry.viewTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(accent)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("No tasks yet")
                .font(.system(size: 14))
                .foregroundColor(emptyColor)
                .frame(maxWidth: .infinity)
            Spacer()
        }
    }

    private var taskList: some View {
        ForEach(entry.tasks.prefix(6), id: \.id) { task in
            HStack(spacing: 10) {
                checkbox(task: task)
                Text(task.title)
                    .font(.system(size: 15))
                    .foregroundColor(task.isCompleted ? textMuted : textPrimary)
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.vertical, 3)
        }
    }

    private func checkbox(task: WidgetTask) -> some View {
        Group {
            if task.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(accent)
            } else {
                Circle()
                    .stroke(textMuted, lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            }
        }
    }
}

// MARK: - Widget

struct PlansWidget: Widget {
    let kind: String = "PlansWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PlansWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Plans")
        .description("Your tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Bundle

@main
struct PlansWidgetBundle: WidgetBundle {
    var body: some Widget {
        PlansWidget()
    }
}
