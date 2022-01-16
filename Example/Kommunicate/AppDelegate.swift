//
//  AppDelegate.swift
//  Kommunicate
//
//  Created by mukeshthawani on 02/19/2018.
//  Copyright (c) 2018 mukeshthawani. All rights reserved.
//
#if os(iOS)
import UIKit
import Firebase
import FirebaseMessaging
import UserNotifications
import Kommunicate

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UNUserNotificationCenterDelegate {

    var window: UIWindow?

    // Pass your App Id here. You can get the App Id from install section in the dashboard.
    var appId = ""

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        setUpNavigationBarAppearance()

        
//        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
               
       if #available(iOS 10.0, *) {
           UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
               if let error = error {
                   print("D'oh: \(error.localizedDescription)")
               } else {
                   DispatchQueue.main.async {
                       application.registerForRemoteNotifications()
                   }
               }
           }
       }
       if #available(iOS 10.0, *) {
           UNUserNotificationCenter.current().delegate = self
       }
               

        KMPushNotificationHandler.shared.dataConnectionNotificationHandlerWith(Kommunicate.defaultConfiguration, Kommunicate.kmConversationViewConfiguration)
        let kmApplocalNotificationHandler : KMAppLocalNotification =  KMAppLocalNotification.appLocalNotificationHandler()
        kmApplocalNotificationHandler.dataConnectionNotificationHandler()

        if (KMUserDefaultHandler.isLoggedIn())
        {
            // Get login screen from storyboard and present it
            if let viewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "NavViewController") as? UINavigationController {
                viewController.modalPresentationStyle = .fullScreen
                self.window?.makeKeyAndVisible();
                self.window?.rootViewController!.present(viewController, animated:true, completion: nil)
            }
        }
        return true
    }

   
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        print("APP_ENTER_IN_BACKGROUND")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_BACKGROUND"), object: nil)

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        KMPushNotificationService.applicationEntersForeground()
                print("APP_ENTER_IN_FOREGROUND")
        NotificationCenter.default.post(name: Notification.Name(rawValue: "APP_ENTER_IN_FOREGROUND"), object: nil)
                UIApplication.shared.applicationIconBadgeNumber = 0
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        KMDbHandler.sharedInstance().saveContext()
    }

     func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
           
           print("DEVICE_TOKEN_DATA :: \(deviceToken.description)")  // (SWIFT = 3) : TOKEN PARSING
           var deviceTokenString: String = ""
           for i in 0..<deviceToken.count
           {
               deviceTokenString += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
           }
           print("DEVICE_TOKEN_STRING :: \(deviceTokenString)")

           if (KMUserDefaultHandler.getApnDeviceToken() != deviceTokenString)
           {
               let kmRegisterUserClientService: KMRegisterUserClientService = KMRegisterUserClientService()
               kmRegisterUserClientService.updateApnDeviceToken(withCompletion: deviceTokenString, withCompletion: { (response, error) in
                   print ("REGISTRATION_RESPONSE :: \(String(describing: response))")
               })
           }
           Messaging.messaging().apnsToken = deviceToken;
    }
    
     func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("Failed to register for notifications: \(error.localizedDescription)")
    }

    @available(iOS 10.0, *)
       func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
          
          let userInfo = notification.request.content.userInfo
          print(userInfo)
          
          let service = KMPushNotificationService()
          let dict = notification.request.content.userInfo
          
          if service.isKommunicateNotification(dict) {
              service.processPushNotification(dict, appState: UIApplication.shared.applicationState)
              completionHandler([])
              return
          } else {
              Messaging.messaging().appDidReceiveMessage(userInfo)
          }
          completionHandler([.sound, .badge, .alert])
      }

    @available(iOS 10.0, *)
        func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
           let userInfo = response.notification.request.content.userInfo
           print(userInfo)
           let service = KMPushNotificationService()
           let dict = response.notification.request.content.userInfo
           if service.isApplozicNotification(dict) {
               service.processPushNotification(dict, appState: UIApplication.shared.applicationState)
           } else {
               Messaging.messaging().appDidReceiveMessage(userInfo)
           }
           completionHandler()
       }
    
     func application(_ application: UIApplication,
                                  didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                                  fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult)
                                    -> Void) {
            
            if let messageID = userInfo["gcmMessageIDKey"] {
                print("Message ID: \(messageID)")
            }
            print(userInfo)
            
            let service = KMPushNotificationService()
            if service.isApplozicNotification(userInfo) {
                service.processPushNotification(userInfo, appState: UIApplication.shared.applicationState)
            } else {
                Messaging.messaging().appDidReceiveMessage(userInfo)
            }
            completionHandler(UIBackgroundFetchResult.newData)
        }
    
    

    func setUpNavigationBarAppearance() {

        // App appearance
        let navigationBarProxy = UINavigationBar.appearance()
        navigationBarProxy.isTranslucent = false
        navigationBarProxy.barTintColor = UIColor(red:0.93, green:0.94, blue:0.95, alpha:1.0) // light nav blue
        navigationBarProxy.tintColor = .white
        navigationBarProxy.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]

        // Kommunicate SDK
        let kmNavigationBarProxy = UINavigationBar.appearance(whenContainedInInstancesOf: [KMBaseNavigationViewController.self])
        kmNavigationBarProxy.isTranslucent = false
        navigationBarProxy.tintColor = UIColor.navigationOceanBlue()
        kmNavigationBarProxy.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black]
    }
    

}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
    
    func messaging(_ messaging: Messaging, appDidReceiveMessage message: NSDictionary) {
        print(message)
    }
}
#endif
