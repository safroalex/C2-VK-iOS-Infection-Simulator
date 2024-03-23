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
        self.people = Array(repeating: Person(isInfected: false), count: groupSize)
    }
    
    func startSimulation(frequency: TimeInterval) {
        // Здесь должна быть логика симуляции
    }
    
    func toggleInfectionStatus(for personID: UUID) {
        guard let index = people.firstIndex(where: { $0.id == personID }) else { return }
        people[index].isInfected.toggle()
    }
}


