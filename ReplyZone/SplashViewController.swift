import UIKit

class SplashViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Spash de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.showLoginScreen() // Ahora simplemente irá a la pantalla de Login
        }
    }

    func showLoginScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") // Asegúrate que el Storyboard ID de tu pantalla de login sea correcto
        loginVC.modalPresentationStyle = .fullScreen
        self.present(loginVC, animated: true, completion: nil)
    }
}
