//
//  PlatformController.swift
//  MGE-macOS
//
//  Created by 최승민 on 2021/12/04.
//

import Cocoa

class LocalViewController: NSViewController {}

extension ViewController
{
    func addGestureRecognizers(to view: NSView)
    {
        let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
        view.addGestureRecognizer(pan)
    }
    
    @objc func handlePan(gesture: NSPanGestureRecognizer)
    {
        let translation = gesture.translation(in: gesture.view)
        let delta = float2(Float(translation.x), Float(translation.y))
        
        renderer?.scene?.camera.rotate(delta: delta)
        gesture.setTranslation(.zero, in: gesture.view)
    }
    
    override func scrollWheel(with event: NSEvent)
    {
        renderer?.scene?.camera.zoom(delta: Float(event.deltaY))
    }
}
