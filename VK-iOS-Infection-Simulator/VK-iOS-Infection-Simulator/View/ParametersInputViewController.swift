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
        view.backgroundColor = .white // Установим белый фон для контроллера
        setupLayout()
        setupBindings()
    }
    
    private func setupLayout() {
        let stackView = UIStackView(arrangedSubviews: [groupSizeTextField, infectionFactorTextField, frequencyTextField, startSimulationButton])
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        groupSizeTextField.borderStyle = .roundedRect
        groupSizeTextField.placeholder = "Размер группы"
        
        infectionFactorTextField.borderStyle = .roundedRect
        infectionFactorTextField.placeholder = "Фактор заражения"
        
        frequencyTextField.borderStyle = .roundedRect
        frequencyTextField.placeholder = "Частота обновления (сек)"
        
        startSimulationButton.setTitle("Запустить симуляцию", for: .normal)
        startSimulationButton.backgroundColor = .systemBlue
        startSimulationButton.setTitleColor(.white, for: .normal)
        startSimulationButton.layer.cornerRadius = 5
        
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func setupBindings() {
        startSimulationButton.addTarget(self, action: #selector(startSimulationTapped), for: .touchUpInside)
        
        // Если потребуется, здесь можно добавить дополнительные привязки с Combine
    }
    
    @objc private func startSimulationTapped() {
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


