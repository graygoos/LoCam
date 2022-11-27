//
//  LCButton.swift
//  LoCam
//
//  Created by Femi Aliu on 20/09/2022.
//

import UIKit

class LCButton: UIButton {
    
    let photoButton = UIButton()
    let videoButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configurePhotoButton()
        configureVideoButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init(buttonType: UIButton) {
        super.init(frame: .zero)
        configurePhotoButton()
        configureVideoButton()
    }
    
    private func configurePhotoButton() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular, scale: .large)
        let photoButton = UIImage(systemName: "square", withConfiguration: largeConfig)
        photoButton?.withTintColor(.white)
    }
    
    private func configureVideoButton() {
        translatesAutoresizingMaskIntoConstraints = false
        
        var largeConfig = UIImage.SymbolConfiguration(pointSize: 120, weight: .regular, scale: .large)
        largeConfig = largeConfig.applying(UIImage.SymbolConfiguration(paletteColors: [UIColor.systemRed, UIColor.white]))
//        let videoButton = UIImage(systemName: "square.inset.filled", withConfiguration: largeConfig)
    }
    
//    func set(buttonImage: UIImage) {
//        
//    }
}
