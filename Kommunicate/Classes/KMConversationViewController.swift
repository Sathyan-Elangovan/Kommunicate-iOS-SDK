//
//  KMConversationViewController.swift
//  Kommunicate
//
//  Created by Shivam Pokhriyal on 14/11/18.
//

import UIKit
import Applozic
import ApplozicSwift

/// Before pushing this view Controller. Use this
/// navigationItem.backBarButtonItem = UIBarButtonItem(customView: UIView())
open class KMConversationViewController: ALKConversationViewController {

    private let faqIdentifier =  11223346
    private let kmConversationViewConfiguration: KMConversationViewConfiguration
    private weak var ratingVC: RatingViewController?
    private let registerUserClientService = ALRegisterUserClientService()
    private let kmBotService  = KMBotService()

    lazy var customNavigationView = ConversationVCNavBar(
        delegate: self,
        localizationFileName: self.configuration.localizedStringFileName,
        configuration: kmConversationViewConfiguration)

    let awayMessageView = AwayMessageView(frame: CGRect.zero)
    let botCharLimitView = BotCharacterLimitView(frame: .zero)
    let conversationClosedView: ConversationClosedView = {
        let closedView = ConversationClosedView(frame: .zero)
        closedView.isHidden = true
        return closedView
    }()

    var topConstraintClosedView: NSLayoutConstraint?
    var conversationService = KMConversationService()
    var conversationDetail = ConversationDetail()

    private var converastionNavBarItemToken: NotificationToken? = nil
    private var channelMetadataUpdateToken: NotificationToken? = nil

    private let awayMessageheight = 80.0

    private let charLimitForBotViewHeight = 80.0

    private var isBotAssignedToDialogflow = false

    private var isClosedConversation: Bool {
        guard let channelId = viewModel.channelKey,
            !ALChannelService.isChannelDeleted(channelId),
            conversationDetail.isClosedConversation(channelId: channelId.intValue) else {
                return false
        }
        return true
    }

    private var isAwayMessageViewHidden = true {
        didSet {
            guard oldValue != isAwayMessageViewHidden else { return }
            showAwayMessage(!isAwayMessageViewHidden)
        }
    }

    private var isClosedConversationViewHidden = true {
        didSet {
            guard oldValue != isClosedConversationViewHidden else { return }
            showClosedConversationView(!isClosedConversationViewHidden)
        }
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigation()
    }

    required public init(configuration: ALKConfiguration,
                         conversationViewConfiguration: KMConversationViewConfiguration,
                         individualLaunch : Bool = true) {
        self.kmConversationViewConfiguration = conversationViewConfiguration
        super.init(configuration: configuration)
        self.chatBar.addTextView(delegate: self)
        self.individualLaunch = individualLaunch
        addNotificationCenterObserver()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init(configuration: ALKConfiguration) {
        fatalError("init(configuration:) has not been implemented")
    }

    open override func viewDidLoad() {
        super.viewDidLoad()

        customNavigationView.setupAppearance()
        
        if #available(iOS 13.0, *) {
            // Always adopt a light interface style.
            overrideUserInterfaceStyle = .light
        }

        checkPlanAndShowSuspensionScreen()
        addViewConstraints()
        guard let channelId = viewModel.channelKey else { return }
        sendConversationOpenNotification(channelId: String(describing: channelId))
        setupConversationClosedView()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        awayMessageView.drawDottedLines()
        botCharLimitView.drawDottedLines()
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideAwayAndClosedView()
        self.isBotAssignedToDialogflow = false
        botCharLimitViewHeight(hide: true)
        self.chatBar.disableSendButton(isSendButtonDisabled: false)
    }

    override open func newMessagesAdded() {
        super.newMessagesAdded()

        // Hide away message view whenever a new message comes.
        // Make sure the message is not from same user.
        guard !viewModel.messageModels.isEmpty else { return }
        if let lastMessage = viewModel.messageModels.last, !lastMessage.isMyMessage {
            isAwayMessageViewHidden = true
        }
    }

