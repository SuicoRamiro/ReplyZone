import UIKit

class CrearPerfilViewController: UIViewController {
    var correo: String? 
    
    @IBOutlet weak var TextFieldNombres: UITextField!
    @IBOutlet weak var TextFieldApellidos: UITextField!
    @IBOutlet weak var TextFieldTelefono: UITextField!
    @IBOutlet weak var TextFieldDNI: UITextField!
    @IBOutlet weak var TextFieldCorreo: UITextField!
    @IBOutlet weak var tipoCuentaPickerView: UISegmentedControl!
    let opcionesTipoCuenta = ["Cliente", "Trabajador"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configurar las opciones del UISegmentedControl
        tipoCuentaPickerView.removeAllSegments()
        for (index, opcion) in opcionesTipoCuenta.enumerated() {
            tipoCuentaPickerView.insertSegment(withTitle: opcion, at: index, animated: false)
        }
        
        // Seleccionar por defecto el primer segmento
        tipoCuentaPickerView.selectedSegmentIndex = 0

        if let correo = correo {
            TextFieldCorreo.text = correo
        }
    }

}
