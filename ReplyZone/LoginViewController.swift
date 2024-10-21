import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var TextFieldCorreo: UITextField!
    @IBOutlet weak var TextFieldContraseña: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Establecer el color del texto
        TextFieldCorreo.textColor = .white // O el color que prefieras
        
        // Cambiar el color del placeholder
        let placeholderTextCorreo = "Ingrese su correo electronico"
        TextFieldCorreo.attributedPlaceholder = NSAttributedString(
            string: placeholderTextCorreo,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )

        // Configuración para el campo de contraseña
        TextFieldContraseña.textColor = .white
        
        // Cambiar el color del placeholder
        let placeholderTextContrasena = "Ingrese su contraseña"
        TextFieldContraseña.attributedPlaceholder = NSAttributedString(
            string: placeholderTextContrasena,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )
    }
    
    
    @IBAction func ButtonIniciarSesion(_ sender: Any) {
        Auth.auth().signIn(withEmail: TextFieldCorreo.text!, password: TextFieldContraseña.text! ) { (user, error) in print("Intentando Iniciar Sesion")
            if error != nil{
                print("Se presento el siguiente error: \(error)")
            }else{
                print("Inicio de Sesion Exitoso")
            }
        }
    }
    
}
