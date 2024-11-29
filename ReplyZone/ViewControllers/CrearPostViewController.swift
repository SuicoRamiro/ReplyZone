import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage

class CrearPostViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var imagePicker = UIImagePickerController()

    @IBOutlet weak var txtContenido: UITextView!
    @IBOutlet weak var imagenPost: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.delegate = self
    }

    @IBAction func albumTapped(_ sender: Any) {
        imagePicker.sourceType = .savedPhotosAlbum
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func camaraTapped(_ sender: Any) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func ButtonPublicar(_ sender: Any) {
        // Verificar si el campo de texto tiene contenido
        guard let contenido = txtContenido.text, !contenido.isEmpty else {
            print("Por favor, escribe algo antes de publicar.")
            return
        }

        guard let userID = Auth.auth().currentUser?.uid else {
            print("Usuario no autenticado.")
            return
        }

        let usersRef = Database.database().reference().child("usuarios").child(userID)

        usersRef.observeSingleEvent(of: .value) { snapshot in
            guard let userData = snapshot.value as? [String: Any],
                  let nombres = userData["nombres"] as? String,
                  let apellidos = userData["apellidos"] as? String else {
                print("No se pudo obtener el nombre del usuario.")
                return
            }

            let userName = "\(nombres) \(apellidos)" // Concatenar nombres y apellidos
            let databaseRef = Database.database().reference().child("posts").childByAutoId()

            if let image = self.imagenPost.image, let imageData = image.jpegData(compressionQuality: 0.50) {
                let imagenesFolder = Storage.storage().reference().child("imagenes").child("\(UUID().uuidString).jpg")

                imagenesFolder.putData(imageData, metadata: nil) { metadata, error in
                    if let error = error {
                        print("Error al subir la imagen: \(error.localizedDescription)")
                        return
                    }

                    imagenesFolder.downloadURL { (url, error) in
                        if let error = error {
                            print("Error al obtener la URL de la imagen: \(error.localizedDescription)")
                            return
                        }

                        guard let imageUrl = url?.absoluteString else {
                            print("No se pudo obtener la URL de la imagen.")
                            return
                        }

                        let post: [String: Any] = [
                            "userName": userName,
                            "content": contenido,
                            "date": self.getCurrentDate(),
                            "imageUrl": imageUrl
                        ]

                        databaseRef.setValue(post) { error, _ in
                            if let error = error {
                                print("Error al guardar la publicación: \(error.localizedDescription)")
                            } else {
                                print("Publicación guardada con éxito")
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            } else {
                let post: [String: Any] = [
                    "userName": userName,
                    "content": contenido,
                    "date": self.getCurrentDate()
                ]

                databaseRef.setValue(post) { error, _ in
                    if let error = error {
                        print("Error al guardar la publicación: \(error.localizedDescription)")
                    } else {
                        print("Publicación guardada con éxito")
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }

    // Función para obtener la fecha actual
    func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm" // Formato de hora
        let time = dateFormatter.string(from: Date())
        
        dateFormatter.dateFormat = "dd/MM/yy" // Formato de fecha
        let date = dateFormatter.string(from: Date())
        
        return "\(time) - \(date)" // Combina hora y fecha
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
        imagenPost.image = image
        imagenPost.backgroundColor = UIColor.clear
        imagePicker.dismiss(animated: true, completion: nil)
    }
}
