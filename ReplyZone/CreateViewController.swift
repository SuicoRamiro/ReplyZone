import UIKit
import Firebase
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

class CreateViewController: UIViewController {

    @IBOutlet weak var TextFieldCorreo: UITextField!
    @IBOutlet weak var TextFieldContraseña: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        // Establecer el color del texto
        TextFieldCorreo.textColor = .white // O el color que prefieras
        
        // Cambiar el color del placeholder
        let placeholderTextCorreo = "Ingrese un correo electronico existente"
        TextFieldCorreo.attributedPlaceholder = NSAttributedString(
            string: placeholderTextCorreo,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )

        // Configuración para el campo de contraseña
        TextFieldContraseña.textColor = .white
        
        // Cambiar el color del placeholder
        let placeholderTextContrasena = "Ingrese una contraseña segura"
        TextFieldContraseña.attributedPlaceholder = NSAttributedString(
            string: placeholderTextContrasena,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white]
        )
    }
    
    
    @IBAction func ButtonCrear(_ sender: Any) {
        
    }
    
    @IBAction func ButtonGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { signInResult, error in
            if let error = error {
                print("Error al iniciar sesión con Google: \(error.localizedDescription)")
                return
            }
            guard let user = signInResult?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Error: No se pudo obtener el ID Token o Access Token.")
                return
            }
            let accessToken = user.accessToken.tokenString

            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)

            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Error al autenticar en Firebase: \(error.localizedDescription)")
                } else {
                    print("Inicio de sesión exitoso con Google!")
                }
            }
        }
    }
}
