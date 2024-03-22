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
    
    private var simulator: VirusSpreadSimulator?
    private var subscriptions = Set<AnyCancellable>()
    
    func setupSimulation(groupSize: Int, infectionFactor: Int, frequency: TimeInterval) {
        simulator = VirusSpreadSimulator(groupSize: groupSize, infectionFactor: infectionFactor)
        simulator?.$people
            .receive(on: RunLoop.main)
            .assign(to: &$people)
        
        // Пример подписки на изменение статуса симуляции
        // Это может быть полезно, если логика вашей симуляции подразумевает изменение этого статуса
    }
    
    func startSimulation() {
        guard let simulator = simulator, !isSimulationRunning else { return }
        isSimulationRunning = true
        simulator.startSimulation(frequency: 1.0) // Установите желаемую частоту обновления
        
        // Добавьте необходимую логику для остановки симуляции и обновления isSimulationRunning
    }
    
    func toggleInfectionStatus(for personID: UUID) {
        simulator?.toggleInfectionStatus(for: personID)
    }
}
