//
//  DpadView.swift
//  HarpApp
//
//  Created by Lou Zell on 7/25/16.
//  Copyright © 2016 Lou Zell. All rights reserved.
//

import UIKit

class DpadView : UIView {




    class Images {
        lazy var inactive   = UIImage(named: "Dpad")!
        lazy var right      = UIImage(named: "DpadRight")!
        lazy var downRight  = UIImage(named: "DpadDownRight")!
        lazy var down       = UIImage(named: "DpadDown")!
        lazy var downLeft   = UIImage(named: "DpadDownLeft")!
        lazy var left       = UIImage(named: "DpadLeft")!
        lazy var upLeft     = UIImage(named: "DpadUpLeft")!
        lazy var up         = UIImage(named: "DpadUp")!
        lazy var upRight    = UIImage(named: "DpadUpRight")!

        static let a = M_PI_4
        static let b = a / 2.0

        let arcs = [
            [-b          , b],
            [b           , b + a],
            [b + a       , b + 2 * a],
            [b + 2 * a   , b + 3 * a],
            [b + 3 * a   , -b - 3 * a],
            [-b - 3 * a  , -b - 2 * a],
            [-b - 2 * a  , -b - a],
            [-b - a      , -b],
        ]

        subscript(key: Double) -> UIImage {
            get {
                switch key {
                case _ where key > arcs[0][0] && key <= arcs[0][1]: return right
                case _ where key > arcs[1][0] && key <= arcs[1][1]: return downRight
                case _ where key > arcs[2][0] && key <= arcs[2][1]: return down
                case _ where key > arcs[3][0] && key <= arcs[3][1]: return downLeft
                case _ where key > arcs[4][0] || key <= arcs[4][1]: return left
                case _ where key > arcs[5][0] && key <= arcs[5][1]: return upLeft
                case _ where key > arcs[6][0] && key <= arcs[6][1]: return up
                case _ where key > arcs[7][0] && key <= arcs[7][1]: return upRight
                default:
                    assert(false)
                    return inactive
                }
            }
        }
    }
    let images = Images()
    var imgView : UIImageView!

    init() {
        // First Phase
        super.init(frame: CGRectZero)

        // Second phase
        multipleTouchEnabled = false
        imgView = UIImageView(frame: CGRectZero)
        imgView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imgView)
        addConstraints(NSLayoutConstraint.superviewFillingConstraintsForView(imgView))
        imgView.image = images.inactive
    }

    required init?(coder: NSCoder) { super.init(coder: coder); assert(false) }


    // MARK: - Tracking

    // The tracking code is simplified under the assumption that there will only ever
    // be one touch on the dpad:
    var trackingTouch : UITouch?
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        trackingTouch = touches.first
        updateUI(trackingTouch!)
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        assert(trackingTouch == touches.first)
        updateUI(trackingTouch!)
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        assert(trackingTouch == touches.first)
        finishTracking()
    }

    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        finishTracking()
    }

    private func finishTracking() {
        trackingTouch = nil
        imgView.image = images.inactive
    }

    private func updateUI(touch: UITouch) {
        let loc = touch.locationInView(self)
        let origin = CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds))
        let theta = atan2(loc.y - origin.y, loc.x - origin.x)
        print(theta)
        imgView.image = images[Double(theta)]
    }
}