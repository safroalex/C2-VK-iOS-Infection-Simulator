//
//  VirusSpreadSimulator.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//
import Foundation
import Combine

/// Структура, представляющая персону в симуляции распространения вируса.
struct Person {
    var id: UUID = UUID()
    var isInfected: Bool = false
}

/// Класс для симуляции распространения вируса среди группы людей.
class VirusSpreadSimulator {
    @Published var people: [Person] = []

    private var infectionFactor: Int
    private var timer: Timer?
    private var frequency: TimeInterval = 1.0
    private var currentItemsPerRow: Int?
    
    /// Инициализатор симулятора.
    /// - Parameters:
    ///   - groupSize: Размер группы людей.
    ///   - infectionFactor: Фактор заражения, определяющий вероятность заражения.
    init(groupSize: Int, infectionFactor: Int) {
        self.infectionFactor = infectionFactor
        self.people = (0..<groupSize).map { _ in Person(isInfected: false) }
    }

    // MARK: - Симуляция
    
    /// Запускает симуляцию распространения вируса.
    /// - Parameter frequency: Частота обновления состояния симуляции.
    func startSimulation(frequency: TimeInterval) {
        self.frequency = frequency
        print("Симуляция началась с частотой \(frequency) и фактором инфекции \(infectionFactor).")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            self?.spreadInfection()
        }
    }

    /// Распространяет инфекцию среди людей, основываясь на текущем факторе заражения.
    func spreadInfection() {
        guard let itemsPerRow = self.currentItemsPerRow else { return }
        var newInfections: [Int] = []

        for (index, person) in people.enumerated() {
            guard person.isInfected else { continue }
            
            let neighborsIndexes = getNeighborsIndex(for: index, in: itemsPerRow)
            let infectableNeighbors = neighborsIndexes.filter { !people[$0].isInfected }
            
            let infectionsLimit = min(infectionFactor, infectableNeighbors.count)
            if infectionsLimit > 0 {
                let randomInfectionsCount = Int.random(in: 1...infectionsLimit)
                for i in infectableNeighbors.shuffled().prefix(randomInfectionsCount) {
                    newInfections.append(i)
                }
            }
        }

        for index in newInfections {
            people[index].isInfected = true
        }
    }

    /// Возвращает индексы соседей для данного элемента.
    /// - Parameters:
    ///   - index: Индекс элемента.
    ///   - itemsPerRow: Количество элементов в строке.
    /// - Returns: Массив индексов соседних элементов.
    private func getNeighborsIndex(for index: Int, in itemsPerRow: Int) -> [Int] {
        let totalItems = people.count
        let row = index / itemsPerRow
        let column = index % itemsPerRow
        let lastRowFirstIndex = totalItems - (totalItems % itemsPerRow)
        let isLastRow = index >= lastRowFirstIndex
        let itemsInLastRow = totalItems % itemsPerRow
        
        var neighbors: [Int] = []
        for i in -1...1 {
            for j in -1...1 {
                if i == 0 && j == 0 { continue }
                
                let neighborRow = row + i
                let neighborColumn = column + j
                let inLastRow = neighborRow * itemsPerRow >= lastRowFirstIndex
                
                let columnCondition = inLastRow ? neighborColumn >= 0 && neighborColumn < itemsInLastRow : neighborColumn >= 0 && neighborColumn < itemsPerRow
                
                if neighborRow >= 0 && neighborRow <= (totalItems / itemsPerRow) &&
                    columnCondition {
                    let neighborIndex = neighborRow * itemsPerRow + neighborColumn
                    if neighborIndex >= 0 && neighborIndex < totalItems {
                        neighbors.append(neighborIndex)
                    }
                }
            }
        }
        return neighbors
    }
    
    // MARK: - Управление статусом заражения
    
    /// Переключает статус заражения для указанного человека.
    /// - Parameter personID: Идентификатор персоны.
    func toggleInfectionStatus(for personID: UUID) {
        guard let index = people.firstIndex(where: { $0.id == personID }) else { return }
        if !people[index].isInfected {
            people[index].isInfected = true
            print("VirusSpreadSimulator знает о зараженном \(personID)")

            if timer == nil {
                startSimulation(frequency: frequency)
            }
        }
    }

    // MARK: - Статистика и обновления
    
    /// Вычисляет статистику зараженных и здоровых людей.
    /// - Parameter completion: Блок выполнения, возвращающий количество здоровых и зараженных.
    func calculateStatistics(completion: @escaping (_ healthyCount: Int, _ infectedCount: Int) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let infectedCount = self.people.filter { $0.isInfected }.count
            let healthyCount = self.people.count - infectedCount
            
            DispatchQueue.main.async {
                completion(healthyCount, infectedCount)
            }
        }
    }
    
    /// Обновляет раскладку, устанавливая количество элементов в строке.
    /// - Parameter itemsPerRow: Количество элементов в строке.
    func updateLayout(itemsPerRow: Int) {
        print("Кол-во элементов в строке: \(itemsPerRow)")
        self.currentItemsPerRow = itemsPerRow
    }

    // MARK: - Управление симуляцией
    
    /// Останавливает симуляцию распространения вируса.
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }

}
