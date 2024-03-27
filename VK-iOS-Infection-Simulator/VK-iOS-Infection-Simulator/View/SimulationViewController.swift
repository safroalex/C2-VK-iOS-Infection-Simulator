//
//  SimulationViewController.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//

import UIKit
import Combine

class SimulationViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    private var viewModel: VirusSpreadViewModel!
    private var subscriptions = Set<AnyCancellable>()
    private var labelsStackView: UIStackView!
    private var collectionView: UICollectionView!
    private let healthyLabel = UILabel()
    private let infectedLabel = UILabel()
    private let stopSimulationButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        setupBindings()
    }
    
    
    
    private func setupLayout() {
        view.backgroundColor = .systemBackground // Для наглядности
        
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 25, height: 25) // Меньший размер ячейки
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)

        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight] // Автоподгонка размера
        collectionView.backgroundColor = .systemBackground
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Регистрация класса ячейки
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        
        view.addSubview(collectionView)
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeSelection(_:)))
        panGesture.maximumNumberOfTouches = 1 // Максимальное количество касаний
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
            // Здоровые слева
            healthyLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            healthyLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),

            // Зараженные справа
            infectedLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            infectedLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
        ])

        
        // Начальные значения
        healthyLabel.text = "Здоровых: 0"
        infectedLabel.text = "Зараженных: 0"

    }
    
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
                // Находим индекс измененного Person в массиве people ViewModel, а не Simulator
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
                // Обновление лейблов с количеством здоровых и больных
                self?.updateLabels(healthyCount: healthyCount, infectedCount: infectedCount)
            }
            .store(in: &subscriptions)
    }

    
    func configure(with viewModel: VirusSpreadViewModel) {
        self.viewModel = viewModel
    }
    
    @objc private func stopSimulationTapped() {
        stopSimulation()
        navigationController?.popViewController(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.people.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let personID = viewModel.people[indexPath.row].id
        print("Did select item at \(indexPath), personID: \(personID)")
        viewModel.toggleInfectionStatus(for: personID)
    }



    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        cell.layer.cornerRadius = 10
        cell.layer.masksToBounds = true
        cell.backgroundColor = viewModel.people[indexPath.item].isInfected ? .red : .green // Пример визуализации
        return cell
    }
    

    
    @objc private func handleSwipeSelection(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: collectionView)
        
        switch gesture.state {
        case .began, .changed:
            guard let indexPath = collectionView.indexPathForItem(at: location),
                let cell = collectionView.cellForItem(at: indexPath) else { return }

            
            // Изменение состояния выбранной ячейки, если это необходимо
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
    
    func updateLabels(healthyCount: Int, infectedCount: Int) {
        healthyLabel.text = "Здоровых: \(healthyCount)"
        infectedLabel.text = "Зараженных: \(infectedCount)"
    }

    func recalculateItemsPerRow() {
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }
        let totalWidth = collectionView.bounds.size.width
        let itemWidth = layout.itemSize.width
        let spacing = layout.minimumInteritemSpacing

        // Для более точного расчёта учитываем отступы слева и справа
        let insets = layout.sectionInset.left + layout.sectionInset.right

        // Вычисляем количество элементов в строке
        let itemsPerRow = Int((totalWidth - insets + spacing) / (itemWidth + spacing))

        // Выводим результат в консоль для дебага
        print("Количество элементов в строке: \(itemsPerRow)")
        viewModel.updateItemsPerRow(itemsPerRow) // Сообщаем ViewModel об изменении
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        recalculateItemsPerRow()
    }

    func stopSimulation() {
        viewModel.stopSimulation()
    }
    
    private func styleLabel(_ label: UILabel) {
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8) // Прозрачность фона
        label.textColor = .white
        label.textAlignment = .center
        label.layer.cornerRadius = 10 // Скругление углов
        label.layer.masksToBounds = true
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium) // Шрифт покрупнее
        // Установка фиксированных размеров для меток
        label.widthAnchor.constraint(equalToConstant: 120).isActive = true
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
    }



}


