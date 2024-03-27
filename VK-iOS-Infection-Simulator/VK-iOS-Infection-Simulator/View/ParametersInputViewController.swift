//
//  ParametersInputViewController.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//

import UIKit
import Combine

/// Контроллер ввода параметров для настройки и запуска симуляции распространения вируса.
class ParametersInputViewController: UIViewController {
    // MARK: - Private Properties
    private var viewModel: VirusSpreadViewModel = VirusSpreadViewModel()
    private var subscriptions = Set<AnyCancellable>()

    // UI-элементы для ввода пользовательских данных.
    private let groupSizeTextField = UITextField()
    private let infectionFactorTextField = UITextField()
    private let frequencyTextField = UITextField()
    private let startSimulationButton = UIButton(type: .system)
    
    // MARK: - Lifecycle Methods
    
    /// Вызывается после загрузки представления контроллера.
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupBindings()

        // Подписка на уведомления клавиатуры.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Подписка на уведомления приложения для скрытия клавиатуры.
        NotificationCenter.default.addObserver(self, selector: #selector(dismissKeyboard), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissKeyboard), name: UIApplication.didEnterBackgroundNotification, object: nil)

        // Добавление жеста для скрытия клавиатуры.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    /// Скрывает клавиатуру.
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    /// Отписывается от всех уведомлений при деинициализации контроллера.
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Keyboard Observing
        
    /// Поднимает представление при появлении клавиатуры, если необходимо.
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        var shouldMoveViewUp = false

        let bottomOfTextField = startSimulationButton.convert(startSimulationButton.bounds, to: self.view).maxY;
        let topOfKeyboard = view.frame.height - keyboardSize.height

        if bottomOfTextField > topOfKeyboard {
            shouldMoveViewUp = true
        }

        if (shouldMoveViewUp) {
            self.view.frame.origin.y = 0 - keyboardSize.height
        }
    }

    /// Возвращает представление на исходную позицию при исчезновении клавиатуры.
    @objc private func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }

    // MARK: - Setup Methods
    
    /// Настраивает макет UI-компонентов в представлении.
    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [groupSizeTextField, infectionFactorTextField, frequencyTextField, startSimulationButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        [groupSizeTextField, infectionFactorTextField, frequencyTextField].forEach { textField in
            textField.borderStyle = .roundedRect
            textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
            textField.font = UIFont.systemFont(ofSize: 18)
        }
        
        groupSizeTextField.placeholder = "Размер группы"
        infectionFactorTextField.placeholder = "Фактор заражения"
        frequencyTextField.placeholder = "Частота обновления (сек)"
        
        startSimulationButton.setTitle("Запустить симуляцию", for: .normal)
        startSimulationButton.backgroundColor = .systemBlue
        startSimulationButton.setTitleColor(.white, for: .normal)
        startSimulationButton.layer.cornerRadius = 10
        startSimulationButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        startSimulationButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    /// Устанавливает привязки между UI-компонентами и моделью представления.
    private func setupBindings() {
        startSimulationButton.addTarget(self, action: #selector(startSimulationTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    /// Обрабатывает нажатие кнопки "Запустить симуляцию".
    @objc private func startSimulationTapped() {
        dismissKeyboard()
        
        guard let groupSizeText = groupSizeTextField.text,
              let groupSize = Int(groupSizeText), groupSize > 0 else {
            showAlert(title: "Ошибка ввода", message: "Количество людей в группе должно быть положительным числом.")
            return
        }
        
        guard let infectionFactorText = infectionFactorTextField.text,
              let infectionFactor = Int(infectionFactorText), infectionFactor > 0, infectionFactor <= groupSize else {
            showAlert(title: "Ошибка ввода", message: "Фактор заражения должен быть положительным числом, не превышающим общее количество людей.")
            return
        }
        
        guard let frequencyText = frequencyTextField.text,
              let frequency = Double(frequencyText), frequency > 0.0 else {
            showAlert(title: "Ошибка ввода", message: "Период пересчёта должен быть положительным числом секунд.")
            return
        }
        
        viewModel.setupSimulation(groupSize: groupSize, infectionFactor: infectionFactor, frequency: frequency)
        viewModel.startSimulation()
        
        let simulationVC = SimulationViewController()
        simulationVC.configure(with: viewModel)
        navigationController?.pushViewController(simulationVC, animated: true)
    }
    
    // MARK: - Configuration
    
    /// Конфигурирует контроллер с помощью модели представления.
    /// - Parameter viewModel: Модель представления для настройки.
    func configure(with viewModel: VirusSpreadViewModel) {
        self.viewModel = viewModel
    }
    
    /// Показывает всплывающее окно с предупреждением.
    /// - Parameters:
    ///   - title: Заголовок предупреждения.
    ///   - message: Сообщение предупреждения.
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}
