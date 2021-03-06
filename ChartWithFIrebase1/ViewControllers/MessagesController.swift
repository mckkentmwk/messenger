//
//  ViewController.swift
//  ChartWithFIrebase1
//
//  Created by kyucraquispe on 2/28/20.
//  Copyright © 2020 kyucraquispe. All rights reserved.
//

import UIKit
import Firebase

class MessagesController: UITableViewController {

    var messages  = [Message]()
    var messagesDictionary  = [String: Message]()
    let cellId = "cellId"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleLogout))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Message", style: .plain, target: self, action: #selector(handleNewMessage))
        
        checkIfUserIsLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
        //observeMessages()
    }
    
    func observeUserMessages() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("Does not exist current user")
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            let messageId = snapshot.key
            let messagesReference = Database.database().reference().child("messages").child(messageId)
            
            messagesReference.observeSingleEvent(of: .value, with: { (snapshot) in
                //print(snapshot)
                if let dictionary = snapshot.value as? [String: AnyObject] {
                    let message = Message()
                    message.fromId = dictionary["fromId"] as? String
                    message.text = dictionary["text"] as? String
                    message.timestamp = dictionary["timestamp"] as? NSNumber
                    message.toId = dictionary["toId"] as? String
                    
                    //self.messages.append(message)
                    if let toId = message.toId {
                        self.messagesDictionary[toId] = message
                        self.messages = Array(self.messagesDictionary.values)
                        self.messages.sort { (msg1, msg2) -> Bool in
                            return msg1.timestamp!.intValue > msg2.timestamp!.intValue
                        }
                    }
                    
                    self.tableView.reloadData()
                    
                    //print(message.text ?? "no message")
                }
            }, withCancel: nil)
        }, withCancel: nil)
    }
    
    func observeMessages() {
        let ref = Database.database().reference().child("messages")
        ref.observe(.childAdded) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let message = Message()
                message.fromId = dictionary["fromId"] as? String
                message.text = dictionary["text"] as? String
                message.timestamp = dictionary["timestamp"] as? NSNumber
                message.toId = dictionary["toId"] as? String
                
                //self.messages.append(message)
                if let toId = message.toId {
                    self.messagesDictionary[toId] = message
                    self.messages = Array(self.messagesDictionary.values)
                    self.messages.sort { (msg1, msg2) -> Bool in
                        return msg1.timestamp!.intValue > msg2.timestamp!.intValue
                    }
                }
                
                self.tableView.reloadData()
                
                //print(message.text ?? "no message")
            }
           
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 72
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }
    
    
    @objc func handleNewMessage() {
        let newMessageController = NewMessageController()
        newMessageController.messageController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        self.present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserIsLoggedIn() {
        //user is not logged in
        guard let uid = Auth.auth().currentUser?.uid else {
            handleLogout()
            return
        }
        
        Database.database().reference().child("users").child(uid).observe(.value) { (snapshot) in
            if let dictionary = snapshot.value as? [String: AnyObject] {
                let user = User()
                user.id = snapshot.key
                user.name = dictionary["name"] as? String
                user.email = dictionary["email"] as? String
                user.profileImageUrl = dictionary["profileImageUrl"] as? String
                self.setupNavbarWithUser(user: user)
            }
        }
    }
    
    func setupNavbarWithUser(user: User) {
        //self.navigationItem.title = user.name
        self.messages.removeAll()
        self.messagesDictionary.removeAll()
        self.tableView.reloadData()
        
        observeUserMessages()
        
        let titleView = UIView()
        
        var dinamicWidth = CGFloat(integerLiteral: 100)
        if let sizeOfName = user.name?.width(withConstrainedHeight: titleView.frame.size.height, font: UILabel().font) {
            dinamicWidth = sizeOfName + CGFloat(integerLiteral: 56)
        }
        titleView.frame = CGRect(x: 0, y: 0, width: dinamicWidth, height: 40)
        
        self.navigationItem.titleView = titleView
        
        let profileImageView = UIImageView()
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        if let profileImageUrl = user.profileImageUrl {
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        titleView.addSubview(profileImageView)
        
        //Constraints for profileImageView, needs: x, y, height and width
        profileImageView.leftAnchor.constraint(equalTo: titleView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        
        
        nameLabel.text = user.name
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(nameLabel)
        
        //Constraints for nameLabel, needs: x, y, height and width
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: titleView.rightAnchor).isActive = true
        nameLabel.topAnchor.constraint(equalTo: titleView.topAnchor).isActive = true
        nameLabel.bottomAnchor.constraint(equalTo: titleView.bottomAnchor).isActive = true
    }
    
    @objc func showChatControllerWithUser(user: User) {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func handleLogout() {
        // try to logout
        do {
            try Auth.auth().signOut()
        } catch let logoutError {
            print(logoutError)
        }
        
        let loginController = LoginController()
        loginController.callbackClosure = { [weak self] in
            self?.checkIfUserIsLoggedIn()
        }
        //Ask Tom why this have a strange behavior. Video1 : min 10
        self.present(loginController, animated: true, completion: nil)
        
    }


}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.width)
    }
}
