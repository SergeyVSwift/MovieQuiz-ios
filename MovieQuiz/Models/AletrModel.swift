import Foundation

// Структура для Алерта
struct AlertModel {
    let title: String
    let message: String
    let buttonText: String
    let completion: () -> Void
}
    
