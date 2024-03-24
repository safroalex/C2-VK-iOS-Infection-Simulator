//
//  ParametersInputViewController.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//

import UIKit
import Combine

class ParametersInputViewController: UIViewController {
    private var viewModel: VirusSpreadViewModel = VirusSpreadViewModel()
    private var subscriptions = Set<AnyCancellable>()
    
    private let groupSizeTextField = UITextField()
    private let infectionFactorTextField = UITextField()
    private let frequencyTextField = UITextField()
    private let startSimulationButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupLayout()
        setupBindings()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Добавление наблюдателей для скрытия клавиатуры при сворачивании приложения или его переходе в фоновый режим
        NotificationCenter.default.addObserver(self, selector: #selector(dismissKeyboard), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(dismissKeyboard), name: UIApplication.didEnterBackgroundNotification, object: nil)

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
            return
        }
        var shouldMoveViewUp = false

        // Если активное текстовое поле есть и клавиатура перекрывает это текстовое поле, то сдвигаем вверх
        let bottomOfTextField = startSimulationButton.convert(startSimulationButton.bounds, to: self.view).maxY;
        let topOfKeyboard = view.frame.height - keyboardSize.height

        if bottomOfTextField > topOfKeyboard {
            shouldMoveViewUp = true
        }

        if(shouldMoveViewUp) {
            self.view.frame.origin.y = 0 - keyboardSize.height
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        self.view.frame.origin.y = 0
    }


    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [groupSizeTextField, infectionFactorTextField, frequencyTextField, startSimulationButton])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.distribution = .fillEqually
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Установка стилей для текстовых полей
        [groupSizeTextField, infectionFactorTextField, frequencyTextField].forEach { textField in
            textField.borderStyle = .roundedRect
            textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
            textField.font = UIFont.systemFont(ofSize: 18)
        }
        
        // Настройки placeholder
        groupSizeTextField.placeholder = "Размер группы"
        infectionFactorTextField.placeholder = "Фактор заражения"
        frequencyTextField.placeholder = "Частота обновления (сек)"
        
        // Стилизация кнопки
        startSimulationButton.setTitle("Запустить симуляцию", for: .normal)
        startSimulationButton.backgroundColor = .systemBlue
        startSimulationButton.setTitleColor(.white, for: .normal)
        startSimulationButton.layer.cornerRadius = 10
        startSimulationButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        startSimulationButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        view.addSubview(stackView)
        
        // Изменение ограничений для размещения элементов у нижнего края view
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    
    private func setupBindings() {
        startSimulationButton.addTarget(self, action: #selector(startSimulationTapped), for: .touchUpInside)
    }
    
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
    
    func configure(with viewModel: VirusSpreadViewModel) {
        self.viewModel = viewModel
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        self.present(alert, animated: true)
    }
}


