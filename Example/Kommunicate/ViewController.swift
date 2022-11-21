//
//  ViewController.swift
//  Kommunicate
//
//  Created by mukeshthawani on 02/19/2018.
//  Copyright (c) 2018 mukeshthawani. All rights reserved.
//

#if os(iOS)
    import Kommunicate
    import UIKit
import ChatProvidersSDK
import ChatSDK

    class ViewController: UIViewController {
        let activityIndicator = UIActivityIndicatorView(style: .gray)

        override func viewDidLoad() {
            super.viewDidLoad()
            activityIndicator.center = CGPoint(x: view.bounds.size.width / 2,
                                               y: view.bounds.size.height / 2)
            view.addSubview(activityIndicator)
            view.bringSubviewToFront(activityIndicator)
            Chat.initialize(accountKey: "CnMABmhtyYgfYQQtuSEyRcgHgKCa8kQ", appId: "com.kommunicate.demo")
            let chatAPIConfiguration = ChatAPIConfiguration()
            chatAPIConfiguration.visitorInfo = VisitorInfo(name: "pakka", email: "pakka@gmail.com", phoneNumber: "6383362545")
            Chat.instance?.configuration = chatAPIConfiguration

            zendeskChat()

        }
        
        func observerForZendeskEvent() {
            let stateToken = Chat.chatProvider?.observeChatState { (state) in
                // Handle logs, agent events, queue position changes and other events
                print("Pakka101 state \(state.logs)")
            }
        
//            let connectionToken = Chat.connectionProvider.observeConnectionState { (connection) in
//                // Handle connection status changes
//                print("Pakka101 connection \(connection)")
//
//            }
//
//            let accountToken = Chat.chatProvider.observeAccount { account in
//                // Handle department and account status changes
//                print("Pakka101 account \(account)")
//
//            }

            let settingsToken = Chat.settingsProvider?.observeChatSettings { settings in
                // Handle changes to Chat settings
                print("Pakka101 chat settings \(settings)")

            }
            
            

            var tokens: [ObservationToken?] = [stateToken,  settingsToken]
            
        }
        
        func zendeskChat() {
//            var token: ChatProvidersSDK.ObservationToken?
//               token = Chat.connectionProvider?.observeConnectionStatus { status in
//                   guard status.isConnected else { return }
//
//                   Chat.profileProvider?.addTags(["tag"])
//                   Chat.profileProvider?.setNote("Visitor Notes")
//                   token?.cancel() // Ensure call only happens once
//               }
               Chat.connectionProvider?.connect()
//            observerForZendeskEvent()

            
            
        }
        
        func sendMessage() {
            
//            var token: ChatProvidersSDK.ObservationToken?
//               token = Chat.connectionProvider?.observeConnectionStatus { status in
//                   guard status.isConnected else { return }
//                   print("Pakka101 connnection status \(status.isConnected)")
//
////                   Chat.profileProvider?.addTags(["tag"])
////                   Chat.profileProvider?.setNote("Visitor Notes")
////                   token?.cancel() // Ensure call only happens once
//               }
//            let stateToken = Chat.chatProvider?.observeChatState { (state) in
//                // Handle logs, agent events, queue position changes and other events
//                print("Pakka101 state \(state)")
//            }

            Chat.chatProvider?.sendMessage("Help me.please") { (result) in
                switch result {
                case .success(let messageId):
                    print("pakka101 message send successfully \(messageId)")
                    // The message was successfully sent
                case .failure(let error):
                    // Something went wrong
                    // You can easily retrieve the messageId to use when retrying
                    let messageId = error.messageId
                    print("pakka101 message send error \(error)")
                }
            }
        }

        @IBAction func launchConversation(_: Any) {
            sendMessage()
//            activityIndicator.startAnimating()
//            view.isUserInteractionEnabled = false
//            //alex-rcrqd
           
//            Kommunicate.showConversations(from: self)
//
//            let kmConversation = KMConversationBuilder()
//                .withBotIds(["alex-rcrqd"])
//
//                // To set the conversation assignee, pass AgentId or BotId.
////
//                .withConversationAssignee("alex-rcrqd")
//
//
//                // To set the custom title
//                .withConversationTitle("Sathyan-t")
//
//                .useLastConversation(true)
//                .build()
////////""bot_customization": ["id":"alex-rcrqd","name":"sathyan-t"],
//            let messageInfo = ["user-name":"sathya"] as [String : Any]
//                 do {
//                   try Kommunicate.defaultConfiguration.updateChatContext(with: messageInfo)
//                } catch {
//                  print("Failed to update chat context: ", error)
//                }
//
//            Kommunicate.createConversation(conversation: kmConversation) { result in
//                switch result {
//                case .success(let conversationId):
//                    print("Conversation id: ",conversationId)
//                    Kommunicate.showConversationWith(
//                        groupId: conversationId,
//                        from: self,
//                        showListOnBack: false, // If true, then the conversation list will be shown on tap of the back button.
//                        completionHandler: { success in
//                        print("conversation was shown")
//                    })
//                // Launch conversation
//                case .failure(let kmConversationError):
//                    print("Failed to create a conversation: ", kmConversationError)
//                }
//            }
//
//
            
//
//            Kommunicate.createAndShowConversation(from: self, completion: {
//                error in
//                self.activityIndicator.stopAnimating()
//                self.view.isUserInteractionEnabled = true
//                if error != nil {
//                    print("Error while launching")
//                }
//            })
            
            
//            Kommunicate.showConversationWith(
//                   groupId: "79143433",
//                   from: self,
//                   showListOnBack: false, // If true, then the conversation list will be shown on tap of the back button.
//                   completionHandler: { success in
//                   print("conversation was shown")
//               })
//            Kommunicate.showConversations(from: self)
        }

        @IBAction func logoutAction(_: Any) {
            Kommunicate.logoutUser { result in
                switch result {
                case .success:
                    print("Logout success")
                    self.dismiss(animated: true, completion: nil)
                case .failure:
                    print("Logout failure, now registering remote notifications(if not registered)")
                    if !UIApplication.shared.isRegisteredForRemoteNotifications {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { granted, _ in
                            if granted {
                                DispatchQueue.main.async {
                                    UIApplication.shared.registerForRemoteNotifications()
                                }
                            }
                            DispatchQueue.main.async {
                                self.dismiss(animated: true, completion: nil)
                            }
                        }
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
    }
#endif
