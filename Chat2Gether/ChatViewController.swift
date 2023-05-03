//
//  ChatViewController.swift
//  Chat2Gether
//
//  Created by Sinem  on 31.01.2023.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate
{
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var chatTableView: UITableView!
    
    var messagesArray: [Dictionary<String, String>] = []
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        chatTableView.delegate = self
        chatTableView.dataSource = self
        
        messageTextField.delegate = self
        
        chatTableView.estimatedRowHeight = 80.0
        chatTableView.rowHeight = UITableView.automaticDimension
        
        let notificationName = NSNotification.Name("receivedMPCDataNotification")
        NotificationCenter.default.addObserver(self, selector: Selector(("handleMPCReceivedDataWithNotification")), name: notificationName, object: nil)
        
    }
    
//    MARK: UITableView
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return messagesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = chatTableView.dequeueReusableCell(withIdentifier: "ChatTableViewCell") as! ChatTableViewCell
        let currentMessage = messagesArray[indexPath.row] as Dictionary<String, String>
         
        if let sender = currentMessage["sender"]
        {
            var senderLabelText: String
            var senderColor: UIColor
         
            if sender == "self"
            {
                senderLabelText = "I said:"
                senderColor = UIColor.systemPink
            }
            else
            {
                senderLabelText = sender + " said:"
                senderColor = UIColor.systemPink
            }
            
            cell.detailTextLabel?.text = senderLabelText
            cell.detailTextLabel?.textColor = senderColor
        }
         
        if let message = currentMessage["message"]
        {
            cell.textLabel?.text = message
        }
            return cell
    }
    
//    MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        textField.resignFirstResponder()
     
        let messageDictionary: [String: String] = ["message": textField.text!]
     
        if appDelegate.mpcManager.sendData(dictionaryWithData: messageDictionary, toPeer: appDelegate.mpcManager.session.connectedPeers[0] as MCPeerID)
        {
            let dictionary: [String: String] = ["sender": "self", "message": textField.text!]
            messagesArray.append(dictionary)
     
            self.updateTableview()
        }
        else
        {
            print("Could not send data")
        }
     
        textField.text = ""
     
        return true
    }
    
    func updateTableview()
    {
        self.chatTableView.reloadData()
     
        if self.chatTableView.contentSize.height > self.chatTableView.frame.size.height
        {
            chatTableView.scrollToRow(at: NSIndexPath(row: messagesArray.count - 1, section: 0) as IndexPath, at: UITableView.ScrollPosition.bottom, animated: true)
        }
    }
    
    func handleMPCReceivedDataWithNotification(notification: NSNotification)
    {
        // Get the dictionary containing the data and the source peer from the notification.
        let receivedDataDictionary = notification.object as! Dictionary<String, AnyObject>

        // "Extract" the data and the source peer from the received dictionary.
        let data = receivedDataDictionary["data"] as? NSData
        let fromPeer = receivedDataDictionary["fromPeer"] as! MCPeerID

        var dataDictionary: [String: String] = [:]

        // Convert the data (NSData) into a Dictionary object.
        do {
            dataDictionary = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSDictionary.self, from: data! as Data) as! Dictionary<String, String>
        } catch {
            print("Error: \(error)")
        }

        // Check if there's an entry with the "message" key.
        if let message = dataDictionary["message"]
        {
            // Make sure that the message is other than "_end_chat_".
            if message != "_end_chat_"
            {
                // Create a new dictionary and set the sender and the received message to it.
                let messageDictionary: [String: String] = ["sender": fromPeer.displayName, "message": message]

                // Add this dictionary to the messagesArray array.
                messagesArray.append(messageDictionary)

                // Reload the tableview data and scroll to the bottom using the main thread.
                OperationQueue.main.addOperation( { () -> Void in self.updateTableview() } )
            }
            else
            {
                // In this case an "_end_chat_" message was received.
                // Show an alert view to the user.
                let alert = UIAlertController(title: "", message: "\(fromPeer.displayName) ended this chat.", preferredStyle: UIAlertController.Style.alert)

                let doneAction: UIAlertAction = UIAlertAction(title: "Okay", style: UIAlertAction.Style.default) { (alertAction) -> Void in
                    self.appDelegate.mpcManager.session.disconnect()
                    self.dismiss(animated: true, completion: nil)
                }

                alert.addAction(doneAction)

                OperationQueue.main.addOperation( { () -> Void in self.present(alert, animated: true, completion: nil) } )
            }
        }
    }
}
