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

class WebViewProgressView: UIView {

    var barAnimationDuration = 0.27
    var fadeAnimationDuration = 0.27
    var fadeOutDelay = 0.1
    var progress: Float {
        get {
            return _progress
        }
        set {
            setProgress(newValue, animated: false)
        }
    }

    private var progressView = UIView()
    private var _progress: Float = 0.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    func setProgress(_ progress: Float, animated: Bool) {
        _progress = progress
        let isGrowing = progress > 0.0
        UIView.animate(
            withDuration: (isGrowing && animated) ? barAnimationDuration: 0.0,
            delay: 0,
            options: UIViewAnimationOptions(),
            animations: {
                self.progressView.frame.size.width = CGFloat(progress) * self.bounds.size.width
            },
            completion: nil
        )

        if progress >= 1.0 {
            UIView.animate(
                withDuration: animated ? barAnimationDuration : 0.0,
                delay: fadeOutDelay,
                options: UIViewAnimationOptions(),
                animations: {
                    self.progressView.alpha = 0.0
                }, completion: { completed in
                    self.progressView.frame.size.width = 0.0
                }
            )
        } else {
            UIView.animate(
                withDuration: animated ? barAnimationDuration : 0.0,
                delay: fadeOutDelay,
                options: UIViewAnimationOptions(),
                animations: {
                    self.progressView.alpha = 1.0
                },
                completion: nil
            )
        }
    }

    private func configureViews() {
        isUserInteractionEnabled = false;
        autoresizingMask = .flexibleWidth

        progressView.frame = bounds
        progressView.frame.size.width = 0
        progressView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        progressView.backgroundColor = tintColor
        addSubview(progressView)

        barAnimationDuration = 0.27
        fadeAnimationDuration = 0.27
        fadeOutDelay = 0.1
    }
}
