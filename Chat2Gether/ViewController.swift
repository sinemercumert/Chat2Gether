//
//  ViewController.swift
//  Chat2Gether
//
//  Created by Sinem  on 31.01.2023.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, MPCManagerDelegate

{
    
    @IBOutlet weak var personTableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var isAdvertising: Bool!

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        personTableView.dataSource = self
        personTableView.delegate = self
        
        appDelegate.mpcManager.delegate = self
        
        appDelegate.mpcManager.browser.startBrowsingForPeers()
        
        appDelegate.mpcManager.advertiser.startAdvertisingPeer()
         
        isAdvertising = true
    }

    @IBAction func actionToolbar(_ sender: Any)
    {
        let actionSheet = UIAlertController(title: "", message: "Change Visibility", preferredStyle: UIAlertController.Style.actionSheet)
        var actionTitle: String
        
        if isAdvertising == true
        {
            actionTitle = "Make me invisible to others"
        }
        else
        {
            actionTitle = "Make me visible to others"
        }
         
        let visibilityAction: UIAlertAction = UIAlertAction(title: actionTitle, style: UIAlertAction.Style.default) { (alertAction) -> Void in
            if self.isAdvertising == true
            {
                self.appDelegate.mpcManager.advertiser.stopAdvertisingPeer()
            }
            else
            {
                self.appDelegate.mpcManager.advertiser.startAdvertisingPeer()
            }
            
            self.isAdvertising = !self.isAdvertising
        }
         
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (alertAction) -> Void in }
         
        actionSheet.addAction(visibilityAction)
        actionSheet.addAction(cancelAction)
         
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return appDelegate.mpcManager.foundPeers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = personTableView.dequeueReusableCell(withIdentifier: "DeviceTableViewCell") as! DeviceTableViewCell // ???????????????????????????????????????????????????
        cell.deviceNameLabel.text = appDelegate.mpcManager.foundPeers[indexPath.row].displayName
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        performSegue(withIdentifier: "toChatViewController", sender: nil)           // ???????????????????????????????????????????????????
        
        let selectedPeer = appDelegate.mpcManager.foundPeers[indexPath.row] as MCPeerID  
        appDelegate.mpcManager.browser.invitePeer(selectedPeer, to: appDelegate.mpcManager.session, withContext: nil, timeout: 20)
    }
    
//    MARK: MPCManagerDelegate
    
    func invitationWasReceived(fromPeer: String) {
        let alert = UIAlertController(title: "", message: "\(fromPeer) wants to chat with you.", preferredStyle: UIAlertController.Style.alert)
         
        let acceptAction: UIAlertAction = UIAlertAction(title: "Accept", style: UIAlertAction.Style.default) { (alertAction) -> Void in
            self.appDelegate.mpcManager.invitationHandler(true, self.appDelegate.mpcManager.session)
        }
         
        let declineAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) { (alertAction) -> Void in
            self.appDelegate.mpcManager.invitationHandler(false, nil)
        }
         
        alert.addAction(acceptAction)
        alert.addAction(declineAction)
         
        OperationQueue.main.addOperation { () -> Void in
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func connectedWithPeer(peerID: MCPeerID)
    {
        OperationQueue.main.addOperation { () -> Void in
            self.performSegue(withIdentifier: "idSegueChat", sender: self)
        }
    }
    
    func foundPeer()
    {
        personTableView.reloadData()
    }
    
    func lostPeer()
    {
        personTableView.reloadData()
    }
}


