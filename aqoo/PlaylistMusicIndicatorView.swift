//
//  PlaylistMusicIndicatorView.swift
//  aqoo
//
//  Created by Patrick Paechnatz on 03.03.18.
//  Copyright © 2018 Patrick Paechnatz. All rights reserved.
//  Based on Aufree's ESTMusicIndicator (https://github.com/Aufree/ESTMusicIndicator)
//

import UIKit

public enum PlaylistMusicIndicatorViewState: Int {
    
    case stopped
    case playing
    case paused
}

public enum PlaylistMusicPlayMode: Int {
    
    case playNormal
    case playShuffle
    case playLoop
    case clear
}

open class PlaylistMusicIndicatorView: UIView {

    open var hidesWhenStopped: Bool = true {
        
        didSet {
            
            if  state == .stopped {
                isHidden = hidesWhenStopped
            }
        }
    }
    
    public var state: PlaylistMusicIndicatorViewState = .stopped {
        
        didSet {
            
            if  state == .stopped {
                stopAnimating()
                if  hidesWhenStopped {
                    isHidden = true
                }
                
            } else {
                
                stopAnimating()
                if  state == .playing {
                    startAnimating()
                }
                
                isHidden = false
            }
        }
    }
    
    private var hasInstalledConstraints: Bool = false
    private var contentView: PlaylistMusicIndicatorContentView!
    
    override public init(frame: CGRect) {
        
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        
        layer.masksToBounds = true
        contentView = PlaylistMusicIndicatorContentView.init()
        addSubview(contentView)
        
        prepareLayoutPriorities()
        setNeedsUpdateConstraints()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationDidEnterBackground(_:)),
            name: NSNotification.Name.UIApplicationDidEnterBackground,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(UIApplicationDelegate.applicationWillEnterForeground(_:)),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil
        )
    }
    
    private func prepareLayoutPriorities() {
        
        setContentHuggingPriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.horizontal)
        setContentHuggingPriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
        
        setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.horizontal)
        setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: UILayoutConstraintAxis.vertical)
    }
    
    deinit { NotificationCenter.default.removeObserver(self) }
    
    override open var intrinsicContentSize : CGSize {
        return contentView.intrinsicContentSize
    }
    
    override open func updateConstraints() {
        
        if !hasInstalledConstraints {
            addConstraint(NSLayoutConstraint(
                 item: self,
                 attribute: .centerX,
                 relatedBy: .equal,
                 toItem: contentView,
                 attribute: .centerX,
                 multiplier: 1.0,
                 constant: 0.0)
            )
            
            addConstraint(NSLayoutConstraint(
                 item: self,
                 attribute: .centerY,
                 relatedBy: .equal,
                 toItem: contentView,
                 attribute: .centerY,
                 multiplier: 1.0,
                 constant: 0.0)
            )
            
            hasInstalledConstraints = true
        }
        
        super.updateConstraints()
    }
    
    override open func forBaselineLayout() -> UIView {
        
        return contentView
    }

    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        
        return intrinsicContentSize
    }
    
    private func startAnimating() {
        
        if contentView.isOscillating() { return }
        
        contentView.stopDecay()
        contentView.startOscillation()
    }
    
    private func stopAnimating() {
        
        if !contentView.isOscillating() { return }
        
        contentView.stopOscillation()
        contentView.startDecay()
    }
    
    @objc
    private func applicationDidEnterBackground(_ notification: Notification) {
        
        stopAnimating()
    }
    
    @objc
    private func applicationWillEnterForeground(_ notification: Notification) {
        
        if state == .playing { startAnimating() }
    }
}
