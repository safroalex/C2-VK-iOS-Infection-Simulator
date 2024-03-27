//
//  VirusSpreadViewModel.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//
import Foundation
import Combine

class VirusSpreadViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var isSimulationRunning: Bool = false
    @Published var itemsPerRow: Int = 0 // Добавлено для отслеживания количества элементов в строке
    
    private var simulator: VirusSpreadSimulator?
    private var subscriptions = Set<AnyCancellable>()
    private var frequency: TimeInterval = 1.0 // Значение по умолчанию
    var personStatusChanged = PassthroughSubject<UUID, Never>()
    var statisticsUpdated = PassthroughSubject<(healthyCount: Int, infectedCount: Int), Never>()
    
    func setupSimulation(groupSize: Int, infectionFactor: Int, frequency: TimeInterval) {
        self.frequency = frequency // Сохраняем значение частоты
        simulator = VirusSpreadSimulator(groupSize: groupSize, infectionFactor: infectionFactor)
        simulator?.$people
            .receive(on: RunLoop.main)
            .assign(to: &$people)
        
        // Внутри VirusSpreadViewModel после инициализации simulator
        $itemsPerRow
            .sink { [weak self] itemsPerRow in
                self?.simulator?.updateLayout(itemsPerRow: itemsPerRow)
            }
            .store(in: &subscriptions)

    }
    
    
    func startSimulation() {
        print("Симуляция началась в VirusSpreadViewModel")
        guard let simulator = simulator, !isSimulationRunning else { return }
        isSimulationRunning = true
        simulator.startSimulation(frequency: frequency) // Запуск симуляции с сохраненной частотой
        
        // Запуск таймера для регулярного обновления статистики
        Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            self?.updateStatistics()
        }
    }
    
    func stopSimulation() {
        // Остановить таймер и симуляцию здесь
        simulator?.stopSimulation() // Это предполагает, что у вас есть метод stopSimulation в VirusSpreadSimulator
        isSimulationRunning = false
    }    
    
    func toggleInfectionStatus(for personID: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            // Поиск индекса зараженного человека в ViewModel
            if let index = self.people.firstIndex(where: { $0.id == personID }) {
                // Заражаем только если человек был здоров
                if !self.people[index].isInfected {
                    print("Infecting person at index: \(index), personID: \(personID)")
                    self.people[index].isInfected = true
                    
                    // Отправляем информацию о заражении в Simulator
                    DispatchQueue.main.async {
                        self.simulator?.toggleInfectionStatus(for: personID)
                        print("VirusSpreadViewModel знает о зараженном \(personID)")
                    }
                }
            }
        }
    }

    
    func updateStatistics() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let healthyCount = self.people.filter { !$0.isInfected }.count
            let infectedCount = self.people.count - healthyCount
            
            DispatchQueue.main.async {
                // Отправляем обновленную статистику в главный поток
                self.statisticsUpdated.send((healthyCount, infectedCount))
            }
        }
    }
    
    func updateItemsPerRow(_ count: Int) {
        itemsPerRow = count // Обновляем и выводим в консоль количество элементов в строке
        print("Обновлено количество элементов в строке: \(count)")
    }
}
