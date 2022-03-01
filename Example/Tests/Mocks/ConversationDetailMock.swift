//
//  ConversationDetailMock.swift
//  Kommunicate_Tests
//
//  Created by Shivam Pokhriyal on 05/03/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation
import KommunicateCoreiOSSDK
@testable import Kommunicate

class ConversationDetailMock: ConversationDetail {
    var groupId: NSNumber!

    override func updatedAssigneeDetails(groupId: NSNumber?, userId _: String?, completion: @escaping (ALContact?, ALChannel?) -> Void) {
        self.groupId = groupId
        completion(nil, nil)
    }
}