    func addNotificationCenterObserver() {

        converastionNavBarItemToken = NotificationCenter.default.observe(
            name: Notification.Name(rawValue:ALKNavigationItem.NSNotificationForConversationViewNavigationTap),
            object: nil,
            queue: nil,
            using: { [weak self] notification in
                guard let notificationInfo = notification.userInfo,
                    let strongSelf = self else {
                        return
                }
                let identifier = notificationInfo["identifier"] as? Int
                if identifier == strongSelf.faqIdentifier{
                    Kommunicate.openFaq(from: strongSelf, with: strongSelf.configuration)
                }
        })

        channelMetadataUpdateToken = NotificationCenter.default.observe(
            name: NSNotification.Name(rawValue: "UPDATE_CHANNEL_METADATA"),
            object: nil,
            queue: nil,
            using: { [weak self] notification in
                self?.onChannelMetadataUpdate()
        })

        if individualLaunch {
            NotificationCenter.default.addObserver(self, selector: #selector(pushNotification(notification:)), name: Notification.Name.pushNotification, object: nil)
        }
    }

    @objc func pushNotification(notification: NSNotification) {
        print("Push notification received in KMConversationViewController: ", notification.object ?? "")
        let pushNotificationHelper = KMPushNotificationHelper(configuration, kmConversationViewConfiguration)
        let (notifData, _) = pushNotificationHelper.notificationInfo(notification as Notification)
        guard
            self.isViewLoaded,
            self.view.window != nil,
            let notificationData = notifData,
            !pushNotificationHelper.isNotificationForActiveThread(notificationData)
            else { return }

        unsubscribingChannel()
        viewModel.contactId = nil
        viewModel.channelKey = notificationData.groupId
        viewModel.conversationProxy = nil
        viewWillLoadFromTappingOnNotification()
        refreshViewController()
    }

    func addViewConstraints() {        chatBar.headerView.addViewsForAutolayout(views: [awayMessageView, botCharLimitView])

        botCharLimitView.layout {
            $0.leading == chatBar.headerView.leadingAnchor
            $0.trailing == chatBar.headerView.trailingAnchor
            $0.bottom == chatBar.headerView.bottomAnchor
        }

        botCharLimitView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: BotCharacterLimitView.ConstraintIdentifier.botCharacterLimitViewHeight.rawValue).isActive = true

        awayMessageView.layout {
            $0.leading == chatBar.headerView.leadingAnchor
            $0.trailing == chatBar.headerView.trailingAnchor
            $0.bottom == botCharLimitView.topAnchor
        }
        awayMessageView.heightAnchor.constraintEqualToAnchor(constant: 0, identifier: AwayMessageView.ConstraintIdentifier.awayMessageViewViewHeight.rawValue).isActive = true
    }

    func fetchBotType()  {
        guard let channelKey = viewModel.channelKey else { return }
        kmBotService.fetchBotTypeIfAssignedToBot(groupId: channelKey) { [weak self] (isDialogflowBot)  in
            self?.isBotAssignedToDialogflow = isDialogflowBot
            guard let weakSelf = self,
                channelKey == weakSelf.viewModel.channelKey,
                !weakSelf.isClosedConversation else {
                    return
            }
            DispatchQueue.main.async {
                if weakSelf.isBotAssignedToDialogflow {
                    weakSelf.checkCharLimitAndShowLimitView(characterCount: weakSelf.chatBar.textView.text.count)
                } else {
                    weakSelf.botCharLimitViewHeight(hide: true)
                    weakSelf.chatBar.disableSendButton(isSendButtonDisabled: false)
                }
            }
        }
    }

    func messageStatusAndFetchBotType() {
        self.botCharLimitViewHeight(hide: true)
        guard let channelKey = viewModel.channelKey, !isClosedConversation else { return }
        conversationService.awayMessageFor(groupId: channelKey, completion: {
            result in
            DispatchQueue.main.async {
                switch result {
                case .success(let message):
                    guard !message.isEmpty else { return }
                    self.isAwayMessageViewHidden = false
                    self.awayMessageView.set(message: message)
                    /// Fetch the bot type
                    self.fetchBotType()
                case .failure(let error):
                    print("Message status error: \(error)")
                    self.isAwayMessageViewHidden = true
                    /// Fetch the bot type
                    self.fetchBotType()
                    return
                }
            }
        })
    }

