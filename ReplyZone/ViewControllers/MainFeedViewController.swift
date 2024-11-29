import UIKit
import Firebase
import FirebaseAuth

class MainFeedViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UISearchBarDelegate, PostCellDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    var posts = [Post]() // Array de todas las publicaciones
    var filteredPosts = [Post]() // Array de publicaciones filtradas (por búsqueda)
    var isSearching = false // Indica si el usuario está buscando contenido

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configuración de delegados y data source
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        
        // Registrar la celda personalizada
        collectionView.register(PostCell.self, forCellWithReuseIdentifier: "PostCell")
        
        // Cargar publicaciones desde Firebase
        fetchPosts()
        
        // Obtener información del perfil del usuario
        obtenerPerfilUsuario { user in
            if let user = user {
                print("Nombre de usuario: \(user.nombres)")
                print("Email: \(user.correo)")
                print("Tipo de cuenta: \(user.tipoCuenta)")
            } else {
                print("No se pudo obtener el usuario.")
            }
        }
        
        // Configuración de la barra de navegación
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(named: "ColorPrimario") // Color personalizado desde assets
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // Color del texto del título
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = UIColor.white // Color de los botones de la barra
    }

    // Método para cargar publicaciones desde Firebase
    func fetchPosts() {
        let databaseRef = Database.database().reference().child("posts") // Referencia a la base de datos en Firebase
        
        // Observar los cambios en la base de datos
        databaseRef.observe(.value) { snapshot in
            var newPosts = [Post]()
            
            for child in snapshot.children { // Recorrer cada nodo hijo
                if let childSnapshot = child as? DataSnapshot,
                   let dict = childSnapshot.value as? [String: Any],
                   let userName = dict["userName"] as? String,
                   let content = dict["content"] as? String,
                   let date = dict["date"] as? String {
                    
                    let imageUrl = dict["imageUrl"] as? String // URL opcional de la imagen
                    let post = Post(userName: userName, content: content, postId: childSnapshot.key, date: date, imageUrl: imageUrl)
                    newPosts.append(post)
                }
            }
            
            // Actualizar el array de publicaciones y recargar la colección
            self.posts = newPosts
            self.filteredPosts = newPosts
            self.collectionView.reloadData()
        }
    }

    // Configuración de celdas en la colección
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
        let post = isSearching ? filteredPosts[indexPath.row] : posts[indexPath.row]
        
        // Asignar el delegado y el postId a la celda
        cell.delegate = self
        cell.postId = post.postId
        
        // Configurar la celda con los datos del post y el tipo de cuenta del usuario
        obtenerPerfilUsuario { user in
            let tipoCuenta = user?.tipoCuenta
            cell.configure(with: post, tipoCuenta: tipoCuenta)
        }
        
        return cell
    }

    // Número de elementos en la colección
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return isSearching ? filteredPosts.count : posts.count
    }

    // Tamaño dinámico de las celdas en función del contenido
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let post = isSearching ? filteredPosts[indexPath.row] : posts[indexPath.row]
        let content = post.content
        let font = UIFont.systemFont(ofSize: 14)
        
        // Calcular el tamaño del texto
        let constraintRect = CGSize(width: collectionView.frame.width - 16, height: .greatestFiniteMagnitude)
        let boundingBox = content.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)
        
        let textHeight = boundingBox.height + 20
        let imageHeight: CGFloat = post.imageUrl != nil ? 150 : 0
        
        return CGSize(width: collectionView.frame.width, height: textHeight + imageHeight + 60)
    }

    // Actualización dinámica de los resultados de búsqueda
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredPosts = posts
        } else {
            isSearching = true
            filteredPosts = posts.filter { post in
                return post.userName.lowercased().contains(searchText.lowercased())
            }
        }
        collectionView.reloadData()
    }

    // Restablecer la búsqueda al cancelar
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        isSearching = false
        filteredPosts = posts
        collectionView.reloadData()
        searchBar.resignFirstResponder()
    }
    
    // Método para obtener el perfil del usuario actual desde Firebase
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
                print("Error al obtener el perfil del usuario.")
                completion(nil)
                return
            }
            completion(user)
        }
    }


    // Acción al tocar el botón de contacto en una publicación
    func didTapContactButton(on cell: PostCell) {
        guard let post = posts.first(where: { $0.postId == cell.postId }) else { return }
        
        obtenerPerfilUsuario { user in
            if let user = user {
                let senderId = post.userName
                let receiverId = user.dni
                self.performSegue(withIdentifier: "chatSegue", sender: (senderId, receiverId))
            }
        }
    }
    
    // Acción al eliminar una publicación
    func didDeletePost(on cell: PostCell) {
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        
        // Eliminar del array correcto y actualizar la colección
        if isSearching {
            filteredPosts.remove(at: indexPath.row)
        } else {
            posts.remove(at: indexPath.row)
        }
        
        collectionView.deleteItems(at: [indexPath])
    }

    // Preparación para la navegación entre pantallas
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "chatSegue", let (senderId, receiverId) = sender as? (String, String) {
            let chatVC = segue.destination as! ChatViewController
            chatVC.senderId = senderId
            chatVC.receiverId = receiverId
        }
    }
}
