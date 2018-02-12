
import Firebase
import UserNotifications
import UIKit
import CoreData
import FirebaseMessaging
import SF_swift_framework

//:Delegate class for application
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    //MARK: Variables
    let gcmMessageIDKey = "gcm.message_id"
    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
    var presentViewController:UIViewController!
    static var sdkLoader:SDKLoader!
    var activityindicater:UIActivityIndicatorView! = nil
    var activityindicaterView:UIView! = nil
    var indicator:Bool = false
    
    //MARK: Application Delegates
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        //Load SDK
        SDKLoader.loadSDK(server: "188.166.251.121", port: 5222)
        //NEtwork reachability
        _ = ReachabilityManager.sharedManager
        ChatterUtil.setNavigationBar()
        
        //Configure Firebase
        FirebaseApp.configure()
        
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = self
        // [END set_messaging_delegate]
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        self.registerForRemoteNotification(application: application)
        
        // [END register_for_notifications]
        
        self.getRootViewController()
        return true
    }
    
    
    
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "SFUserDetail", jid: "", success: { (users:[SFUserDetail]) in
            
            if !users.isEmpty && users[0].login {
                ConnectionManager.getInstance().setNetworkConnectivity(networkConnectivity: true)
                Platform.getInstance().getUserManager().signalNegotiationQueue()
                _  = ConnectionManager.getInstance().reconnectAsync()
            }
        },failure: { (String) in
            print(String)
        })
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    
    
    func applicationWillTerminate(_ application: UIApplication) {
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "SFUserDetail", jid: "", success: { (users:[SFUserDetail]) in
            
            if !users.isEmpty && users[0].login {
                Platform.getInstance().shutdown()
            }
        },failure: { (String) in
            print(String)
        })
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
        //        Platform.shutdown()
        //        SDKLoader.deleteInstance()
    }
    
    
    // [START connect_gcm_service]
    func applicationDidBecomeActive( _ application: UIApplication) {
        
        // Connect to the GCM server to receive non-APNS notifications
        //        GCMService.sharedInstance().connect(handler: { error -> Void in
        //            if let error = error as NSError? {
        //                print("Could not connect to GCM: \(error.localizedDescription)")
        //            } else {
        //                self.connectedToGCM = true
        //                print("Connected to GCM")
        //                // [START_EXCLUDE]
        //                self.subscribeToTopic()
        //                // [END_EXCLUDE]
        //            }
        //        })
    }
    
    // [END connect_gcm_service]
    
    
    // [START disconnect_gcm_service]
    func applicationDidEnterBackground(_ application: UIApplication) {
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "SFUserDetail", jid: "", success: { (users:[SFUserDetail]) in
            
            if !users.isEmpty && users[0].login {
                ConnectionManager.getInstance().setNetworkConnectivity(networkConnectivity: false)
                Platform.getInstance().getUserManager().closeStream()
            }
        },failure: { (String) in
            print(String)
        })
        
        //        GCMService.sharedInstance().disconnect()
        // [START_EXCLUDE]
        //        self.connectedToGCM = false
        // [END_EXCLUDE]
    }
    // [END disconnect_gcm_service]
    
    // [START receive_message]
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        if (UIApplication.shared.applicationState == UIApplicationState.active) || (UIApplication.shared.applicationState == UIApplicationState.inactive) {
            _ = ConnectionManager.getInstance().reconnectAsync()
            
        }
        NotificationReciever.getInstance().collectNotificationData(userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    // [END receive_message]
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // This function is added here only for debugging purposes, and can be removed if swizzling is enabled.
    // If swizzling is disabled then this function must be implemented so that the APNs token can be paired to
    // the FCM registration token.
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("APNs token retrieved: \(deviceToken)")
        
        let  token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print(token)
        // With swizzling disabled you must set the APNs token here.
        Messaging.messaging().apnsToken = deviceToken
        
        // [START log_fcm_reg_token]
        let fcmtoken = Messaging.messaging().fcmToken
        print("FCM token: \(fcmtoken ?? "")")
        // [END log_fcm_reg_token]
        //SET TOKEN
        UserDefaults.standard.set(fcmtoken, forKey: "NOTIFICATIONTOKEN")
    }
    
    
    // MARK: - Core Data stack
    
    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
         */
        let container = NSPersistentContainer(name: "Beach")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        let context = persistentContainer.viewContext
        let sfContext = SFCoreDataManager.sharedInstance.getContext()
        if context.hasChanges {
            do {
                try context.save()
                if sfContext.hasChanges {
                    try sfContext.save()
                }
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    
    ///MARK:  Get Root ViewController Of App
    func getRootViewController(){
        SFCoreDataManager.sharedInstance.getInfoFromDataBase(entityName: "SFUserDetail", jid: "", success: { (users:[SFUserDetail]) in
            
            if !users.isEmpty && users[0].login {
                do{
                    try Platform.getInstance().getUserManager().reconnectLogin(userName: users[0].user_name!, password: users[0].password!,  domain:users[0].domain!, success:  { (String) in
                        do{
                            
                            _ = try Platform.getInstance().getUserManager().sendGetRosterRequest(version: UserDefaults.standard.object(forKey: "RosterVersion") as! Int)
                            let corrId = UUID().uuidString
                            _ = Platform.getInstance().getUserManager().sendGetChatRoomsRequest(corrId: corrId)
                            ChatterUtil.sendNotificationKey(pushNotificationService: PushNotificationService.FCM)
                        }
                        catch {
                            
                        }
                    }, failure: { (str) in
                        print(str)
                    })
                    
                    let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
                    let vc = (storyBoard.instantiateViewController(withIdentifier: "ChatterTabBarController") as? ChatterTabBarController)!
                    self.window!.rootViewController = vc
                }
                catch {
                    
                }
            }
            else {
                
                let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
                
                let objLoginViewController = (storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController)!;
                self.window!.rootViewController = objLoginViewController
            }
        },failure: { (str) in
            let storyBoard:UIStoryboard = UIStoryboard(name: "Main", bundle: nil);
            
            let objLoginViewController = (storyBoard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController)!;
            self.window!.rootViewController = objLoginViewController
        })
    }
    
    //MARK: Resister for remote notification
    func registerForRemoteNotification(application:UIApplication)  {
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
            
            let authOptions: UNAuthorizationOptions = [.alert, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
                UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
    }
    // MARK: - Activity indicator
    //: Add Activity indicator in view controller
    func addActivitiIndicaterView() {
        print("add indicator")
        if indicator == false {
            self.activityindicaterView = UIView.init(frame: CGRect(x: 0, y: 0, width: (self.window?.frame.size.width)!, height: (self.window?.frame.size.height)!))
            
            self.activityindicaterView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
            
            self.activityindicater = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
            
            self.activityindicater.center = ((self.window?.center)!)
            
            self.activityindicaterView.addSubview(self.activityindicater)
            self.window?.addSubview(self.activityindicaterView)
            self.activityindicater.startAnimating()
            indicator = true
        }
        else {
            DispatchQueue.main.async {
                if (self.activityindicater != nil)
                {
                    if self.indicator == false {
                        self.activityindicater.stopAnimating()
                        self.activityindicaterView.isHidden = true
                        self.activityindicaterView = nil
                        self.activityindicater = nil
                        
                        self.activityindicaterView = UIView.init(frame: CGRect(x: 0, y: 0, width: (self.window?.frame.size.width)!, height: (self.window?.frame.size.height)!))
                        
                        self.activityindicaterView.backgroundColor = UIColor.init(red: 0, green: 0, blue: 0, alpha: 0.5)
                        
                        self.activityindicater = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.whiteLarge)
                        
                        self.activityindicater.center = ((self.window?.center)!)
                        
                        self.activityindicaterView.addSubview(self.activityindicater)
                        self.window?.addSubview(self.activityindicaterView)
                        self.activityindicater.startAnimating()
                        self.indicator = true
                    }
                }
                
            }
            
        }
    }
    
    // : - Add Activity indicator in view controller
    func hideActivitiIndicaterView()  {
        print("hide indicator")
        DispatchQueue.main.async {
            if (self.activityindicater != nil)
            {
                self.activityindicater.stopAnimating()
                self.activityindicaterView.isHidden = true
                self.activityindicaterView = nil
                self.activityindicater = nil
                self.indicator = false
            }
        }
    }
}


// [START ios_10_message_handling]
@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        if presentViewController != nil && presentViewController.isKind(of: UserChatViewController.self) && userInfo["from_jid"] != nil && userInfo["from_jid"] as! String == (presentViewController as! UserChatViewController).getJid() && (UIApplication.shared.applicationState != UIApplicationState.background) {
            completionHandler([])
        }
            // Change this to your preferred presentation option
        else {
            completionHandler([.alert,.sound])
        }
    }
    
    
    //Handel Notification
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        _ = response.notification.request.content
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        let _:UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabbar:UITabBarController = self.window?.rootViewController as! UITabBarController
        tabbar.selectedIndex = 0
        let navC = tabbar.viewControllers![0] as! UINavigationController
        //            navC.popToRootViewController(animated: false)
        
        let activeChatViewController = navC.viewControllers[0] as! ConversationViewController
        activeChatViewController.navigateToUserChat(userJid: userInfo["from_jid"] as! String)
        completionHandler()
    }
}
// [END ios_10_message_handling]


extension AppDelegate : MessagingDelegate {
    
    // [START refresh_token]
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
    }
    // [END refresh_token]
    
    // [START ios_10_data_message]
    // Receive data messages on iOS 10+ directly from FCM (bypassing APNs) when the app is in the foreground.
    // To enable direct data messages, you can set Messaging.messaging().shouldEstablishDirectChannel to true.
    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
    // [END ios_10_data_message]
}
