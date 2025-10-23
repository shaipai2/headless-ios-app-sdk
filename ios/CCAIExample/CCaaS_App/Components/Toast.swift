//
//  Toast.swift
//  CCAIExample
//
//  Created by Nirob Hasan on 4/10/25.
//

import UIKit

struct Toast {
    static func show(message: String) {
        guard let viewController = getTopViewController() else { return }
        let toastLabel = UILabel(frame: CGRect(x: viewController.view.frame.size.width/2 - 150, y: viewController.view.frame.size.height-100, width: 300, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 10
        toastLabel.clipsToBounds = true

        viewController.view.addSubview(toastLabel)

        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            toastLabel.alpha = 1.0
        }, completion: { _ in
            UIView.animate(withDuration: 0.5, delay: 2.0, options: .curveEaseIn, animations: {
                toastLabel.alpha = 0.0
            }, completion: { _ in
                toastLabel.removeFromSuperview()
            })
        })
    }

    private static func getTopViewController() -> UIViewController? {
        let keyWindow = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
        guard let rootViewController = keyWindow?.rootViewController else { return nil }
        var topViewController = rootViewController
        while let presentedViewController = topViewController.presentedViewController {
            topViewController = presentedViewController
        }
        return topViewController
    }
}
