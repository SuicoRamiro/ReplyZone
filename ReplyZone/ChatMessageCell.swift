import UIKit

class ChatMessageCell: UITableViewCell {
    // La vista de fondo actuará como burbuja
    private let bubbleBackgroundView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray5 // Color de fondo de la burbuja
        return view
    }()
    
    // Label para el mensaje
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Constraints para alinear la burbuja
    private var leadingConstraint: NSLayoutConstraint!
    private var trailingConstraint: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        // Configura la celda agregando la vista de burbuja y el label del mensaje
        contentView.addSubview(bubbleBackgroundView)
        contentView.addSubview(messageLabel)
        
        // Constraints para la burbuja
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            messageLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 250),
            
            bubbleBackgroundView.topAnchor.constraint(equalTo: messageLabel.topAnchor, constant: -8),
            bubbleBackgroundView.leadingAnchor.constraint(equalTo: messageLabel.leadingAnchor, constant: -8),
            bubbleBackgroundView.bottomAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 8),
            bubbleBackgroundView.trailingAnchor.constraint(equalTo: messageLabel.trailingAnchor, constant: 8),
        ])
        
        // Leading y trailing constraints para alinear a la izquierda o derecha
        leadingConstraint = messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20)
        trailingConstraint = messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configurar la celda para mensajes enviados y recibidos
    func configure(with message: String, isSentByCurrentUser: Bool) {
        messageLabel.text = message
        bubbleBackgroundView.backgroundColor = isSentByCurrentUser ? .systemBlue : .systemGray5
        messageLabel.textColor = isSentByCurrentUser ? .white : .black
        
        if isSentByCurrentUser {
            leadingConstraint.isActive = false
            trailingConstraint.isActive = true
        } else {
            leadingConstraint.isActive = true
            trailingConstraint.isActive = false
        }
    }
}
