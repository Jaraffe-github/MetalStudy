//
//  Primitive.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

class Primitive
{
    static func makeCube(device: MTLDevice, size: Float) -> MDLMesh
    {
        let allocator = MTKMeshBufferAllocator(device: device)
        let mesh = MDLMesh(boxWithExtent: [size, size, size],
                           segments: [1, 1, 1],
                           inwardNormals: false, geometryType: .triangles,
                           allocator: allocator)
        return mesh
    }
}
