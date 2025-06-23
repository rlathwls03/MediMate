//
//  AppDelegate.swift
//  TermProject_2271246_kimsojin
//
//  Created by 김소진 on 5/22/25.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseStorage
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        // Firebase 초기화
        FirebaseApp.configure()
        
        Firestore.firestore().collection("test").document("name").setData(["name":"So Jin Kim"])
        
        // 샘플 데이터 최초 1회 업로드
        if !UserDefaults.standard.bool(forKey: "SampleDataUploaded") {
            FirebaseService.shared.uploadSampleMedicineData()
            UserDefaults.standard.set(true, forKey: "SampleDataUploaded")
            print("샘플 데이터 업로드 완료 (최초 1회)")
        } else {
            print("샘플 데이터는 이미 업로드됨")
        }
        
        // 알림 권한 요청 및 delegate 설정
        UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
        requestNotificationPermission()
        
        return true
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("알림 권한 허용됨")
            } else {
                print("알림 권한 거부됨: \(error?.localizedDescription ?? "없음")")
            }
        }
    }
    
    // 포그라운드 상태에서도 알림 표시되도록 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // 알림을 배너와 소리로 표시
        completionHandler([.banner, .sound])
    }
    
    // MARK: UISceneSession Lifecycle
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    
}

