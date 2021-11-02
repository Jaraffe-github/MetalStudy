//
//  Primitive.swift
//  MyFirstMetalProgram
//
//  Created by Jaraffe on 2021/11/02.
//

import MetalKit

class Primitive: Node{
    
    var renderPipelineState: MTLRenderPipelineState!
    
    var vertexFunctionName: String
    var fragmentFunctionName: String
    
    var texture: MTLTexture?
    
    var vertexDescriptor: MTLVertexDescriptor {
        let vertexDescriptor = MTLVertexDescriptor()
        //Vertices
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        
        //Color
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<SIMD3<Float>>.size
        
        //Texture Coordinates
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<SIMD3<Float>>.size + MemoryLayout<SIMD4<Float>>.size
        
        //Normals
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].offset = MemoryLayout<SIMD3<Float>>.size + MemoryLayout<SIMD4<Float>>.size + MemoryLayout<SIMD2<Float>>.size
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Vertex>.stride
        return vertexDescriptor
    }
    
    var vertexBuffer: MTLBuffer!
    var indexBuffer: MTLBuffer!
    
    var vertices: [Vertex]!
    var indices: [UInt32]!
    
    var modelConstants = ModelConstants()
    
    init(device: MTLDevice, imageName: String){
        vertexFunctionName = "basic_vertex_function"
        fragmentFunctionName = "basic_fragment_function"
        super.init()
        if let texture = setTexture(device: device, imageName: imageName){
            self.texture = texture
            fragmentFunctionName = "textured_fragment_function"
        }
        buildVertices()
        buildBuffers(device: device)
        renderPipelineState = buildPipelineState(device: device)
    }
    
    func buildVertices(){  }
    
    func buildBuffers(device: MTLDevice){
        vertexBuffer = device.makeBuffer(bytes: vertices, length: MemoryLayout<Vertex>.stride * vertices.count, options: [])
        indexBuffer = device.makeBuffer(bytes: indices, length: MemoryLayout<UInt32>.size * indices.count, options: [])
    }
}

extension Primitive: Renderable{
    func draw(commandEncoder: MTLRenderCommandEncoder, modelViewMatrix: matrix_float4x4){
        commandEncoder.setRenderPipelineState(renderPipelineState)
        
        modelConstants.modelViewMatrix = modelViewMatrix
        modelConstants.materialColor = materialColor
        
        commandEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        commandEncoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.stride, index: 1)
        commandEncoder.setFragmentTexture(texture, index: 0)
        
        commandEncoder.drawIndexedPrimitives(type: .triangle,
                                             indexCount: indices.count,
                                             indexType: .uint32,
                                             indexBuffer: indexBuffer,
                                             indexBufferOffset: 0)
    }
}

extension Primitive: Texturable{  }
