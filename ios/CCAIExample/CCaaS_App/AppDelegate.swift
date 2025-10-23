//
//  AppDelegate.swift
//  SwiftUIExample
//
//  Created by Jaesung on 6/18/25.
//

import UIKit
import UserNotifications
import CCAIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("App_Log: in didFinishLaunchingWithOptions")
        setupNotificationDelegate()
        return true
    }

    func setupNotificationDelegate() {
        print("App_Log: setting UNUserNotificationCenter delegate")
        UNUserNotificationCenter.current().delegate = self
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNS Token: \(convertDeviceTokenToString(deviceToken: deviceToken))")
        CCAI.shared.pushNotificationService?.updatePushToken(data: deviceToken, type: .apns)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error.localizedDescription)")
        CCAI.shared.pushNotificationService?.updatePushToken(data: nil, type: .apns)
    }

    // Handle the silent push notification when the app is in the background
    @MainActor
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
        print("App_Log: didReceiveRemoteNotification")
        print("User Info: \(userInfo)")
        await CCAI.shared.pushNotificationService?.handlePushNotification(userInfo)
        return .newData
    }

    func convertDeviceTokenToString(deviceToken: Data) -> String {
        return deviceToken.map { String(format: "%02x", $0) }.joined()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle push notification when the app is in the foreground
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        print("App_Log: willPresent")
        let userInfo = notification.request.content.userInfo
        print("User Info: \(userInfo)")
        await CCAI.shared.pushNotificationService?.handlePushNotification(userInfo)
        return []
    }

    // Handle push notification when the app is in the background or terminated (tapped on)
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        print("App_Log: didReceive")
        let userInfo = response.notification.request.content.userInfo
        print("User Info: \(userInfo)")
        await CCAI.shared.pushNotificationService?.handlePushNotification(userInfo)
        print("App_Log: calling handlePushNotification")
    }
}
