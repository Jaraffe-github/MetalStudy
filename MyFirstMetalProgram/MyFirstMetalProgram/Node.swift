//
//  File.swift
//  MyFirstMetalProgram
//
//  Created by Jaraffe on 2021/10/28.
//

import MetalKit

class Node{
    var children: [Node] = [ ]
    
    var position = SIMD3<Float>(repeating: 0)
    var rotation = SIMD3<Float>(repeating: 0)
    var scale = SIMD3<Float>(repeating: 1)
    
    var materialColor = SIMD4<Float>(repeating: 1)
    
    var shininess: Float = 0.0
    var specularIntensity: Float = 0.0
    
    var modelMatrix: matrix_float4x4{
        var modelMatrix = matrix_identity_float4x4
        modelMatrix.translate(direction: position)
        modelMatrix.rotate(angle: rotation.x, axis: SIMD3<Float>(1, 0, 0))
        modelMatrix.rotate(angle: rotation.y, axis: SIMD3<Float>(0, 1, 0))
        modelMatrix.rotate(angle: rotation.z, axis: SIMD3<Float>(0, 0, 1))
        modelMatrix.scale(axis: scale)
        return modelMatrix
    }
    
    func add(child: Node){
        children.append(child)
    }
    
    func render(commandEncoder: MTLRenderCommandEncoder, parentModelMatrix: matrix_float4x4){
        for child in children{
            child.render(commandEncoder: commandEncoder, parentModelMatrix: parentModelMatrix)
        }
        let modelViewMatrix:matrix_float4x4 = matrix_multiply(parentModelMatrix, modelMatrix)
        if let renderable = self as? Renderable{
            renderable.draw(commandEncoder: commandEncoder, modelViewMatrix: modelViewMatrix)
        }
    }
}
