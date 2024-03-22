//
//  InputViewModel.swift
//  VK-iOS-Infection-Simulator
//
//  Created by Александр Сафронов on 22.03.2024.
//

import Combine

class InputViewModel {
    // Используем @Published для автоматической публикации изменений
    @Published var groupSize: String = ""
    @Published var infectionFactor: String = ""
    @Published var periodT: String = ""
    
    // PassthroughSubject используется для отправки события нажатия кнопки
    var simulateButtonTapped = PassthroughSubject<Void, Never>()
}
