import UIKit
import Firebase

class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var senderId: String!
    var receiverId: String!
    
    var messages = [Message]()
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        
        // Altura dinámica
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        
        observeMessages()
        
    }

    
    func observeMessages() {
        let chatId = getChatId(senderId: senderId, receiverId: receiverId)
        let messagesRef = Database.database().reference().child("chats").child(chatId).child("messages")
        
        messagesRef.observe(.childAdded) { snapshot in
            guard let messageData = snapshot.value as? [String: Any],
                  let senderId = messageData["senderId"] as? String,
                  let receiverId = messageData["receiverId"] as? String,
                  let content = messageData["content"] as? String,
                  let timestamp = messageData["timestamp"] as? TimeInterval else { return }
            
            let message = Message(senderId: senderId, receiverId: receiverId, content: content, timestamp: timestamp)
            self.messages.append(message)
            self.tableView.reloadData()
        }
        
    }
    
    func getChatId(senderId: String, receiverId: String) -> String {
        // El ID del chat puede ser una combinación de los ID de los usuarios
        let ids = [senderId, receiverId].sorted()
        return ids.joined(separator: "_")
    }
    
    @IBAction func sendMessage(_ sender: Any) {
        guard let content = messageTextField.text, !content.isEmpty else { return }
        
        let message = Message(senderId: senderId, receiverId: receiverId, content: content, timestamp: Date().timeIntervalSince1970)
        
        let chatId = getChatId(senderId: senderId, receiverId: receiverId)
        let messageRef = Database.database().reference().child("chats").child(chatId).child("messages").childByAutoId()
        
        let messageData: [String: Any] = [
            "senderId": message.senderId,
            "receiverId": message.receiverId,
            "content": message.content,
            "timestamp": message.timestamp
        ]
        
        messageRef.setValue(messageData)
        messageTextField.text = "" // Limpiar el campo de texto
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath) as! MessageCell
        
        // Verifica si el mensaje fue enviado por el usuario actual
        let isSent = message.senderId == senderId
        cell.configure(message: message, isSent: isSent)
        
        return cell
    }

}
