//
//  NotificationService.swift
//  Aura Energy Revealed
//
//  A gentle daily reflection nudge — quiet hours respected, never a nag.
//

import Foundation
import UserNotifications

enum NotificationService {

    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    static func scheduleDailyReflection(hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["dailyReflection"])

        let content = UNMutableNotificationContent()
        content.title = "A quiet moment"
        content.body = "Your aura is waiting to be read. Take a breath and see today's colours."
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyReflection", content: content, trigger: trigger)
        center.add(request)
    }

    static func cancelDailyReflection() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["dailyReflection"])
    }
}
