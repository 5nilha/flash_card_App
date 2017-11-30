//
//  ViewController.swift
//  Flash Chat
//
//  Created by Angela Yu on 29/08/2015.
//  Copyright (c) 2015 London App Brewery. All rights reserved.
//

import UIKit
import Firebase
import ChameleonFramework


class ChatViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    // Declare instance variables here
    var messageArray : [Message] = [Message]() //message object to hold the sender's email and message
    
    // We've pre-linked the IBOutlets
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var sendButton: UIButton!
    @IBOutlet var messageTextfield: UITextField!
    @IBOutlet var messageTableView: UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set the delegate and dataSource
        messageTableView.delegate = self
        messageTableView.dataSource = self
        messageTextfield.delegate = self
    
        
        //Set the tapGesture
        //The tapGesture will trigger when the screen is click anywhere and Call the methos tableViteTapped
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tableViewTapped))
        messageTableView.addGestureRecognizer(tapGesture)

        
        //Register the MessageCell.xib file
        messageTableView.register(UINib(nibName: "MessageCell", bundle: nil), forCellReuseIdentifier: "customMessageCell")
        
        
        configureTableView()
        retrieveMessages() // Retrieves the app as soon as the app load
        
        messageTableView.separatorStyle = .none
    }
    
    

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //MARK: - TableView DataSource Methods
    
    
    //Declare cellForRowAtIndexPath
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "customMessageCell", for: indexPath) as! CustomMessageCell
        
        //passes the message from the messageArray to the label on the tableviewCell
        cell.messageBody.text = messageArray[indexPath.row].messageText // since the messageArray contains object, this line gets the element in the array and calll the element and the element's messageText property
        
        cell.senderUsername.text = messageArray[indexPath.row].sender
        cell.avatarImageView.image = UIImage(named: "egg")
        
        if cell.senderUsername.text == Auth.auth().currentUser?.email as! String! {
            //messages from current user
            cell.avatarImageView.backgroundColor = UIColor.flatMint()
            cell.messageBackground.backgroundColor = UIColor.flatSkyBlue()
        } else {
            cell.messageBackground.backgroundColor = UIColor.flatWatermelon()
        }
        
        return cell
    }
    
    
    //Declare numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageArray.count
    }
    
    
    //Declare tableViewTapped
    @objc func tableViewTapped() {
        messageTextfield.endEditing(true) // Will
    }
    
    
    //Declare configureTableView
    func configureTableView() {
        messageTableView.rowHeight = UITableViewAutomaticDimension // the table cell will be able to display all the content inside the cell independent of its size
        messageTableView.estimatedRowHeight = 120.0 // Sets the minimum height to display the cell
    }
    
    
    
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //MARK:- TextField Delegate Methods
    
    //Declare textFieldDidBeginEditing
    //Whenever the message textfield is clicked this function is authomatically loaded
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //The function allows the textfield delegate to know that a text field was tapped
        let keyboardHeight = 258 // is the height of the keyboard on the screen
        let messageField = 50 // is the height of the message textfield
       
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint.constant = CGFloat(keyboardHeight + messageField)
            self.view.layoutIfNeeded() // if something in the view changes, it redraw the whole thing
        }
    }
    
    
    //Declare textFieldDidEndEditing
    /*This function is not loaded automatically. A Tapgesture monitores when the user clicks out of the message textview, and only then it calls the function tableViewTapped and sets  messageTextfield.endEditing(true), to this function be called */
    func textFieldDidEndEditing(_ textField: UITextField) {
        UIView.animate(withDuration: 0.3) {
            self.heightConstraint.constant = 50
            self.view.layoutIfNeeded()
        }
    }

    
    
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    
    
    //MARK: - Send & Recieve from Firebase
    
    
    @IBAction func sendPressed(_ sender: AnyObject) {
        
        messageTextfield.endEditing(true)
        //TODO: Send the message to Firebase and save it in our database
        //disable the msssage textField whe nthe user clicks send to avoid him to send the same message again and again until the message is sved on database
        messageTextfield.isEnabled = false
        sendButton.isEnabled = false
        
        let messagesDB = Database.database().reference().child("Messages")
        
        let messageDictionary = ["Sender": Auth.auth().currentUser?.email,
                                 "MessageBody" : messageTextfield.text!]
        
        //Creates a custom random key to the messages, so it can be saved using a unique identifier
        // This lines saves the messageDictionary inside the message dabase under the automatic generated unique identifier
        messagesDB.childByAutoId().setValue(messageDictionary){
            (error, reference) in
            
            if error != nil {
                print("DEVELOPER: Error = \(String(describing: error))")
            }
            else {
                print("DEVELOPER: Message saved successfully")
                
                //Now that the message is saved in the database, the save button and the message textField are enabled
                self.messageTextfield.isEnabled = true
                self.sendButton.isEnabled = true
                self.messageTextfield.text = ""  // Clear the message field 
            }
        }
    }
    
    
    //Retrieve Messages method from database
    func retrieveMessages() {
        
        //Access the database reference
        let messagesDB = Database.database().reference().child("Messages")
        
        //Observes the database to evey time it changes
        //.childAdded means to observe whenever a new entry is added into the database
        messagesDB.observe(.childAdded, with:  { (snapshot) in
           let snapshotValue = snapshot.value as! Dictionary<String, String> // all values inside the database. The values was stored as Dictionary, so it retrieves a dictionary
            let messageString = snapshotValue["MessageBody"]! // after retrieves the dictionary, now it gets the value inside it
            let senderEmail = snapshotValue["Sender"]! // // after retrieves the dictionary, now it gets the ket inside it
         
            //Creates a message object and assign the messageString and senderEmail to the objects propeties.
            let message = Message()
            message.messageText = messageString
            message.sender = senderEmail
            
            //Append the message object to the message array
            self.messageArray.append(message)
            self.configureTableView() // call the function to resize and refornat the size of the tableview cell
            self.messageTableView.reloadData() // Reload the message tableview with the new data
        })
        
    }
    
    
    
    @IBAction func logOutPressed(_ sender: AnyObject) {
        
        //Log out the user and send them back to WelcomeViewController
        
        do {
            try Auth.auth().signOut()
            print("DEVELOPER: User Logged out")
            navigationController?.popViewController(animated: true)
        }
        catch {
            print("DEVELOPER: Error, there was a problem signing out")
        }
        
    }

}
