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
    
    init(groupSize: Int, infectionFactor: Int) {
        self.infectionFactor = infectionFactor
        self.people = (0..<groupSize).map { _ in Person(isInfected: false) }
    }

    
    func startSimulation(frequency: TimeInterval) {
        // Здесь должна быть логика симуляции
    }
    
    func toggleInfectionStatus(for personID: UUID) {
        guard let index = people.firstIndex(where: { $0.id == personID }) else { return }
        people[index].isInfected.toggle()
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

}


