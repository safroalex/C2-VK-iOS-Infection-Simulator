//
//  SimulationViewController.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//

import UIKit
import Combine

/// Контроллер, отображающий визуализацию симуляции распространения вируса.
class SimulationViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    // MARK: - Private Properties
    private var viewModel: VirusSpreadViewModel!
    private var subscriptions = Set<AnyCancellable>()
    private var labelsStackView: UIStackView!
    private var collectionView: UICollectionView!
    private let healthyLabel = UILabel()
    private let infectedLabel = UILabel()
    private let stopSimulationButton = UIButton(type: .system)
    
    // MARK: - Lifecycle Methods
    
    /// Вызывается после загрузки представления контроллера.
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupBindings()
    }
    
    // MARK: - Setup Methods
    
    /// Настраивает макет и внешний вид элементов управления на экране.
    private func setupLayout() {
        view.backgroundColor = .systemBackground
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 25, height: 25)
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        view.addSubview(collectionView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeSelection(_:)))
        panGesture.maximumNumberOfTouches = 1
        collectionView.addGestureRecognizer(panGesture)
        
        navigationItem.hidesBackButton = true

        healthyLabel.translatesAutoresizingMaskIntoConstraints = false
        infectedLabel.translatesAutoresizingMaskIntoConstraints = false
        
        stopSimulationButton.setTitle("Стоп", for: .normal)
        stopSimulationButton.backgroundColor = .systemRed
        stopSimulationButton.setTitleColor(.white, for: .normal)
        stopSimulationButton.layer.cornerRadius = 10
        stopSimulationButton.translatesAutoresizingMaskIntoConstraints = false
        stopSimulationButton.addTarget(self, action: #selector(stopSimulationTapped), for: .touchUpInside)
       
        styleLabel(healthyLabel)
        styleLabel(infectedLabel)
        
        view.addSubview(stopSimulationButton)
        view.addSubview(healthyLabel)
        view.addSubview(infectedLabel)
        
        labelsStackView = UIStackView(arrangedSubviews: [healthyLabel, infectedLabel])
        labelsStackView.axis = .horizontal
        labelsStackView.distribution = .fillEqually
        labelsStackView.spacing = 10
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(labelsStackView)
        
        
        NSLayoutConstraint.activate([
            stopSimulationButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopSimulationButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopSimulationButton.widthAnchor.constraint(equalToConstant: 200),
            stopSimulationButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        NSLayoutConstraint.activate([
            healthyLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            healthyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            infectedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infectedLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])

        healthyLabel.text = "Здоровых: 0"
        infectedLabel.text = "Зараженных: 0"
    }
    
    /// Устанавливает привязки между элементами управления и моделью представления.
    private func setupBindings() {
        viewModel.$people
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.collectionView.reloadData()
            }
            .store(in: &subscriptions)

        viewModel.personStatusChanged
            .sink { [weak self] personID in
                guard let self = self else { return }
                if let index = self.viewModel.people.firstIndex(where: { $0.id == personID }) {
                    let indexPathToUpdate = IndexPath(item: index, section: 0)
                    print("Correcting indexPath to: \(indexPathToUpdate) for personID: \(personID)")
                    self.collectionView.reloadItems(at: [indexPathToUpdate])
                }
            }
            .store(in: &subscriptions)
        
        viewModel.statisticsUpdated
            .receive(on: RunLoop.main)
            .sink { [weak self] healthyCount, infectedCount in
                self?.updateLabels(healthyCount: healthyCount, infectedCount: infectedCount)
            }
            .store(in: &subscriptions)
    }

    // MARK: - Configuration
    
    /// Конфигурирует контроллер с помощью модели представления.
    /// - Parameter viewModel: Модель представления для конфигурации.
    func configure(with viewModel: VirusSpreadViewModel) {
        self.viewModel = viewModel
    }
    
    // MARK: - Actions
    
    /// Обработчик нажатия кнопки "Стоп", останавливающий симуляцию и возвращающий пользователя.
    @objc private func stopSimulationTapped() {
        stopSimulation()
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - UICollectionViewDataSource
    
    /// Возвращает количество элементов в секции коллекции.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.people.count
    }
    
    /// Конфигурирует и возвращает ячейку коллекции для указанного индекса пути.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let personID = viewModel.people[indexPath.row].id
        print("Did select item at \(indexPath), personID: \(personID)")
        viewModel.toggleInfectionStatus(for: personID)
    }

    // MARK: - UICollectionViewDelegate
    
    /// Вызывается при выборе элемента в коллекции.
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        cell.backgroundColor = viewModel.people[indexPath.item].isInfected ? .red : .green
        return cell
    }
    
    // MARK: - Gesture Handling
    
    /// Обрабатывает жесты панорамирования для выбора ячеек во время движения.
    @objc private func handleSwipeSelection(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        
        switch gesture.state {
        case .began, .changed:
            guard let indexPath = collectionView.indexPathForItem(at: location),
            let cell = collectionView.cellForItem(at: indexPath) else { return }

            let personID = viewModel.people[indexPath.row].id
            if !viewModel.people[indexPath.row].isInfected {
                viewModel.toggleInfectionStatus(for: personID)
            }
            
        default:
            break
        }
    }

    func updateCollectionView(forModifiedIndexPath indexPath: IndexPath) {
        collectionView.reloadItems(at: [indexPath])
    }
    
    // MARK: - UI Updates
    
    /// Обновляет метки статистики здоровых и зараженных.
    func updateLabels(healthyCount: Int, infectedCount: Int) {
        healthyLabel.text = "Здоровых: \(healthyCount)"
        infectedLabel.text = "Зараженных: \(infectedCount)"
    }
    
    /// Вычисляет и обновляет количество элементов в строке для корректного отображения коллекции.
    func recalculateItemsPerRow() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let totalWidth = collectionView.bounds.size.width
        let itemWidth = layout.itemSize.width
        let spacing = layout.minimumInteritemSpacing

        let insets = layout.sectionInset.left + layout.sectionInset.right

        let itemsPerRow = Int((totalWidth - insets + spacing) / (itemWidth + spacing))

        print("Количество элементов в строке: \(itemsPerRow)")
        viewModel.updateItemsPerRow(itemsPerRow)
    }

    /// Вызывается перед настройкой подмножеств представлений.
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        recalculateItemsPerRow()
    }

    /// Останавливает симуляцию и выполняет необходимую очистку.
    func stopSimulation() {
        viewModel.stopSimulation()
    }
    
    /// Настраивает стиль метки для отображения статистики.
    private func styleLabel(_ label: UILabel) {
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.layer.masksToBounds = true
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.widthAnchor.constraint(equalToConstant: 120).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }
}
