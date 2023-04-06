import UIKit

final class MovieQuizViewController: UIViewController, QuestionFactoryDelegate {
    
    
    //  MARK: - IB Actions
    // Кнопка "Да"
    @IBAction private func yesButtonClicked(_ sender: UIButton) {
        noButton.isEnabled = false
        yesButton.isEnabled = false
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = true
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    // Кнопка "Нет"
    @IBAction private func noButtonClicked(_ sender: UIButton) {
        noButton.isEnabled = false
        yesButton.isEnabled = false
        guard let currentQuestion = currentQuestion else { return }
        let givenAnswer = false
        showAnswerResult(isCorrect: givenAnswer == currentQuestion.correctAnswer)
    }
    
    // MARK: - Properties
    
    private var questionFactory: QuestionFactory?
    private var currentQuestion: QuizQuestion?
    private var alertPresenter: AlertPresenterProtocol?
    private var statisticService: StatisticService?
    
    private var currentQuestionIndex = 0 // Текущий вопрос
    private var correctAnswers: Int = 0 // Правильных ответов
    private let questionsAmount: Int = 10 // Максимальное количество вопросов
    
    
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var textOfQuestion: UILabel!
    @IBOutlet private weak var textLabel: UILabel!
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var counterLabel: UILabel!
    @IBOutlet private weak var indexQuestionText: UILabel!
    @IBOutlet private weak var questionLabelText: UILabel!
    @IBOutlet private weak var noButton: UIButton!
    @IBOutlet private weak var yesButton: UIButton!
    
    //  MARK: - UIStatusBarStyle
    // Изменяем цвет Статус Бара
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        alertPresenter = AlertPresenter(delegate: self)
        
        imageView.layer.cornerRadius = 20
        questionFactory = QuestionFactory(moviesLoader: MoviesLoader(), delegate: self)
        statisticService = StatisticServiceImplementation()
        
        showLoadingIndicator()
        questionFactory?.loadData()
        
    }
    
    //  MARK: - QuestionFactoryDelegate
    func didReceiveNextQuestion(question: QuizQuestion?) {
        guard let question = question else { return }
        
        currentQuestion = question
        let viewModel = convert(model: question)
        DispatchQueue.main.async { [weak self] in
            self?.show(quiz: viewModel)
        }
    }
    
    // MARK: - LoadQuestion
    func didLoadDataFromServer() {
        activityIndicator.isHidden = true // скрываем индикатор загрузки
        questionFactory?.requestNextQuestion()
    }
    
    func didFailToLoadData(with error: Error) {
        showNetworkError(message: error.localizedDescription) // возьмём в качестве сообщения описание ошибки
    }
    //MARK: - Private Func
    private func show(quiz step: QuizStepViewModel) {
        imageView.image = step.image
        imageView.layer.cornerRadius = 20
        textLabel.text = step.question
        counterLabel.text = step.questionNumber
    }
    
    private func showAnswerResult(isCorrect: Bool) {
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 8
        imageView.layer.cornerRadius = 20
        if isCorrect {
            imageView.layer.borderColor = UIColor.ypGreen.cgColor
            correctAnswers += 1
        } else {
            imageView.layer.borderColor = UIColor.ypRed.cgColor
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [ weak self ] in
            guard let self = self else { return }
            self.showNextQuestionOrResults()
            self.imageView.layer.borderWidth = 0
            self.noButton.isEnabled = true
            self.yesButton.isEnabled = true
        }
    }
    
    private func showLoadingIndicator() {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
    }
    
    private func hideLoadingIndicator() {
        activityIndicator.isHidden = true
    }
    
    private func convert(model: QuizQuestion) -> QuizStepViewModel {
        return QuizStepViewModel(
            image: UIImage(data: model.image) ?? UIImage(),
            question: model.text,
            questionNumber: "\(currentQuestionIndex + 1)/\(questionsAmount)")
    }
    
    // MARK: - NetworError
    private func showNetworkError(message: String){
        
        let errorScreen = AlertModel(title: "Ошибка",
                                     message: message,
                                     buttonText: "Попробовать еще раз",
                                     completion: { [weak self] in
            guard let self = self else { return }
            
            self.currentQuestionIndex = 0
            self.correctAnswers = 0
            
            self.questionFactory?.requestNextQuestion()
        })
        
        alertPresenter?.showQuizResult(model: errorScreen)
    }
    
    // MARK: - showNextQuestionOrResults
    private func showNextQuestionOrResults() {
        imageView.layer.borderWidth = 0
        if currentQuestionIndex == questionsAmount - 1 { // - 1 потому что индекс начинается с 0, а длинна массива — с 1
            imageView.layer.borderWidth = 8
            statisticService?.store(correct: correctAnswers, total: questionsAmount)
            guard let gamesCount = statisticService?.gamesCount else { return }
            guard let bestGame = statisticService?.bestGame else { return }
            guard let totalAccuracy = statisticService?.totalAccuracy else { return }
            
            // Финальная версия окончания игры
            let finalScreen = AlertModel (title: "Этот раунд окончен!",
                                          message: """
                                                    Ваш результат: \(correctAnswers)/\(questionsAmount)
                                                    Количество сыгранных квизов: \(gamesCount)
                                                    Рекорд: \(bestGame.correct)/\(bestGame.total) (\(bestGame.date.dateTimeString))
                                                    Средняя точность: \(String(format: "%.2f", totalAccuracy))%
                                                   """ ,
                                          buttonText: "Сыграть еще раз",
                                          completion: { [weak self] in
                guard let self = self else { return }
                self.imageView.layer.borderWidth = 0
                self.currentQuestionIndex = 0
                self.correctAnswers = 0
                self.questionFactory?.requestNextQuestion()
            })
            alertPresenter?.showQuizResult(model: finalScreen)
        } else {
            currentQuestionIndex += 1
            questionFactory?.requestNextQuestion()
        }
    }
}
