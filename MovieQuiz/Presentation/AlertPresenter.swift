import UIKit

final class AlertPresenter: AlertPresenterProtocol {
   
    weak var viewController: UIViewController?
    
    init(viewController: UIViewController?) {
        self.viewController = viewController
    }
    
    func showQuizResult(model: AlertModel) {
        let alert = UIAlertController(
            title: model.title,
            message: model.message,
            preferredStyle: .alert)
        let action = UIAlertAction(
            title: model.buttonText,
            style: .default) { _ in
                model.completion()}
        
        alert.addAction(action)
        alert.preferredAction = action
        alert.view.accessibilityIdentifier = "Game results"
        
        viewController?.present(alert, animated: true, completion: nil)
    }
}
