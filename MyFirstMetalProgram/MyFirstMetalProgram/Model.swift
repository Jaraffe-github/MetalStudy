//
//  Model.swift
//  MyFirstMetalProgram
//
//  Created by Jaraffe on 2021/11/02.
//

import MetalKit

class Model: Node{
    
    var vertexFunctionName: String = "basic_vertex_function"
    var fragmentFunctionName: String = "basic_fragment_function"
    
    var renderPipelineState: MTLRenderPipelineState!
    
    var meshes: [AnyObject]?
    
    var modelConstants = ModelConstants()
    
    var texture: MTLTexture?
    
    var vertexDescriptor: MTLVertexDescriptor{
        let vertexDescriptor = MTLVertexDescriptor()
        
        //Position
        vertexDescriptor.attributes[0].bufferIndex = 0
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        
        //Color
        vertexDescriptor.attributes[1].bufferIndex = 0
        vertexDescriptor.attributes[1].format = .float4
        vertexDescriptor.attributes[1].offset = MemoryLayout<Float>.size * 3
        
        //Texture Coordinates
        vertexDescriptor.attributes[2].bufferIndex = 0
        vertexDescriptor.attributes[2].format = .float2
        vertexDescriptor.attributes[2].offset = MemoryLayout<Float>.size * 7
        
        //Normals
        vertexDescriptor.attributes[3].bufferIndex = 0
        vertexDescriptor.attributes[3].format = .float3
        vertexDescriptor.attributes[3].offset = MemoryLayout<Float>.size * 9
        
        vertexDescriptor.layouts[0].stride = MemoryLayout<Float>.size * 12
        
        return vertexDescriptor
    }
    
    init(device: MTLDevice, modelName: String, imageName: String){
        super.init()
        buildModelMeshes(device: device, modelName: modelName)
        
        if(imageName != ""){
            texture = setTexture(device: device, imageName: imageName)
            fragmentFunctionName = "textured_fragment_function"
        }
        
        renderPipelineState = buildPipelineState(device: device)
    }
    
    func buildModelMeshes(device: MTLDevice, modelName: String){
        let assetURL = Bundle.main.url(forResource: modelName, withExtension: "obj")
        
        let assetVertexDescriptor = MTKModelIOVertexDescriptorFromMetal(vertexDescriptor)
        
        let position = assetVertexDescriptor.attributes[0] as! MDLVertexAttribute
        position.name = MDLVertexAttributePosition
        assetVertexDescriptor.attributes[0] = position
        
        let color = assetVertexDescriptor.attributes[1] as! MDLVertexAttribute
        color.name = MDLVertexAttributeColor
        assetVertexDescriptor.attributes[1] = color
        
        let textureCoordiantes = assetVertexDescriptor.attributes[2] as! MDLVertexAttribute
        textureCoordiantes.name = MDLVertexAttributeTextureCoordinate
        assetVertexDescriptor.attributes[2] = textureCoordiantes
        
        let normals = assetVertexDescriptor.attributes[3] as! MDLVertexAttribute
        normals.name = MDLVertexAttributeNormal
        assetVertexDescriptor.attributes[3] = normals
        
        let bufferAllocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(url: assetURL!, vertexDescriptor: assetVertexDescriptor, bufferAllocator: bufferAllocator)
        
        do{
            _ = try MTKMesh.newMeshes(asset: asset, device: device)
        } catch let error as NSError{
            print(error)
        }
    }
}

extension Model: Renderable{
    func draw(commandEncoder: MTLRenderCommandEncoder, modelViewMatrix: matrix_float4x4) {
        commandEncoder.setRenderPipelineState(renderPipelineState)
        
        modelConstants.modelViewMatrix = modelViewMatrix
        modelConstants.materialColor = materialColor
        modelConstants.normalMatrix = modelViewMatrix.upperLeftMatrix()
        modelConstants.shininess = shininess
        modelConstants.specularIntensity = specularIntensity
        commandEncoder.setVertexBytes(&modelConstants, length: MemoryLayout<ModelConstants>.stride, index: 1)
        
        if(texture != nil){
            commandEncoder.setFragmentTexture(texture, index: 0)
        }
        
        guard let meshes = self.meshes as? [MTKMesh], meshes.count > 0 else { return }
        
        for mesh in meshes{
            let vertexBuffer = mesh.vertexBuffers[0]
            commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
            
            for submesh in mesh.submeshes{
                commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                                     indexCount: submesh.indexCount,
                                                     indexType: submesh.indexType,
                                                     indexBuffer: submesh.indexBuffer.buffer,
                                                     indexBufferOffset: submesh.indexBuffer.offset)
            }
        }
    }
}

extension Model: Texturable{  }
