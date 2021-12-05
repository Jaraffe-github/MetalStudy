//
//  VertexDescriptor.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import ModelIO

extension MDLVertexDescriptor
{
    static var defaultVertexDescriptor: MDLVertexDescriptor =
    {
        let vertexDescriptor = MDLVertexDescriptor()
        var offset = 0;
        
        // position
        vertexDescriptor.attributes[Int(Position.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                                                 format: .float3,
                                                                                 offset: 0,
                                                                                 bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride
        
        // normal
        vertexDescriptor.attributes[Int(Normal.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                                               format: .float3,
                                                                               offset: offset,
                                                                               bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride
        
        // uv
        vertexDescriptor.attributes[Int(UV.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                                           format: .float2,
                                                                           offset: offset,
                                                                           bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float2>.stride
        
        // tangent
        vertexDescriptor.attributes[Int(Tangent.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeTangent,
                                                                           format: .float3,
                                                                           offset: offset,
                                                                           bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride
        
        // bitangent
        vertexDescriptor.attributes[Int(Bitangent.rawValue)] = MDLVertexAttribute(name: MDLVertexAttributeBitangent,
                                                                           format: .float3,
                                                                           offset: offset,
                                                                           bufferIndex: Int(BufferIndexVertices.rawValue))
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        return vertexDescriptor
    }()
}
