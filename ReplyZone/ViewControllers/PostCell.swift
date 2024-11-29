import UIKit
import SDWebImage
import Firebase
import FirebaseAuth

protocol PostCellDelegate: AnyObject {
    func didTapContactButton(on cell: PostCell)
}

class PostCell: UICollectionViewCell {
    
    weak var delegate: PostCellDelegate?
    
    var postId: String?
    
    private let userNameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .heavy)
        label.textColor = .white
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = .gray
        return label
    }()
    
    private let postImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
    private let contactButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Contactar", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 18
        return button
    }()
    
    private let userInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        return stackView
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Borrar", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .colorPrimario
        button.layer.cornerRadius = 18
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        userInfoStackView.addArrangedSubview(userNameLabel)
        userInfoStackView.addArrangedSubview(dateLabel)
        
        contentView.addSubview(userInfoStackView)
        contentView.addSubview(contentLabel)
        contentView.addSubview(postImageView)
        contentView.addSubview(contactButton)
        contentView.addSubview(deleteButton)
        
        // Configurar constraints
        userInfoStackView.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        postImageView.translatesAutoresizingMaskIntoConstraints = false
        contactButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            userInfoStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            userInfoStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            userInfoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            contentLabel.topAnchor.constraint(equalTo: userInfoStackView.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            postImageView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 8),
            postImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            postImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            postImageView.heightAnchor.constraint(equalToConstant: 150),
            
            contactButton.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 8),
            contactButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            contactButton.heightAnchor.constraint(equalToConstant: 30),
            contactButton.widthAnchor.constraint(equalToConstant: 80),
            contactButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            deleteButton.topAnchor.constraint(equalTo: postImageView.bottomAnchor, constant: 8),
            deleteButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            deleteButton.heightAnchor.constraint(equalToConstant: 30),
            deleteButton.widthAnchor.constraint(equalToConstant: 80),
            deleteButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
        
        contentView.layer.cornerRadius = 8
        contentView.backgroundColor = .fondo
        
        contactButton.addTarget(self, action: #selector(contactButtonTapped), for: .touchUpInside)
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(with post: Post, tipoCuenta: String?) {
        userNameLabel.text = post.userName
        contentLabel.text = post.content
        dateLabel.text = post.date
        postId = post.postId // Asignar el ID del post
        
        // Obtener perfil del usuario actual
        obtenerPerfilUsuario { [weak self] user in
            guard let self = self else { return }
            guard let user = user else {
                self.deleteButton.isHidden = true // Ocultar si no se obtiene el usuario
                self.contactButton.isHidden = true // Ocultar el botón "Contactar" si no hay usuario
                return
            }
            
            // Concatenar nombres y apellidos
            let fullName = "\(user.nombres) \(user.apellidos)"
            
            // Mostrar el botón "Borrar" solo si el userName del post coincide con el nombre completo del usuario
            self.deleteButton.isHidden = post.userName != fullName ? true : false
            
            // Mostrar el botón "Contactar" solo si el tipo de cuenta es "Trabajador" y el nombre completo del usuario logueado es diferente al del post
            if tipoCuenta == "Trabajador" && post.userName != fullName {
                self.contactButton.isHidden = false
            } else {
                self.contactButton.isHidden = true
            }
        }
        
        // Manejar la visibilidad y altura de la imagen
        if let imageUrlString = post.imageUrl, let imageUrl = URL(string: imageUrlString) {
            postImageView.sd_setImage(with: imageUrl, placeholderImage: UIImage(named: "placeholder")) { [weak self] _, _, _, _ in
                self?.setNeedsLayout()
            }
            
            postImageView.isHidden = false
            postImageView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        } else {
            postImageView.image = UIImage(named: "placeholder")
            postImageView.isHidden = true
            postImageView.heightAnchor.constraint(equalToConstant: 0).isActive = true
        }
        
        layoutIfNeeded()
    }

    func obtenerPerfilUsuario(completion: @escaping (User?) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No hay un usuario autenticado.")
            completion(nil)
            return
        }
        
        let databaseRef = Database.database().reference()
        databaseRef.child("usuarios").child(userId).observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let jsonData = try? JSONSerialization.data(withJSONObject: userData),
                  let user = try? JSONDecoder().decode(User.self, from: jsonData) else {
                print("Error al obtener los datos del usuario.")
                completion(nil)
                return
            }
            completion(user)
        }
    }
    
    private func deletePost(withId id: String) {
        let databaseRef = Database.database().reference()
        databaseRef.child("posts").child(id).removeValue { [weak self] error, _ in
            if let error = error {
                print("Error al borrar el post: \(error.localizedDescription)")
            } else {
                print("Post borrado exitosamente.")
                // Aquí no llamamos al delegado para evitar la navegación al chat
            }
        }
    }
    
    @objc private func contactButtonTapped() {
        delegate?.didTapContactButton(on: self)
    }
    
    @objc private func deleteButtonTapped() {
        guard let postId = postId else { return }
        deletePost(withId: postId)
    }
}

