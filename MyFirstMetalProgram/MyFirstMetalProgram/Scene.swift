//
//  Scene.swift
//  MyFirstMetalProgram
//
//  Created by Jaraffe on 2021/10/27.
//

import MetalKit

class Scene: Node{
    var device: MTLDevice!
    var sceneConstants = SceneConstants()
    var camera = Camera()
    var light = Light()
    
    init(device: MTLDevice){
        self.device = device
        super.init()
    }
    
    func updateInput(deltaTime: Float){
        
    }
    
    func updateModel(){
        
    }
    
    func render(commandEncoder: MTLRenderCommandEncoder, deltaTime: Float){
        light.ambientIntensity = Preferences.ambientIntensity
        light.diffuseIntensity = Preferences.diffuseIntensity
        updateInput(deltaTime: deltaTime)
        updateModel()
        
        sceneConstants.projectionMatrix = camera.projectionMatrix
        commandEncoder.setVertexBytes(&sceneConstants, length: MemoryLayout<SceneConstants>.stride, index: 2)
        commandEncoder.setFragmentBytes(&light, length: MemoryLayout<Light>.stride, index: 1)
        
        for child in children{
            child.render(commandEncoder: commandEncoder, parentModelMatrix: camera.viewMatrix)
        }
    }
}
