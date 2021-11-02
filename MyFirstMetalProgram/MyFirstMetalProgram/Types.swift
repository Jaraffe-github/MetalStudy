//
//  Types.swift
//  MyFirstMetalProgram
//
//  Created by Jaraffe on 2021/10/25.
//

import MetalKit

struct Vertex{
    var position: SIMD3<Float>
    var color: SIMD4<Float>
    var textCoords: SIMD2<Float>
    var normal: SIMD3<Float>
}

struct ModelConstants{
    var modelViewMatrix = matrix_identity_float4x4
    var materialColor = SIMD4<Float>(repeating: 1)
    var normalMatrix = matrix_identity_float3x3
    var shininess: Float = 0.0
    var specularIntensity: Float = 0.0
}

struct SceneConstants{
    var projectionMatrix = matrix_identity_float4x4
}

struct Light{
    var color = SIMD3<Float>(repeating: 1)
    var ambientIntensity: Float = 0.0
    var direction = SIMD3<Float>(repeating: 0)
    var diffuseIntensity: Float = 0.2
}
