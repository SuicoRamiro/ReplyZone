import UIKit
import Firebase
import GoogleSignIn
import FirebaseCore
import FirebaseAuth

class CreateViewController: UIViewController {

    @IBOutlet weak var TextFieldCorreo: UITextField!
    @IBOutlet weak var TextFieldContraseña: UITextField!
    
    // Variable para almacenar el correo a pasar al siguiente ViewController
    var correoParaPerfil: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: FirebaseApp.app()?.options.clientID ?? "")

        // Configuración de los campos de texto y placeholders
        configurarCampoTexto(TextFieldCorreo, placeholder: "Ingrese un correo electrónico existente", color: .white)
        configurarCampoTexto(TextFieldContraseña, placeholder: "Ingrese una contraseña segura", color: .white)
        
        // Hacer que el campo de contraseña oculte el texto
        TextFieldContraseña.isSecureTextEntry = true
    }
    
    func configurarCampoTexto(_ textField: UITextField, placeholder: String, color: UIColor) {
        textField.textColor = color
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
    }
    
    @IBAction func ButtonCrear(_ sender: Any) {
        guard let email = TextFieldCorreo.text, !email.isEmpty,
              let password = TextFieldContraseña.text, !password.isEmpty else {
            mostrarAlerta(titulo: "Error", mensaje: "Por favor, complete todos los campos.")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error as NSError? {
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue {
                    self.mostrarAlerta(titulo: "Error", mensaje: "La cuenta con este correo electrónico ya está en uso.")
                } else {
                    self.mostrarAlerta(titulo: "Error", mensaje: "Se presentó un error: \(error.localizedDescription)")
                }
                return
            }
            
            // Almacenar el correo para pasar al siguiente ViewController
            self.correoParaPerfil = email
            self.performSegue(withIdentifier: "verificarSegue", sender: nil)
        }
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
            
            // Obtener el correo del usuario autenticado
            let correo = user.profile?.email
            
            // Verificar si el correo ya está registrado en Firebase
            Database.database().reference().child("usuarios").queryOrdered(byChild: "correo").queryEqual(toValue: correo).observeSingleEvent(of: .value) { snapshot in
                if snapshot.exists() {
                    self.mostrarAlerta(titulo: "Error", mensaje: "La cuenta con este correo electrónico ya está en uso.")
                } else {
                    let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
                    
                    Auth.auth().signIn(with: credential) { authResult, error in
                        if let error = error {
                            self.mostrarAlerta(titulo: "Error", mensaje: "Error al autenticar en Firebase: \(error.localizedDescription)")
                        } else {
                            // Almacenar el correo para pasar al siguiente ViewController
                            self.correoParaPerfil = correo
                            // Realizar el segue
                            self.performSegue(withIdentifier: "verificarSegue", sender: nil)
                        }
                    }
                }
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "verificarSegue" {
            let destinoVC = segue.destination as! VerificarIdentificacionViewController
            destinoVC.correo = correoParaPerfil // Pasar el correo al siguiente ViewController
        }
    }

    
    func mostrarAlerta(titulo: String, mensaje: String) {
        let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alerta, animated: true, completion: nil)
    }
}
