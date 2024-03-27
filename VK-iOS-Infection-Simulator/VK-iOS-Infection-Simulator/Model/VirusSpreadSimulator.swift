//
//  VirusSpreadSimulator.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 23.03.2024.
//
import Foundation
import Combine

struct Person {
    var id: UUID = UUID()
    var isInfected: Bool = false
}

class VirusSpreadSimulator {
    @Published var people: [Person] = []
    
    private var infectionFactor: Int
    private var timer: Timer?
    private var frequency: TimeInterval = 1.0
    private var currentItemsPerRow: Int? // Хранение текущего значения
    
    init(groupSize: Int, infectionFactor: Int) {
        self.infectionFactor = infectionFactor
        self.people = (0..<groupSize).map { _ in Person(isInfected: false) }
    }

    
    func startSimulation(frequency: TimeInterval) {
        self.frequency = frequency
        print("Симуляция началась с частотой \(frequency) и фактором \(infectionFactor)")
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: frequency, repeats: true) { [weak self] _ in
            // Проверяем, что значение itemsPerRow уже установлено
            guard let self = self, let itemsPerRow = self.currentItemsPerRow else { return }
            self.spreadInfection()
        }
    }

    func spreadInfection() {
        guard let itemsPerRow = self.currentItemsPerRow else { return }
        var newInfections: [Int] = []

        for (index, person) in people.enumerated() {
            guard person.isInfected else { continue }
            
            let neighborsIndexes = getNeighborsIndex(for: index, in: itemsPerRow)
            let infectableNeighbors = neighborsIndexes.filter { !people[$0].isInfected }
            
            // Определение случайного количества соседей для заражения
            let infectionsLimit = min(infectionFactor, infectableNeighbors.count)
            if infectionsLimit > 0 {
                let randomInfectionsCount = Int.random(in: 1...infectionsLimit)
                for i in infectableNeighbors.shuffled().prefix(randomInfectionsCount) {
                    newInfections.append(i)
                }
            }
        }

        // Заражение новых людей
        for index in newInfections {
            people[index].isInfected = true
        }
    }

    
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
                if i == 0 && j == 0 { continue } // Пропускаем сам элемент
                
                let neighborRow = row + i
                let neighborColumn = column + j
                let inLastRow = neighborRow * itemsPerRow >= lastRowFirstIndex
                
                // Условие для проверки допустимости соседнего столбца
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





    func toggleInfectionStatus(for personID: UUID) {
        guard let index = people.firstIndex(where: { $0.id == personID }) else { return }
        if !people[index].isInfected {
            people[index].isInfected = true
            print("VirusSpreadSimulator знает о зараженном \(personID)")

            // Используем сохранённое значение частоты для запуска симуляции
            if timer == nil {
                startSimulation(frequency: frequency)
            }
        }
    }


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
    
    func updateLayout(itemsPerRow: Int) {
        print("Кол-во элементов в строке: \(itemsPerRow)")
        self.currentItemsPerRow = itemsPerRow // Сохраняем текущее значение
    }

    
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
    }

}


