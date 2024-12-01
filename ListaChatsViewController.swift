import UIKit
import Firebase
import FirebaseAuth

class ListaChatsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    var chats = [(senderId: String, receiverId: String)]() // Array para almacenar los chats
    var userFullName: String?
    var userDNI: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Verificar si el usuario está autenticado
        if let user = Auth.auth().currentUser {
            print("Usuario autenticado: \(user.uid)") // Imprime el ID del usuario autenticado
            obtenerPerfilUsuario { user in
                if let user = user {
                    self.userFullName = "\(user.nombres) \(user.apellidos)"
                    self.userDNI = user.dni
                    print("Datos recogidos del usuario:")
                    print("Nombre completo: \(self.userFullName ?? "No disponible")")
                    print("DNI: \(self.userDNI ?? "No disponible")")
                    self.fetchChats()
                } else {
                    print("No se pudo obtener el usuario.")
                }
            }
        } else {
            print("No hay usuario autenticado")
        }
        
        tableView.dataSource = self
        tableView.delegate = self
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
                print("Error al obtener el perfil del usuario.")
                completion(nil)
                return
            }
            completion(user)
        }
    }

    func fetchChats() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No hay usuario autenticado")
            return
        }

        let chatsRef = Database.database().reference().child("chats")

        chatsRef.observeSingleEvent(of: .value) { snapshot in
            print("Snapshot: \(snapshot.value ?? "No data")") // Verifica el contenido del snapshot

            for child in snapshot.children {
                if let childSnapshot = child as? DataSnapshot {
                    let chatId = childSnapshot.key // ID del chat
                    let ids = chatId.split(separator: "_").map(String.init) // Separamos el chatId en dos partes

                    // Obtener el DNI y el nombre completo del usuario
                    let userDNI = self.userDNI ?? ""
                    let userFullName = self.userFullName ?? ""

                    // Verificación para saber si la primera parte de la ID del chat es el DNI del usuario
                    if ids.first == userDNI {
                        // Si coincide el DNI del usuario con el primer valor, el otro es el nombre completo
                        let otherUserId = ids[1] // El nombre completo del otro usuario
                        self.chats.append((senderId: userDNI, receiverId: otherUserId)) // Añades el DNI y el nombre completo
                        print("Chat encontrado: \(chatId) con \(otherUserId)")
                    } else if ids[1] == userFullName {
                        // Si el nombre completo del usuario coincide con la segunda parte de la ID, el otro es el DNI
                        let otherUserId = ids[0] // El DNI del otro usuario
                        self.chats.append((senderId: userFullName, receiverId: otherUserId)) // Añades el nombre completo y el DNI
                        print("Chat encontrado por nombre: \(chatId) con \(otherUserId)")
                    } else {
                        print("El chat \(chatId) no coincide con el usuario actual.")
                    }
                }
            }

            // Verificación del número total de chats encontrados
            print("Número de chats encontrados: \(self.chats.count)")

            // Recarga la tabla para mostrar los chats
            self.tableView.reloadData()
        } withCancel: { error in
            print("Error al obtener los chats: \(error.localizedDescription)")
        }
    }


    // Configuración de la tabla para mostrar chats
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chats.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatCell", for: indexPath)
        let chat = chats[indexPath.row]
        
        // Verificar si el receiverId es un número (DNI)
        if let _ = Int(chat.receiverId) {
            // Si receiverId es un número, realizar consulta a la base de datos
            obtenerNombreCompletoPorDNI(dni: chat.receiverId) { fullName in
                // Si se encontró un nombre completo, actualizar la celda
                DispatchQueue.main.async {
                    cell.textLabel?.text = fullName ?? "Nombre no disponible"
                    cell.textLabel?.textColor = .white
                }
            }
        } else {
            // Si receiverId no es un número, se asume que es el nombre completo
            cell.textLabel?.text = chat.receiverId
            cell.textLabel?.textColor = .white
        }

        return cell
    }

    // Función para obtener el nombre completo a partir del DNI
    func obtenerNombreCompletoPorDNI(dni: String, completion: @escaping (String?) -> Void) {
        let databaseRef = Database.database().reference()
        
        // Buscar en la base de datos usando el DNI
        databaseRef.child("usuarios").queryOrdered(byChild: "dni").queryEqual(toValue: dni).observeSingleEvent(of: .value) { snapshot in
            if let value = snapshot.value as? [String: Any] {
                // Si se encuentra un usuario con el DNI, construir el nombre completo
                if let user = value.first?.value as? [String: Any] {
                    let nombres = user["nombres"] as? String ?? ""
                    let apellidos = user["apellidos"] as? String ?? ""
                    let fullName = "\(nombres) \(apellidos)"
                    completion(fullName)
                } else {
                    completion(nil)
                }
            } else {
                completion(nil)
            }
        }
    }

    
    // Manejo de la selección de un chat
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chat = chats[indexPath.row]
        performSegue(withIdentifier: "verChatSegue", sender: chat)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "verChatSegue", let chat = sender as? (String, String) {
            // Imprimir senderId y receiverId en la terminal
            print("senderId: \(chat.0)")
            print("receiverId: \(chat.1)")
            
            let chatVC = segue.destination as! ChatViewController
            chatVC.receiverId = chat.0 // Accede al primer elemento de la tupla
            chatVC.senderId = chat.1 // Accede al segundo elemento de la tupla
        }
    }

}
