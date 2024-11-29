import UIKit
import FirebaseAuth
import GoogleSignIn
import FirebaseCore

class LoginViewController: UIViewController {

    @IBOutlet weak var TextFieldCorreo: UITextField!
    @IBOutlet weak var TextFieldContraseña: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Configuración para Google Sign-In
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        // Establecer el color del texto de los TextFields
        TextFieldCorreo.textColor = .white
        TextFieldContraseña.textColor = .white
        
        // Cambiar el color del placeholder
        let placeholderTextCorreo = "Ingrese su correo electronico"
        TextFieldCorreo.attributedPlaceholder = NSAttributedString(
            string: placeholderTextCorreo,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )

        let placeholderTextContrasena = "Ingrese su contraseña"
        TextFieldContraseña.attributedPlaceholder = NSAttributedString(
            string: placeholderTextContrasena,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )
    }
    
    // Función para el inicio de sesión con correo y contraseña
    @IBAction func ButtonIniciarSesion(_ sender: Any) {
        guard let email = TextFieldCorreo.text, let password = TextFieldContraseña.text else {
            mostrarAlerta(titulo: "Error", mensaje: "Por favor, ingrese su correo y contraseña.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                // Mostrar mensaje de error
                self.mostrarAlerta(titulo: "Error", mensaje: "Error al iniciar sesión: La cuenta ingresada no existe")
                print("Se presentó el siguiente error: \(error)")
            } else {
                // Aquí navegamos al MainFeedViewController en caso de éxito
                self.performSegue(withIdentifier: "showMainFeed", sender: nil)
                print("Inicio de Sesión Exitoso")
            }
        }
    }
    
    // Función para el inicio de sesión con Google
    @IBAction func ButtonGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                self.mostrarAlerta(titulo: "Error", mensaje: "Error al iniciar sesión con Google: La cuenta ingresada no existe")
                return
            }
            
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                self.mostrarAlerta(titulo: "Error", mensaje: "No se pudo obtener el token de Google.")
                return
            }
            
            let accessToken = user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    self.mostrarAlerta(titulo: "Error", mensaje: "Error al autenticar con Firebase: \(error.localizedDescription)")
                    print("Error al autenticar con Firebase: \(error)")
                } else {
                    // Aquí navegamos al MainFeedViewController en caso de éxito
                    self.performSegue(withIdentifier: "showMainFeed", sender: nil)
                    print("Inicio de sesión exitoso con Google")
                }
            }
        }
    }
    
    // Función para mostrar una alerta genérica
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alerta, animated: true, completion: nil)
    }
}
