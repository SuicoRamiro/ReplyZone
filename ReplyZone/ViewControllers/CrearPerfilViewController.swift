import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class CrearPerfilViewController: UIViewController {
    var correo: String?
    var nombres: String?
    var apellidos: String?
    var dni: String?
    
    @IBOutlet weak var fondoImageView: UIImageView!
    @IBOutlet weak var TextFieldNombres: UITextField!
    @IBOutlet weak var TextFieldApellidos: UITextField!
    @IBOutlet weak var TextFieldTelefono: UITextField!
    @IBOutlet weak var TextFieldDNI: UITextField!
    @IBOutlet weak var TextFieldCorreo: UITextField!
    @IBOutlet weak var tipoCuentaPickerView: UISegmentedControl!
    
    let opcionesTipoCuenta = ["Cliente", "Trabajador"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Asignar los valores recibidos a los TextFields correspondientes
        if let nombres = nombres {
            TextFieldNombres.text = nombres
        }
        if let apellidos = apellidos {
            TextFieldApellidos.text = apellidos
        }
        if let dni = dni {
            TextFieldDNI.text = dni
        }
        if let correo = correo {
            TextFieldCorreo.text = correo
        }
        
        tipoCuentaPickerView.removeAllSegments()
        for (index, opcion) in opcionesTipoCuenta.enumerated() {
            tipoCuentaPickerView.insertSegment(withTitle: opcion, at: index, animated: false)
        }
        
        tipoCuentaPickerView.selectedSegmentIndex = 0
        actualizarImagenDeFondo()
        
        tipoCuentaPickerView.addTarget(self, action: #selector(cambioTipoCuenta), for: .valueChanged)
    }
    
    @objc func cambioTipoCuenta() {
        actualizarImagenDeFondo()
    }
    
    func actualizarImagenDeFondo() {
        let imagenFondo: UIImage?
        if tipoCuentaPickerView.selectedSegmentIndex == 0 {
            imagenFondo = UIImage(named: "fondoCliente")
        } else {
            imagenFondo = UIImage(named: "fondoTrabajador")
        }
        
        UIView.transition(with: fondoImageView, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.fondoImageView.image = imagenFondo
        }, completion: nil)
    }
    
    @IBAction func ButtonCancelar(_ sender: Any) {
        eliminarDNIYRegresar()
        eliminarCuentaYRegresar()
    }
    
    func eliminarCuentaYRegresar() {
        guard let usuarioActual = Auth.auth().currentUser else {
            regresarDosVistasAtras()
            return
        }
        
        usuarioActual.delete { error in
            if let error = error {
                print("Error al eliminar la cuenta: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.regresarDosVistasAtras()
                }
            }
        }
    }
    
    func eliminarDNIYRegresar() {
        guard let dniParaEliminar = TextFieldDNI.text, !dniParaEliminar.isEmpty else {
            print("El campo DNI está vacío.")
            regresarDosVistasAtras()
            return
        }

        // Referencia a la base de datos
        let databaseRef = Database.database().reference()
        
        // Ruta donde se encuentra el DNI a eliminar
        let dniPath = "DNI/\(dniParaEliminar)" // Ajusta esta ruta según tu estructura de datos

        // Eliminar el DNI de la base de datos
        databaseRef.child(dniPath).removeValue { error, _ in
            if let error = error {
                print("Error al eliminar el DNI de la base de datos: \(error.localizedDescription)")
            } else {
                print("DNI eliminado exitosamente.")
            }
        }
    }

    func regresarDosVistasAtras() {
        if let presentingViewController = self.presentingViewController?.presentingViewController {
            // Cierra las dos vistas modales
            presentingViewController.dismiss(animated: true, completion: nil)
        } else {
            // Si no hay dos vistas, descarta solo la actual
            self.dismiss(animated: true, completion: nil)
        }
    }

    
    @IBAction func ButtonGuardar(_ sender: Any) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: No hay un usuario autenticado.")
            return
        }
        
        let user = User(
            nombres: TextFieldNombres.text ?? "",
            apellidos: TextFieldApellidos.text ?? "",
            telefono: TextFieldTelefono.text ?? "",
            dni: TextFieldDNI.text ?? "",
            correo: TextFieldCorreo.text ?? "",
            tipoCuenta: opcionesTipoCuenta[tipoCuentaPickerView.selectedSegmentIndex]
        )
        
        let databaseRef = Database.database().reference()
        
        // Convertir la instancia de `User` a un diccionario
        if let userData = try? JSONEncoder().encode(user),
           let userDict = try? JSONSerialization.jsonObject(with: userData, options: []) as? [String: Any] {
            databaseRef.child("usuarios").child(userId).setValue(userDict) { error, _ in
                if let error = error {
                    print("Error al guardar el perfil: \(error.localizedDescription)")
                } else {
                    print("Perfil guardado exitosamente.")
                }
            }
        }
    }
}
