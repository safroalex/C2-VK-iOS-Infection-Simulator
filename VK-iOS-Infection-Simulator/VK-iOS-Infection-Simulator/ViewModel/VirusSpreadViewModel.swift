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
    private var frequency: TimeInterval = 1.0 // Значение по умолчанию
    var personStatusChanged = PassthroughSubject<UUID, Never>()
    
    func setupSimulation(groupSize: Int, infectionFactor: Int, frequency: TimeInterval) {
        self.frequency = frequency // Сохраняем значение частоты
        simulator = VirusSpreadSimulator(groupSize: groupSize, infectionFactor: infectionFactor)
        simulator?.$people
            .receive(on: RunLoop.main)
            .assign(to: &$people)
    }
    
    
    func startSimulation() {
        guard let simulator = simulator, !isSimulationRunning else { return }
        isSimulationRunning = true
        simulator.startSimulation(frequency: frequency) // Используем сохранённое значение частоты
    }
    
    
    func toggleInfectionStatus(for personID: UUID) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let index = self.people.firstIndex(where: { $0.id == personID }), !self.people[index].isInfected {
                // Заражаем только если человек был здоров
                print("Infecting person at index: \(index), personID: \(personID)")
                self.people[index].isInfected = true
                
                DispatchQueue.main.async {
                    print("Sending personStatusChanged for personID: \(personID)")
                    self.personStatusChanged.send(personID)
                }
            }
        }
    }
}
