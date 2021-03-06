//
//  CallManager.swift
//  SDKDemo1
//
//  Created by Vishal on 14/11/18.
//

import Foundation


struct CallData {
    var peerData: User
    var callType: CallType
    var muid: String
    var signallingClient: HippoChannel
}

#if canImport(HippoCallClient)
import HippoCallClient
#endif


class CallManager {
    
    static let shared = CallManager()
    
    func startCall(call: CallData, completion: @escaping (Bool) -> Void) {
        #if canImport(HippoCallClient)
        let peerUser = call.peerData
        guard let peer = HippoUser(name: peerUser.fullName, userID: peerUser.userID, imageURL: peerUser.image) else {
            return
        }
        guard let currentUser = getCurrentUser() else {
            return
        }
        let callToMake = Call(peer: peer, signalingClient: call.signallingClient, uID: call.muid, currentUser: currentUser, type: getCallTypeWith(localType: call.callType))
        HippoCallClient.shared.startCall(call: callToMake, completion: completion)
        #else
        completion(false)
        #endif
    }
    
    func startConnection(peerUser: User, muid: String, callType: CallType, completion: (Bool) -> Void) {
        #if canImport(HippoCallClient)
        guard let peer = HippoUser(name: peerUser.fullName, userID: peerUser.userID, imageURL: peerUser.image) else {
            return
        }
        let type = getCallTypeWith(localType: callType)
        let request = PresentCallRequest.init(peer: peer, callType: type, callUUID: muid)
        HippoCallClient.shared.startConnecting(call: request, uuid: muid)
        #endif
    }
    
    func hungupCall() {
        #if canImport(HippoCallClient)
        HippoCallClient.shared.hangupCall()
        #endif
    }
    
    #if canImport(HippoCallClient)
    func getCallTypeWith(localType: CallType) -> Call.CallType {
        var type = Call.CallType.audio
        
        switch localType {
        case .audio:
            type = .audio
        case .video:
            type = .video
        }
        return type
    }
    #endif
    
    func isCallClientAvailable() -> Bool {
        #if canImport(HippoCallClient)
        return true
        #else
        return false
        #endif
    }
    
    func initCallClientIfPresent() {
        #if canImport(HippoCallClient)
        setCredentials()
        setCallClientDelegate()
        #endif
    }
    
    private func setCredentials() {
        #if canImport(HippoCallClient)
        HippoCallClient.shared.setCredentials(rawCredentials: testCredentials())
        #endif
    }
    func findActiveCallUUID() -> String? {
        #if canImport(HippoCallClient)
        return HippoCallClient.shared.activeCallUUID
        #else
        return nil
        #endif
    }
    private func setCallClientDelegate() {
        #if canImport(HippoCallClient)
        HippoCallClient.shared.registerHippoCallClient(delegate: self)
        #endif
    }
    func voipNotificationRecieved(payloadDict: [String: Any]) {
        #if canImport(HippoCallClient)
        guard let peer = HippoUser(json: payloadDict), let channelID = Int.parse(values: payloadDict, key: "channel_id") else {
            return
        }
        let channel = FuguChannelPersistancyManager.shared.getChannelBy(id: channelID)
        
        if HippoConfig.shared.userDetail == nil {
            HippoConfig.shared.userDetail = HippoUserDetail()
        } else if HippoConfig.shared.agentDetail == nil {
            HippoConfig.shared.setAgentStoredData()
        }
        
        guard let currentUser = getCurrentUser() else {
            return
        }
        HippoCallClient.shared.voipNotificationRecieved(dictionary: payloadDict, peer: peer, signalingClient: channel, currentUser: currentUser)
        #else
        print("cannot import HippoCallClient")
        #endif
    }
    
    private func testCredentials() -> [String :Any] {
        let ice_servers: [String: Any] = [
            "stun": ["stun:turnserver.fuguchat.com:19305"],
            "turn":  [
                "turn:turnserver.fuguchat.com:19305?transport=UDP",
                "turn:turnserver.fuguchat.com:19305?transport=TCP",
                "turns:turnserver.fuguchat.com:5349?transport=UDP",
                "turns:turnserver.fuguchat.com:5349?transport=TCP"
            ]]
        let json: [String: Any] =  ["credential": "3FXCGBCnDfqsrOqs",
                                    "username": "fuguadmin",
                                    "ice_servers": ice_servers,
                                    "turn_api_key": "VPlwuCJcizZye2znMflmJ75x0IraJ5cQ"]
        return json
    }
    
    #if canImport(HippoCallClient)
    func getCurrentUser() -> HippoUser? {
        switch HippoConfig.shared.appUserType {
        case .customer:
            guard let user = HippoConfig.shared.userDetail else {
                return nil
            }
            let name = user.fullName ?? ""
            let userID = HippoUserDetail.fuguUserID ?? -1
            
            return HippoUser(name: name, userID: userID, imageURL: nil)
        case .agent:
            guard let agentDetail = HippoConfig.shared.agentDetail else {
                return nil
            }
            return HippoUser(name: agentDetail.fullName, userID: agentDetail.id, imageURL: nil)
        }
    }
    #endif
}

#if canImport(HippoCallClient)
extension CallManager: HippoCallClientDelegate {
    func loadCallPresenterView(request: CallPresenterRequest) -> CallPresenter? {
        return HippoConfig.shared.notifyCallRequest(request)
    }
}
#endif
