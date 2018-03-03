//
//  PlaylistMusicIndicatorContentView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 03.03.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//  Based on Aufree's ESTMusicIndicator (https://github.com/Aufree/ESTMusicIndicator)
//

import UIKit

class PlaylistMusicIndicatorContentView: UIView {
    
    private let kBarCount = 3
    private let kBarWidth: CGFloat = 3.0
    private let kBarIdleHeight: CGFloat = 3.0
    private let kHorizontalBarSpacing: CGFloat = 2.0 // Measured on iPad 2 (non-Retina)
    private let kRetinaHorizontalBarSpacing: CGFloat = 1.5 // Measured on iPhone 5s (Retina)
    private let kBarMinPeakHeight: CGFloat = 6.0
    private let kBarMaxPeakHeight: CGFloat = 12.0
    private let kMinBaseOscillationPeriod = CFTimeInterval(0.6)
    private let kMaxBaseOscillationPeriod = CFTimeInterval(0.8)
    private let kOscillationAnimationKey: String = "oscillation"
    private let kDecayDuration = CFTimeInterval(0.3)
    private let kDecayAnimationKey: String = "decay"
    
    var barLayers = [CALayer]()
    var hasInstalledConstraints: Bool = false
    
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        prepareBarLayers()
        tintColorDidChange()
        setNeedsUpdateConstraints()
    }
    
    convenience init() { self.init(frame:CGRect.zero) }
    
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }
    
    private func prepareBarLayers() {
        
        var xOffset:CGFloat = 0.0
        
        for index in 1...kBarCount {
            let newLayer = createBarLayerWithXOffset(xOffset, layerIndex: index)
            barLayers.append(newLayer)
            layer.addSublayer(newLayer)
            xOffset = newLayer.frame.maxX + horizontalBarSpacing()
        }
    }
    
    private func createBarLayerWithXOffset(_ xOffset: CGFloat, layerIndex: Int) -> CALayer {
        
        let layer: CALayer = CALayer()
        
        layer.anchorPoint = CGPoint(x: 0.0, y: 1.0)
        layer.position = CGPoint(x: xOffset, y: kBarMaxPeakHeight)
        layer.bounds = CGRect(x: 0.0, y: 0.0, width: kBarWidth, height: (CGFloat(layerIndex) * kBarMaxPeakHeight/CGFloat(kBarCount)))
        
        return layer
    }
    
    private func horizontalBarSpacing() -> CGFloat {
        
        if UIScreen.main.scale == 2.0 {
            return kRetinaHorizontalBarSpacing
        }
        
        return kHorizontalBarSpacing
    }
    
    override func tintColorDidChange() {
        
        for layer in barLayers{
            layer.backgroundColor = tintColor.cgColor
        }
    }
    
    override var intrinsicContentSize : CGSize {
        
        var unionFrame:CGRect = CGRect.zero
        
        for layer in barLayers {
            unionFrame = unionFrame.union(layer.frame)
        }
        
        return unionFrame.size
    }
    
    override func updateConstraints() {
        
        if !hasInstalledConstraints {
            let size = intrinsicContentSize
            addConstraint(NSLayoutConstraint(
                 item: self,
                 attribute: .width,
                 relatedBy: .equal,
                 toItem: nil,
                 attribute: .notAnAttribute,
                 multiplier: 0.0,
                 constant: size.width)
            )

            addConstraint(NSLayoutConstraint(
                 item: self,
                 attribute: .height,
                 relatedBy: .equal,
                 toItem: nil,
                 attribute: .notAnAttribute,
                 multiplier: 0.0,
                 constant: size.height)
            )
            
            hasInstalledConstraints = true
        }
        
        super.updateConstraints()
    }
    
    func startOscillation() {
        
        let basePeriod = kMinBaseOscillationPeriod + (drand48() * (kMaxBaseOscillationPeriod - kMinBaseOscillationPeriod))
        
        for layer in barLayers {
            startOscillatingBarLayer(layer, basePeriod: basePeriod)
        }
    }
    
    func stopOscillation() {
        
        for layer in barLayers {
            layer.removeAnimation(forKey: kOscillationAnimationKey)
        }
    }
    
    func isOscillating() -> Bool {
        
        if let _ = barLayers.first?.animation(forKey: kOscillationAnimationKey) {
            return true
        }
        
        return false
    }
    
    func startDecay() {
        
        for layer in barLayers {
            startDecayingBarLayer(layer)
        }
    }
    
    func stopDecay() {
        
        for layer in barLayers {
            layer.removeAnimation(forKey: kDecayAnimationKey)
        }
    }
    
    private func startOscillatingBarLayer(_ layer: CALayer, basePeriod: CFTimeInterval) {
        
        let peakHeight: CGFloat = kBarMinPeakHeight + CGFloat(arc4random_uniform(UInt32(kBarMaxPeakHeight - kBarMinPeakHeight + 1)))
        
        var fromBouns = layer.bounds
            fromBouns.size.height = kBarIdleHeight
        
        var toBounds: CGRect = layer.bounds
            toBounds.size.height = peakHeight
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "bounds")
            animation.fromValue = NSValue(cgRect:fromBouns)
            animation.toValue = NSValue(cgRect:toBounds)
            animation.repeatCount = Float.infinity
            animation.autoreverses = true
            animation.duration = TimeInterval((CGFloat(basePeriod) / 2) * (kBarMaxPeakHeight / peakHeight))
            animation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseIn)
        
        layer.add(animation, forKey: kOscillationAnimationKey)
    }
    
    private func startDecayingBarLayer(_ layer: CALayer) {
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "bounds")
        
        if let presentation = layer.presentation() {
            animation.fromValue = NSValue(cgRect:CALayer(layer: presentation).bounds)
        };  animation.toValue = NSValue(cgRect:layer.bounds)
            animation.duration = kDecayDuration
            animation.timingFunction = CAMediaTimingFunction.init(name: kCAMediaTimingFunctionEaseOut)
        
        layer.add(animation, forKey: kDecayAnimationKey)
    }
}
