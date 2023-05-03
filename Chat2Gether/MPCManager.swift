//
//  MPCManager.swift
//  Chat2Gether
//
//  Created by Sinem  on 1.02.2023.
//

import UIKit
import MultipeerConnectivity

protocol MPCManagerDelegate
{
    func foundPeer()
    func lostPeer()
    func invitationWasReceived(fromPeer: String)
    func connectedWithPeer(peerID: MCPeerID)
}

class MPCManager: NSObject, MCSessionDelegate, MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate
{
    var delegate: MPCManagerDelegate?
    var session: MCSession!
    var peer: MCPeerID! //yakındakid diğer cihazlar tarafından görülen cihaz
    var browser: MCNearbyServiceBrowser!
    var advertiser: MCNearbyServiceAdvertiser!
    var foundPeers = [MCPeerID]()  // bulunan cihazları depolayacak
    var invitationHandler: ((Bool, MCSession?)->Void)!  // gelen davetleri tutuyor
    
    override init()
    {
        super.init()
     
        peer = MCPeerID(displayName: UIDevice.current.name) //cihaz adı
        
        session = MCSession(peer: peer)
        session.delegate = self
        
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: "appcoda-mpc") // 2. parametre uygulamayı diğerleri arasında uniq tanımlar
        browser.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: "appcoda-mpc")
        advertiser.delegate = self
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) //cihaz bulunduğunda
    {
        foundPeers.append(peerID)
        delegate?.foundPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID)
    {
        for (index, aPeer) in foundPeers.enumerated()
        {
            if aPeer == peerID
            {
                foundPeers.remove(at: index)
                break
            }
        }
        delegate?.lostPeer()
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error)
    {
        print(error.localizedDescription)
    }
    
//    MARK: MCNearbyServiceBrowserDelegate
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void)
    {
        self.invitationHandler = invitationHandler
        delegate?.invitationWasReceived(fromPeer: peerID.displayName)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error)
    {
        print(error.localizedDescription)
    }
    
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState)
    {
        switch state {
            
        case MCSessionState.connected:
            print("Connected to session: \(session)")
            delegate?.connectedWithPeer(peerID: peerID)
     
        case MCSessionState.connecting:
            print("Connecting to session: \(session)")
     
        default:
            print("Did not connect to session: \(session)")
        }
    }
    
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: Progress!) { }
     
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) { }
     
    func session(session: MCSession!, didReceiveStream stream: InputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) { }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) { }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) { }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) { }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) { }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) { }
    
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!)
    {
        let dictionary: [String: AnyObject] = ["data": data, "fromPeer": peerID]
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "receivedMPCDataNotification") , object: dictionary)
    }
    
    func sendData(dictionaryWithData dictionary: Dictionary<String, String>, toPeer targetPeer: MCPeerID) -> Bool
    {
        do {
            let dataToSend = try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: false)
            let peersArray = [targetPeer]
            
            try session.send(dataToSend, toPeers: peersArray, with: .reliable)
            return true
        } catch {
            print("Error: \(error)")
            return false
        }
    }
}
