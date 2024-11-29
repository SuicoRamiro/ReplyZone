import UIKit
import Firebase
import FirebaseAuth
import FirebaseDatabase

class VerificarIdentificacionViewController: UIViewController {
    
    // UI Elements
    @IBOutlet weak var txtNombreCompleto: UITextField!
    @IBOutlet weak var txtDNI: UITextField!
    
    // Variables para almacenar los datos procesados
    var correo: String? // Recibido desde CreateViewController
    var nombresProcesados: String?
    var apellidosProcesados: String?
    var dniProcesado: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Configuración inicial, si es necesario
        configurarCampoTexto(txtNombreCompleto, placeholder: "Ingrese nombres y apellidos completos", color: .white)
        configurarCampoTexto(txtDNI, placeholder: "Ingrese su DNI", color: .white)
    }
    
    @IBAction func continuarTapped(_ sender: UIButton) {
        guard let dni = txtDNI.text, !dni.isEmpty,
              let nombreCompleto = txtNombreCompleto.text, !nombreCompleto.isEmpty else {
            mostrarAlerta(titulo: "Error", mensaje: "Por favor, ingrese todos los campos.")
            return
        }
        
        // Verificar que el DNI no exista ya en Firebase
        verificarDNIExistente(dni: dni) { [weak self] existe in
            guard let self = self else { return }
            
            if existe {
                self.mostrarAlerta(titulo: "Error", mensaje: "El documento de identificación ya ha sido usado.")
            } else {
                self.validarDNIConAPI(dni: dni, nombreCompleto: nombreCompleto)
            }
        }
    }
    
    @IBAction func cancelarTapped(_ sender: Any) {
        eliminarCuentaYRegresar()
    }
        
    func eliminarCuentaYRegresar() {
        guard let usuarioActual = Auth.auth().currentUser else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        
        usuarioActual.delete { error in
            if let error = error {
                print("Error al eliminar la cuenta: \(error.localizedDescription)")
            } else {
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
    }
    
    func verificarDNIExistente(dni: String, completion: @escaping (Bool) -> Void) {
        let ref = Database.database().reference()
        
        // Consultar en el nodo DNI si ya existe el DNI ingresado
        ref.child("DNI").child(dni).observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                completion(true)  // El DNI ya está registrado
            } else {
                completion(false)  // El DNI no está registrado
            }
        }
    }
    
    func validarDNIConAPI(dni: String, nombreCompleto: String) {
        let url = URL(string: "https://api.apis.net.pe/v2/reniec/dni?numero=\(dni)")!
        let token = "apis-token-11854.oWsHSJvgSXiHzH84jqsp0eeKncciLEXw"
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("https://apis.net.pe/consulta-dni-api", forHTTPHeaderField: "Referer")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                self.mostrarAlerta(titulo: "Error", mensaje: "Error al realizar la solicitud: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else {
                self.mostrarAlerta(titulo: "Error", mensaje: "Datos vacíos en la respuesta.")
                return
            }
            
            do {
                let persona = try JSONDecoder().decode(Persona.self, from: data)
                
                // Procesar la entrada del usuario
                let componentes = nombreCompleto.split(separator: " ").map { String($0).uppercased() }
                guard componentes.count >= 3 else {
                    self.mostrarAlerta(titulo: "Error", mensaje: "Por favor, ingrese al menos un nombre y dos apellidos.")
                    return
                }
                
                let apellidoMaternoIngresado = componentes.last!
                let apellidoPaternoIngresado = componentes[componentes.count - 2]
                let nombresIngresados = componentes.dropLast(2).joined(separator: " ")
                
                // Validar contra la API
                if persona.apellidoMaterno == apellidoMaternoIngresado,
                   persona.apellidoPaterno == apellidoPaternoIngresado,
                   persona.nombres == nombresIngresados {
                    
                    // Formatear nombres y apellidos
                    self.nombresProcesados = self.capitalizarTexto(persona.nombres)
                    let apellidoPaterno = self.capitalizarTexto(persona.apellidoPaterno)
                    let apellidoMaterno = self.capitalizarTexto(persona.apellidoMaterno)
                    self.apellidosProcesados = "\(apellidoPaterno) \(apellidoMaterno)"
                    self.dniProcesado = dni
                    
                    // Registrar el DNI en Firebase Realtime Database
                    self.registrarDNIEnFirebaseRealtime(dni: dni)
                    
                    DispatchQueue.main.async {
                        // Realizar el segue después de procesar los datos
                        self.performSegue(withIdentifier: "crearPerfilSegue", sender: nil)
                    }
                } else {
                    self.mostrarAlerta(titulo: "Error", mensaje: "Los datos ingresados no coinciden con la información de la API.")
                }
            } catch {
                self.mostrarAlerta(titulo: "Error", mensaje: "Error al decodificar JSON: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    func registrarDNIEnFirebaseRealtime(dni: String) {
        let ref = Database.database().reference()
        
        // Crear el objeto de registro con el DNI
        let dniRegistro: [String: Any] = [
            "dni": dni
        ]
        
        // Usar el DNI como la clave única para el nodo
        ref.child("DNI").child(dni).setValue(dniRegistro) { error, _ in
            if let error = error {
                print("Error al guardar el DNI en Realtime Database: \(error.localizedDescription)")
            } else {
                print("DNI guardado con éxito en Realtime Database.")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "crearPerfilSegue" {
            let destinoVC = segue.destination as! CrearPerfilViewController
            
            // Pasar los datos procesados al siguiente ViewController
            destinoVC.correo = correo
            destinoVC.nombres = nombresProcesados
            destinoVC.apellidos = apellidosProcesados
            destinoVC.dni = dniProcesado
        }
    }
    
    func capitalizarTexto(_ texto: String) -> String {
        return texto.lowercased().capitalized
    }
    
    func mostrarAlerta(titulo: String, mensaje: String) {
        DispatchQueue.main.async {
            let alerta = UIAlertController(title: titulo, message: mensaje, preferredStyle: .alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alerta, animated: true, completion: nil)
        }
    }
    
    func configurarCampoTexto(_ textField: UITextField, placeholder: String, color: UIColor) {
        textField.textColor = color
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: color]
        )
    }
}
