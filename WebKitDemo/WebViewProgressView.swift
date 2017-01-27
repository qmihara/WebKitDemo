//
//  WebViewProgressView.swift
//  WebKitDemo
//
//  porting NJKWebViewProgress to Swift.
//  see also https://github.com/ninjinkun/NJKWebViewProgress
//
//  Created by Kyusaku Mihara on 9/17/14.
//  Copyright (c) 2014 epohsoft. All rights reserved.
//

import UIKit

public class WebViewProgressView: UIView {

    public var barAnimationDuration = 0.27
    public var fadeAnimationDuration = 0.27
    public var fadeOutDelay = 0.1
    public var progress: Float {
        get {
            return self._progress
        }
        set {
            self.setProgress(newValue, animated: false)
        }
    }

    private var progressView = UIView()
    private var _progress: Float = 0.0

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureViews()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.configureViews()
    }

    public func setProgress(progress: Float, animated: Bool) {
        self._progress = progress
        let isGrowing = progress > 0.0
        UIView.animateWithDuration(
            (isGrowing && animated) ? self.barAnimationDuration: 0.0,
            delay: 0,
            options: UIViewAnimationOptions.CurveEaseInOut,
            animations: {
                self.progressView.frame.size.width = CGFloat(progress) * self.bounds.size.width
            },
            completion: nil
        )

        if progress >= 1.0 {
            UIView.animateWithDuration(
                animated ? self.barAnimationDuration : 0.0,
                delay: self.fadeOutDelay,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: {
                    self.progressView.alpha = 0.0
                }, completion: { completed in
                    self.progressView.frame.size.width = 0.0
                }
            )
        } else {
            UIView.animateWithDuration(
                animated ? self.barAnimationDuration : 0.0,
                delay: self.fadeOutDelay,
                options: UIViewAnimationOptions.CurveEaseInOut,
                animations: {
                    self.progressView.alpha = 1.0
                },
                completion: nil
            )
        }
    }

    private func configureViews() {
        self.userInteractionEnabled = false;
        self.autoresizingMask = .FlexibleWidth

        self.progressView.frame = self.bounds
        self.progressView.frame.size.width = 0
        self.progressView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
        self.progressView.backgroundColor = self.tintColor
        self.addSubview(self.progressView)

        self.barAnimationDuration = 0.27
        self.fadeAnimationDuration = 0.27
        self.fadeOutDelay = 0.1
    }
}
