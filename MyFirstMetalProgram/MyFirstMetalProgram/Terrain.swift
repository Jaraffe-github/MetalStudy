//
//  Terrain.swift
//  MyFirstMetalProgram
//
//  Created by Jaraffe on 2021/11/02.
//

import MetalKit

class Terrain: Primitive{
    
    let GRID_SIZE: Int = 1000
    let VERTEX_COUNT: Int = 500
    
    override func buildVertices() {
        vertices = []
        indices = []
        
        for z in 0..<VERTEX_COUNT{
            for x in 0..<VERTEX_COUNT{
                let vX: Float = Float(x) / Float(Float(VERTEX_COUNT) - Float(1)) * Float(GRID_SIZE)
                let vY: Float = 0.0
                let vZ: Float = Float(z) / Float(Float(VERTEX_COUNT) - Float(1)) * Float(GRID_SIZE)
                
                let tX: Float = fmod(Float(x), 2.0)
                let tZ: Float = fmod(Float(z), 2.0)
                
                let position: SIMD3<Float> = SIMD3<Float>(vX, vY, vZ)
                
                let color: SIMD4<Float> = SIMD4<Float>(repeating: 1)
                
                let textureCoordinates: SIMD2<Float> = SIMD2<Float>(tX, tZ)
                
                let normals: SIMD3<Float> = SIMD3<Float>(0,1,0)
                
                vertices.append(Vertex(position: position, color: color, textCoords: textureCoordinates, normal: normals))
            }
        }
        
        for gz in 0..<VERTEX_COUNT-1{
            for gx in 0..<VERTEX_COUNT-1{
                let topLeft: UInt32 = UInt32(gz * VERTEX_COUNT + gx)
                let topRight: UInt32 = (topLeft + UInt32(1))
                let bottomLeft: UInt32 = UInt32(((gz + 1) * VERTEX_COUNT) + gx)
                let bottomRight: UInt32 = (bottomLeft + UInt32(1))
                indices.append(topLeft)
                indices.append(bottomLeft)
                indices.append(topRight)
                indices.append(topRight)
                indices.append(bottomLeft)
                indices.append(bottomRight)
            }
        }
    }
}
