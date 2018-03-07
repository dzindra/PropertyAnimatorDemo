//
//  ViewController.swift
//  PropertyAnimator
//
//  Created by Jindrich Dolezy on 07/03/2018.
//  Copyright © 2018 Dzindra. All rights reserved.
//

import UIKit

enum AnimState: Int {
    case collapsed
    case expanded
    
    func select<T>(collapsed: T, expanded: T) -> T {
        switch self {
        case .collapsed:
            return collapsed
        case .expanded:
            return expanded
        }
    }
    
    var next: AnimState {
        return select(collapsed: .expanded, expanded: .collapsed)
    }
    
    mutating func toggle() {
        self = self.next
    }
    
    var corners: CGFloat {
        return select(collapsed: 0, expanded: 10)
    }
    
    var color: UIColor {
        return select(collapsed: .blue, expanded: .red)
    }
    
    func height(view: UIView) -> CGFloat {
        return select(collapsed: 150, expanded: view.bounds.height - 20)
    }
}


class ViewController: UIViewController {
    @IBOutlet weak var animView: UIView!
    @IBOutlet weak var viewContraint: NSLayoutConstraint!
    
    var animator: UIViewPropertyAnimator?
    var animState: AnimState = .collapsed

    override func viewDidLoad() {
        super.viewDidLoad()
        
        animView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        
        updateLayout(state: animState)
    }
    
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            self.panningBegan()
        case .ended:
            self.panningEnded(velocity: recognizer.velocity(in: self.view), translation: recognizer.translation(in: self.view))
        default:
            self.panningChanged(translation: recognizer.translation(in: self.view))
        }
    }
    
    func updateLayout(state: AnimState) {
        viewContraint.constant = state.height(view: view)
        animView.backgroundColor = state.color
        animView.layer.cornerRadius = state.corners
        view.layoutIfNeeded()
    }
    
    func panningBegan() {
        if animator?.isRunning ?? false { return }
        
//        animator = UIViewPropertyAnimator(duration: 1.0, curve: .easeIn) {
        animator = UIViewPropertyAnimator(duration: 0.5, dampingRatio: 0.8) {
            self.updateLayout(state: self.animState.next)
        }
        animator?.pauseAnimation()
    }
    
    func panningChanged(translation: CGPoint) {
        if animator?.isRunning ?? false { return }

        let progress = animState.select(
            collapsed: -translation.y / self.view.center.y,
            expanded: translation.y / self.view.center.y
        )
        animator?.fractionComplete = max(0.001, min(0.999, progress))
    }
    
    func panningEnded(velocity: CGPoint, translation: CGPoint) {
        guard let animator = animator else { return }
        
        animator.isReversed = animator.fractionComplete < 0.3
        animator.addCompletion { pos in
            if pos == .end {
                self.animState.toggle()
            }
            self.updateLayout(state: self.animState)
        }
        
        animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }

}

