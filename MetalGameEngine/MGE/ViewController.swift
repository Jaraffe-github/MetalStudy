//
//  ViewController.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

class ViewController: LocalViewController
{
    var renderer: Renderer?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        guard let metalView = view as? MTKView
        else
        {
            fatalError("metal view not set up in storyboard")
        }
        renderer = Renderer(metalView: metalView)
        addGestureRecognizers(to: metalView)
    }
}
