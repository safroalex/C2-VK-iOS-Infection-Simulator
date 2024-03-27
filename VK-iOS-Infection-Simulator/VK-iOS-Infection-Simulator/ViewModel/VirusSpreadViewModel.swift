//
//  VirusSpreadViewModel.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//
import Foundation
import Combine

/// Модель представления для управления симуляцией распространения вируса.
class VirusSpreadViewModel: ObservableObject {
    @Published var people: [Person] = []
    @Published var isSimulationRunning: Bool = false
    @Published var itemsPerRow: Int = 0

    private var simulator: VirusSpreadSimulator?
    private var subscriptions = Set<AnyCancellable>()
    private var frequency: TimeInterval = 1.0

    /// Публикует изменения статуса заражения конкретного человека.
    var personStatusChanged = PassthroughSubject<UUID, Never>()

    /// Публикует обновленную статистику здоровых и зараженных людей.
    var statisticsUpdated = PassthroughSubject<(healthyCount: Int, infectedCount: Int), Never>()
    
    /// Настраивает параметры симуляции.
    /// - Parameters:
    ///   - groupSize: Размер группы людей.
    ///   - infectionFactor: Фактор заражения.
    ///   - frequency: Частота обновления симуляции.
    func setupSimulation(groupSize: Int, infectionFactor: Int, frequency: TimeInterval) {
        self.frequency = frequency
        simulator = VirusSpreadSimulator(groupSize: groupSize, infectionFactor: infectionFactor)
        
        // Привязка массива людей к модели представления.
        simulator?.$people
            .receive(on: RunLoop.main)
            .assign(to: &$people)
        
        // Обновление макета в зависимости от количества элементов в строке.
        $itemsPerRow
            .sink { [weak self] itemsPerRow in
                self?.simulator?.updateLayout(itemsPerRow: itemsPerRow)
            }
            .store(in: &subscriptions)

    }
    
    /// Запускает симуляцию.
    func startSimulation() {
        print("Симуляция началась в VirusSpreadViewModel")
        guard let simulator = simulator, !isSimulationRunning else { return }
        isSimulationRunning = true
        simulator.startSimulation(frequency: frequency)
        
        // Регулярное обновление статистики.
        Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            self?.updateStatistics()
        }
    }
    
    /// Останавливает симуляцию.
    func stopSimulation() {
        simulator?.stopSimulation()
        isSimulationRunning = false
    }
    
    /// Переключает статус заражения для указанного человека.
    /// - Parameter personID: Идентификатор человека.
    func toggleInfectionStatus(for personID: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let index = self.people.firstIndex(where: { $0.id == personID }) {
                if !self.people[index].isInfected {
                    print("Infecting person at index: \(index), personID: \(personID)")
                    self.people[index].isInfected = true
                    
                    DispatchQueue.main.async {
                        self.simulator?.toggleInfectionStatus(for: personID)
                        print("VirusSpreadViewModel знает о зараженном \(personID)")
                    }
                }
            }
        }
    }

    /// Обновляет статистику здоровых и зараженных людей.
    func updateStatistics() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let healthyCount = self.people.filter { !$0.isInfected }.count
            let infectedCount = self.people.count - healthyCount
            
            DispatchQueue.main.async {
                self.statisticsUpdated.send((healthyCount, infectedCount))
            }
        }
    }
    
    /// Обновляет количество элементов в строке для макета коллекции.
    /// - Parameter count: Новое количество элементов в строке.
    func updateItemsPerRow(_ count: Int) {
        itemsPerRow = count
        print("Обновлено количество элементов в строке: \(count)")
    }
}
