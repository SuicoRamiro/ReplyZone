import UIKit

class MessageCell: UITableViewCell {
    
    @IBOutlet weak var bubbleView: UIView!
    @IBOutlet weak var messageLabel: PaddedLabel!
    
    private var messageLabelConstraints: [NSLayoutConstraint] = []
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configura las esquinas redondeadas del label
        messageLabel.layer.cornerRadius = 8
        messageLabel.clipsToBounds = true
    }
    
    func configure(message: Message, isSent: Bool) {
        messageLabel.text = message.content
        
        // Eliminar constraints anteriores
        NSLayoutConstraint.deactivate(messageLabelConstraints)
        
        // Cambiar la apariencia dependiendo del remitente
        if isSent {
            messageLabel.backgroundColor = UIColor.colorPrimario
            messageLabel.textColor = UIColor.white
            
            // Ajustar las restricciones para el mensaje enviado (derecha)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabelConstraints = [
                messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
                messageLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 50), // Ajusta según sea necesario
                messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
            ]
        } else {
            messageLabel.backgroundColor = UIColor.darkGray
            messageLabel.textColor = UIColor.white
            
            // Ajustar las restricciones para el mensaje recibido (izquierda)
            messageLabel.translatesAutoresizingMaskIntoConstraints = false
            messageLabelConstraints = [
                messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                messageLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -50), // Ajusta según sea necesario
                messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
                messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
 
            ]
        }
        
        // Activar los nuevos constraints
        NSLayoutConstraint.activate(messageLabelConstraints)
    }
}

