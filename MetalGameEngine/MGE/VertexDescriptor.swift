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
        
        vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                            format: .float3,
                                                            offset: 0,
                                                            bufferIndex: 0)
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                            format: .float3,
                                                            offset: offset,
                                                            bufferIndex: 0)
        offset += MemoryLayout<float3>.stride
        
        vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: offset)
        return vertexDescriptor
    }()
}