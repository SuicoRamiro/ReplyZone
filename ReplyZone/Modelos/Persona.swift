import Foundation

struct Persona: Codable {
    let nombres: String
    let apellidoPaterno: String
    let apellidoMaterno: String
    let tipoDocumento: String
    let numeroDocumento: String
    let digitoVerificador: String?
}
