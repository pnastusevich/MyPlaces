//
//  RatingControl.swift
//  MyPlaces
//
//  Created by Паша Настусевич on 23.04.24.
//

import UIKit

@IBDesignable class RatingControl: UIStackView {
    
    //MARK: Properties
    
    var rating = 0 {
        didSet {
            updateButtonSelectionState()
        }
    }
    
    private var ratingButtons = [UIButton]()
    
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0) {
        didSet {
            setupButtons()
        }
    }
    @IBInspectable var starCount: Int = 5 {
        didSet {
            setupButtons()
        }
    }

    //MARK: Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    
    // MARK: Button Action
    
    @objc func retingButtonTapped(button: UIButton) {
       
        guard let index = ratingButtons.firstIndex(of: button) else { return } // находим индекс кнопки "firstIndex(of:" возвращает индекс первого выброного элемента
        
        // Calculate the rating of the selected button
        let selectedRating = index + 1
        
        if selectedRating == rating { // если текущий рейтинг звезды равен выбранной звезде, то рейтинг обнулится
            rating = 0
        } else {
            rating = selectedRating
        }
        
        
    }
    
    // MARK: Private Methods
    
    private func setupButtons() {
        
        for button in ratingButtons { // перед тем как создать новые кнопки рейтинга очищаем все старые кнопки
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        
        // Load button image
        let bundle = Bundle(for: type(of: self))
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        for _ in 0..<starCount {
            
            // Create button
            let button = UIButton()
            
            // Set the button image (Присваиваем имдж кнопке в зависимоти от состояния)
            
            button.setImage(emptyStar, for: .normal)
            button.setImage(filledStar, for: .selected) // состояние можно поставить только програмно
            button.setImage(highlightedStar, for: .highlighted) // срабатывает при прикосновении
            button.setImage(highlightedStar, for: [.highlighted, .selected]) // если звезда выделена и мы к ней прикасаемся, то она подсвечивается синим цветом
            
                        
            // add constraints
            button.translatesAutoresizingMaskIntoConstraints = false // отключает автоматические констрейнты для кнопки
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true // высота констрейнтов
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true // ширина констрейнтов
            
            // setup the button action
            button.addTarget(self, action: #selector(retingButtonTapped(button:)), for: .touchUpInside)
            
            // add the button to the stack
            addArrangedSubview(button)
            
            // add the new button on the rating button array
            ratingButtons.append(button)
        }
        updateButtonSelectionState() // вызываем для отображения текущего состояния рейтинга
    }
    
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() { // enumerated() возвращает индекс букв в цифрах
            button.isSelected = index < rating // если индекс кнопки меньше рейтинга то свойсву isSelected будет присваиваться значение true и звезда будет заполненая. Так как это цикл, то заполнение будет по всем звёздам чей индекс меньше рейтинга
        }
    }
}
