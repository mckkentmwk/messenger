//
//  ChatLogController.swift
//  ChartWithFIrebase1
//
//  Created by kyucraquispe on 3/7/20.
//  Copyright © 2020 kyucraquispe. All rights reserved.
//

import UIKit
import Firebase

class ChatLogController: UICollectionViewController, UITextFieldDelegate {
    
    var user: User? {
        didSet {
            navigationItem.title = user?.name
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColor = .white
        
        setupInputComponents()
    }
    
    func setupInputComponents() {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        //TODO: ask tom how to create the ViewController respecting the bottom part
        //anchor constraints, needs: x,y,w,h
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        
        containerView.addSubview(sendButton)
        
        //anchors contraints
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        containerView.addSubview(inputTextField)
        
        //anchors constraints
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = .black
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(separatorLineView)
        
        //anchors contraints
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
    }
    
    @objc func handleSend() {
        print("calling handleSend")
        let ref = Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let timestamp = Int(NSDate().timeIntervalSince1970)
        if let textMessage = inputTextField.text, let toId = user?.id, let fromId = Auth.auth().currentUser?.uid {
            let values = ["text": textMessage, "toId": toId, "fromId": fromId, "timestamp": timestamp] as [String : Any]
            
            //update a new message under a different key
            childRef.updateChildValues(values) { (error, reference) in
                if error != nil {
                    print(error)
                    return
                }
                
                let userMessagesRef = Database.database().reference().child("user-messages").child(fromId)
                let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId)
                
                if let messageId = childRef.key {
                    userMessagesRef.updateChildValues([messageId:1])
                    recipientUserMessagesRef.updateChildValues([messageId:1])
                }
            }
        } else {
            assert(true, "unable to sent message, one of the indispensables values is null")
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
}