    func sendConversationOpenNotification(channelId: String) {
        let info: [String: Any] = ["ConversationId": channelId]
        let launchNotificationName = kmConversationViewConfiguration.conversationLaunchNotificationName
        let notification = Notification(
            name: Notification.Name(rawValue: launchNotificationName),
            object: nil,
            userInfo: info)
        NotificationCenter.default.post(notification)
    }

    func sendConversationCloseNotification(channelId: String) {
        let info: [String: Any] = ["ConversationId": channelId]
        let backbuttonNotificationName = kmConversationViewConfiguration.backButtonNotificationName
        let notification = Notification(
            name: Notification.Name(rawValue: backbuttonNotificationName),
            object: nil,
            userInfo: info)
        NotificationCenter.default.post(notification)
    }

    func updateAssigneeDetails() {
        conversationDetail.updatedAssigneeDetails(groupId: viewModel.channelKey, userId: viewModel.contactId) { (contact,channel) in
            guard let alChannel = channel else {
                print("Channel is nil in updatedAssigneeDetails")
                return
            }
            self.customNavigationView.updateView(assignee: contact,channel: alChannel)
        }
    }

    @objc func onChannelMetadataUpdate() {
        guard viewModel != nil, viewModel.isGroup else { return }
        updateAssigneeDetails()
        // If the user was typing when the status changed
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.fetchBotType()
        }
        view.endEditing(true)
        guard isClosedConversationViewHidden == isClosedConversation else { return }
        checkFeedbackAndShowRatingView()
    }

    private func setupNavigation() {
        // Remove current title from center of navigation bar
        navigationItem.titleView = UIView()
        navigationItem.leftBarButtonItems = nil
        // Create custom navigation view.
        let (contact,channel) =  conversationDetail.conversationAssignee(groupId: viewModel.channelKey, userId: viewModel.contactId)
        guard let alChannel = channel else {
            print("Channel is nil in conversationAssignee")
            return
        }
        customNavigationView.updateView(assignee:contact ,channel: alChannel)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: customNavigationView)
    }

    public override func refreshViewController() {
        clearAndReloadTable()
        configureChatBar()
        hideAwayAndClosedView()
        updateAssigneeDetails()
        // Fetch Assignee details every time view is launched.
        messageStatusAndFetchBotType()
        // Check for group left
        isChannelLeft()
        checkUserBlock()
        subscribeChannelToMqtt()
        viewModel.prepareController()
    }

    public override func loadingFinished(error _: Error?) {
        super.loadingFinished(error: nil)
        checkFeedbackAndShowRatingView()
    }

    private func setupConversationClosedView() {
        conversationClosedView.restartTapped = {[weak self] in

            guard let weakSelf = self else {
                return;
            }
            weakSelf.isClosedConversationViewHidden = true
            if (weakSelf.isBotAssignedToDialogflow) {
                weakSelf.checkCharLimitAndShowLimitView(characterCount: weakSelf.chatBar.textView.text.count)
            } else {
                if weakSelf.isAwayMessageViewHidden {
                    weakSelf.botCharLimitView.isHidden = true
                    weakSelf.chatBar.headerViewHeight = 0
                }
            }
        }
        view.addViewsForAutolayout(views: [conversationClosedView])
        var bottomAnchor = view.bottomAnchor
        if #available(iOS 11, *) {
            bottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        }
        topConstraintClosedView = conversationClosedView.topAnchor
            .constraint(lessThanOrEqualTo: chatBar.topAnchor)
        NSLayoutConstraint.activate([
            conversationClosedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            conversationClosedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            conversationClosedView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    private func checkPlanAndShowSuspensionScreen() {
        let accountVC = ALKAccountSuspensionController()
        guard PricingPlan.shared.showSuspensionScreen() else { return }
        self.present(accountVC, animated: false, completion: nil)
        accountVC.closePressed = {[weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        self.registerUserClientService.syncAccountStatus { response, error in
            guard error == nil, let response = response, response.isRegisteredSuccessfully() else {
                print("Failed to sync the account package status")
                return
            }
            print("Successfuly synced the account package status")
        }
    }

    private func showAwayMessage(_ flag: Bool) {

        if self.botCharLimitView.isHidden {
            botCharLimitView.constraint(withIdentifier: BotCharacterLimitView.ConstraintIdentifier.botCharacterLimitViewHeight.rawValue)?.constant = 0
            botCharLimitView.hideView(hide: true)
        }

        awayMessageView.constraint(withIdentifier: AwayMessageView.ConstraintIdentifier.awayMessageViewViewHeight.rawValue)?.constant = CGFloat(flag ? awayMessageheight : 0)

        chatBar.headerViewHeight = flag ? awayMessageheight: !self.botCharLimitView.isHidden ? charLimitForBotViewHeight : 0
        awayMessageView.showMessage(flag)
    }

    private func hideAwayAndClosedView() {
        isAwayMessageViewHidden = true
        isClosedConversationViewHidden = true
    }
}

extension KMConversationViewController: NavigationBarCallbacks {
    func backButtonPressed() {
        view.endEditing(true)
        let popVC = self.navigationController?.popViewController(animated: true)
        if popVC == nil {
            self.dismiss(animated: true, completion: nil)
        }
        guard let channelId = viewModel.channelKey else { return }
        sendConversationCloseNotification(channelId: String(describing: channelId))
    }
}

extension KMConversationViewController {

    func checkFeedbackAndShowRatingView() {
        guard isClosedConversation else {
            isClosedConversationViewHidden = true
            hideRatingView()
            return
        }
        conversationClosedView.clearFeedback()
        isClosedConversationViewHidden = false
        guard let channelId = viewModel.channelKey,
            !kmConversationViewConfiguration.isCSATOptionDisabled else {
                return
        }
        conversationDetail.feedbackFor(channelId: channelId.intValue) { [weak self] feedback in
            DispatchQueue.main.async {
                guard let previousFeedback = feedback else {
                    self?.showRatingView()
                    return
                }
                self?.show(feedback: previousFeedback)
            }
        }
    }

    private func showRatingView() {
        guard self.ratingVC == nil else { return }
        let ratingVC = RatingViewController()
        ratingVC.closeButtontapped = { [weak self] in
            self?.hideRatingView()
        }
        ratingVC.feedbackSubmitted = { [weak self] feedback in
            print("feedback submitted with rating: \(feedback.rating)")
            self?.hideRatingView()
            self?.submitFeedback(feedback: feedback)
        }
        self.present(ratingVC, animated: true, completion: {[weak self] in
            self?.ratingVC = ratingVC
        })
    }

    private func hideRatingView() {
        guard let ratingVC = ratingVC,
            UIViewController.topViewController() is RatingViewController,
            !ratingVC.isBeingDismissed else {
                return
        }
        self.dismiss(animated: true, completion: { [weak self] in
            self?.ratingVC = nil
        })
    }

    private func submitFeedback(feedback: Feedback) {
        guard let channelId = viewModel.channelKey else { return }
        conversationService.submitFeedback(
            groupId: channelId.intValue,
            feedback: feedback
        ) { [weak self] result in
            switch result {
            case .success(let conversationFeedback):
                print("feedback submit response success: \(conversationFeedback)")
                guard let conversationFeedback = conversationFeedback.feedback else { return }
                DispatchQueue.main.async {
                    self?.show(feedback: conversationFeedback)
                }
            case .failure(let error):
                print("feedback submit response failure: \(error)")
            }
        }
    }

    private func updateMessageListBottomPadding(isClosedViewHidden: Bool) {
        var heightDiff: Double = 0
        if !isClosedViewHidden {
            var bottomInset: CGFloat = 0
            if #available(iOS 11.0, *) {
                bottomInset = view.safeAreaInsets.bottom
            }
            heightDiff = Double(conversationClosedView.frame.height
                - (chatBar.frame.height - bottomInset))
            if heightDiff < 0 {
                if (chatBar.headerViewHeight + heightDiff) >= 0 {
                    heightDiff = chatBar.headerViewHeight + heightDiff
                } else {
                    heightDiff = 0
                }
            }
        }
        chatBar.headerViewHeight = heightDiff
        guard heightDiff > 0 else { return }
        showLastMessage()
    }

    private func showClosedConversationView(_ flag: Bool) {
        conversationClosedView.isHidden = !flag
        updateMessageListBottomPadding(isClosedViewHidden: !flag)
        topConstraintClosedView?.isActive = flag
    }

    private func show(feedback: Feedback) {
        conversationClosedView.setFeedback(feedback)
        conversationClosedView.layoutIfNeeded()
        updateMessageListBottomPadding(isClosedViewHidden: false)
    }
}

extension KMConversationViewController {

    /// This method will check character limit and show the bot character limit UI.
    /// - Parameter characterCount:Count of the character  from the text view
    func checkCharLimitAndShowLimitView(characterCount: Int) {
        if characterCount == 0 {
            self.botCharLimitView.isHidden = true
            chatBar.disableSendButton(isSendButtonDisabled: false)
            botCharLimitViewHeight(hide: true)
            return
        }
        let warningCount = BotCharacterLimitView.CharacterLimit.charLimitForDialogFlowBot - BotCharacterLimitView.CharacterLimit.charLimitWarningForDialogFlowBot
        let isWarning = characterCount >= warningCount
        let diffCount = characterCount - BotCharacterLimitView.CharacterLimit.charLimitForDialogFlowBot

        let isTextExceed = diffCount > 0
        if  isWarning || isTextExceed {
            self.botCharLimitView.isHidden = false
            let botCharLimitText = BotCharacterLimitView.LocalizedText.botCharLimit
            var charInfoText = ""

            if (isTextExceed) {
                let removeCharMessage = BotCharacterLimitView.LocalizedText.removeCharMessage
                charInfoText =  String(format: removeCharMessage, diffCount)
            } else {
                let remainingCharMessage = BotCharacterLimitView.LocalizedText.remainingCharMessage
                charInfoText =  String(format: remainingCharMessage, -diffCount)
            }
            chatBar.disableSendButton(isSendButtonDisabled: isTextExceed)
            let botLimitmessage = String(format: botCharLimitText, BotCharacterLimitView.CharacterLimit.charLimitForDialogFlowBot, charInfoText)
            botCharLimitView.set(message: botLimitmessage)
            botCharLimitViewHeight(hide: false)
        } else {
            self.botCharLimitView.isHidden = true
            botCharLimitViewHeight(hide: true)
            chatBar.disableSendButton(isSendButtonDisabled: false)
        }
    }

    /// This method is used for hide and show the bot char limit view and based on the away message is hidden or not increase or decrease the height of the header View.
    /// - Parameter hide: Pass true for hide the view of bot character limit
    func botCharLimitViewHeight(hide: Bool) {
        botCharLimitView.constraint(withIdentifier: BotCharacterLimitView.ConstraintIdentifier.botCharacterLimitViewHeight.rawValue)?.constant = CGFloat(hide ?  0 : charLimitForBotViewHeight)
        botCharLimitView.hideView(hide: hide)
        botCharLimitView.showDottedLine(!hide)
        if (hide) {
            chatBar.headerViewHeight  = isAwayMessageViewHidden ? 0 :  awayMessageheight
        } else {
            chatBar.headerViewHeight = isAwayMessageViewHidden ?  charLimitForBotViewHeight : awayMessageheight + charLimitForBotViewHeight
        }
    }

}
extension KMConversationViewController : UITextViewDelegate {

    public func textViewDidChange(_ textView: UITextView) {
        guard self.isBotAssignedToDialogflow else {
            return
        }
        checkCharLimitAndShowLimitView(characterCount: textView.text.count)
    }

    public func textViewDidEndEditing(_ textView: UITextView) {

    }

    public func textViewDidBeginEditing(_ textView: UITextView) {

    }
}
