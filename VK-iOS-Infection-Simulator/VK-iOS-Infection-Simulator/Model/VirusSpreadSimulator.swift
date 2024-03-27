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
        print("Метод вызван")
        var newInfections: [Int] = []
        for (index, person) in people.enumerated() {
            guard person.isInfected else { continue }

            // Попытка заразить предыдущего человека в массиве, если он существует и не заражен
            if index > 0 && !people[index - 1].isInfected {
                newInfections.append(index - 1)
                print("Заражен человек на позиции \(index - 1) от человека на позиции \(index)")
            }

            // Попытка заразить следующего человека в массиве, если он существует и не заражен
            if index < people.count - 1 && !people[index + 1].isInfected {
                newInfections.append(index + 1)
                print("Заражен человек на позиции \(index + 1) от человека на позиции \(index)")
            }
        }

        // Заражаем новых людей
        for index in newInfections {
            people[index].isInfected = true
            print("Человек на позиции \(index) теперь заражен.")
        }

        // После обновления статусов заражения можно вызвать calculateStatistics или другой метод для обновления UI
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
        // Немедленное использование нового значения для расчёта заражений
//        spreadInfection(itemsPerRow: itemsPerRow)
    }

    
    func stopSimulation() {
        timer?.invalidate()
        timer = nil
        // Любые дополнительные действия по остановке симуляции
    }

}


