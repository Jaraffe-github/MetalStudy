//
//  Terrain.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/06.
//

import MetalKit
import MetalPerformanceShaders

class TerrainModel: Node, Texturable
{
    static let maxTessellation: Int =
    {
#if os(macOS)
        return 64
#else
        return 16
#endif
    }()
    
    let patches = (horizontal: 6, vertical: 6)
    var patchCount: Int
    {
        return patches.horizontal * patches.vertical
    }
    var terrain = Terrain(size: [8, 8], height: 1, maxTessellation: UInt32(TerrainModel.maxTessellation))
    
    var wireframe = false
    
    var edgeFactors: [Float] = [4]
    var insideFactors: [Float] = [4]
    
    lazy var tessellationFactorsBuffer: MTLBuffer? =
    {
        let count = patchCount * (4 + 2)
        let size = count * MemoryLayout<Float>.size / 2
        return Renderer.device.makeBuffer(length: size, options: .storageModePrivate)
    }()
    
    var depthStencilState: MTLDepthStencilState
    var renderPipelineState: MTLRenderPipelineState
    var tessellationPipelineState: MTLComputePipelineState
    
    var controlPointsBuffer: MTLBuffer?
    
    let heightMap: MTLTexture?
    let terrainSlope: MTLTexture?
    let cliffTexture: MTLTexture?
    let snowTexture: MTLTexture?
    let grassTexture: MTLTexture?
    
    init(name: String)
    {
        depthStencilState = TerrainModel.buildDepthStencilState()
        renderPipelineState = TerrainModel.buildRenderPipelineState()
        tessellationPipelineState = TerrainModel.buildComputePipelineState()
        
        do
        {
            heightMap = try TerrainModel.loadTexture(imageName: "mountain")
            cliffTexture = try TerrainModel.loadTexture(imageName: "cliff-color")
            snowTexture = try TerrainModel.loadTexture(imageName: "snow-color")
            grassTexture = try TerrainModel.loadTexture(imageName: "grass-color")
        }
        catch
        {
            fatalError(error.localizedDescription)
        }
        terrainSlope = TerrainModel.heightToSlope(source: heightMap!)
        
        let controlPoints = createControlPoints(patches: patches,
                                                size: (width: terrain.size.x, height: terrain.size.y))
        controlPointsBuffer = Renderer.device.makeBuffer(bytes: controlPoints,
                                                         length: MemoryLayout<float3>.stride * controlPoints.count)
    }
    
    static func heightToSlope(source: MTLTexture) -> MTLTexture
    {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: source.pixelFormat,
                                                                  width: source.width,
                                                                  height: source.height,
                                                                  mipmapped: false)
        descriptor.usage = [.shaderWrite, .shaderRead]
        guard let destination = Renderer.device.makeTexture(descriptor: descriptor),
              let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
        else
        {
            fatalError()
        }
        let shader = MPSImageSobel(device: Renderer.device)
        shader.encode(commandBuffer: commandBuffer,
                      sourceTexture: source,
                       destinationTexture: destination)
        commandBuffer.commit()
        return destination
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState
    {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)!
    }
    
    static func buildRenderPipelineState() -> MTLRenderPipelineState
    {
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        descriptor.depthAttachmentPixelFormat = .depth32Float

        let vertexFunction = Renderer.library?.makeFunction(name: "terrain_vertex_main")
        let fragmentFunction = Renderer.library?.makeFunction(name: "terrain_fragment_main")
        descriptor.vertexFunction = vertexFunction
        descriptor.fragmentFunction = fragmentFunction

        let vertexDescriptor = MTLVertexDescriptor()
        vertexDescriptor.attributes[0].format = .float3
        vertexDescriptor.attributes[0].offset = 0
        vertexDescriptor.attributes[0].bufferIndex = 0

        vertexDescriptor.layouts[0].stride = MemoryLayout<float3>.stride
        vertexDescriptor.layouts[0].stepFunction = .perPatchControlPoint
        descriptor.vertexDescriptor = vertexDescriptor

        descriptor.tessellationFactorStepFunction = .perPatch
        descriptor.maxTessellationFactor = TerrainModel.maxTessellation
        descriptor.tessellationPartitionMode = .pow2

        return try! Renderer.device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    static func buildComputePipelineState() -> MTLComputePipelineState
    {
        guard let kernelFunction = Renderer.library?.makeFunction(name: "terrain_tessellation_main")
        else
        {
          fatalError("Tessellation shader function not found")
        }
        return try! Renderer.device.makeComputePipelineState(function: kernelFunction)
    }
}

extension TerrainModel: Computable
{
    func compute(computeEncoder: MTLComputeCommandEncoder, uniforms: Uniforms)
    {
        computeEncoder.setComputePipelineState(tessellationPipelineState)
        computeEncoder.setBytes(&edgeFactors,
                                length: MemoryLayout<Float>.size * edgeFactors.count,
                                index: 0)
        computeEncoder.setBytes(&insideFactors,
                                length: MemoryLayout<Float>.size * insideFactors.count,
                                index: 1)
        computeEncoder.setBuffer(tessellationFactorsBuffer, offset: 0, index: 2)
        let width = min(patchCount, tessellationPipelineState.threadExecutionWidth)
        var cameraPosition = uniforms.viewMatrix.columns.3
        computeEncoder.setBytes(&cameraPosition, length: MemoryLayout<float4>.stride, index: 3)
        var matrix = modelMatrix
        computeEncoder.setBytes(&matrix,
                                length: MemoryLayout<float4x4>.stride,
                                index: 4)
        computeEncoder.setBuffer(controlPointsBuffer, offset: 0, index: 5)
        computeEncoder.setBytes(&terrain, length: MemoryLayout<Terrain>.stride,
                                index: 6)
        
        computeEncoder.dispatchThreadgroups(MTLSizeMake(patchCount, 1, 1), threadsPerThreadgroup: MTLSizeMake(width, 1, 1))
    }
}

extension TerrainModel: Renderable
{
    func render(renderEncoder: MTLRenderCommandEncoder,
                uniforms: Uniforms,
                fragmentUniforms fragment: FragmentUniforms)
    {
        var mvp = uniforms.projectionMatrix * uniforms.viewMatrix * modelMatrix
        
        renderEncoder.setDepthStencilState(depthStencilState)
        renderEncoder.setVertexBytes(&mvp, length: MemoryLayout<float4x4>.stride, index: 1)
        renderEncoder.setRenderPipelineState(renderPipelineState)
        renderEncoder.setVertexBuffer(controlPointsBuffer, offset: 0, index: 0)
        
        let fillmode: MTLTriangleFillMode = wireframe ? .lines : .fill
        renderEncoder.setTriangleFillMode(fillmode)
        
        renderEncoder.setTessellationFactorBuffer(tessellationFactorsBuffer,
                                                  offset: 0,
                                                  instanceStride: 0)
        renderEncoder.setVertexTexture(heightMap, index: 0)
        renderEncoder.setVertexBytes(&terrain, length: MemoryLayout<Terrain>.stride, index: 6)
        
        renderEncoder.setFragmentTexture(cliffTexture, index: 1)
        renderEncoder.setFragmentTexture(snowTexture, index: 2)
        renderEncoder.setFragmentTexture(grassTexture, index: 3)
        renderEncoder.setFragmentTexture(terrainSlope, index: 4)
        
        renderEncoder.drawPatches(numberOfPatchControlPoints: 4,
                                  patchStart: 0,
                                  patchCount: patchCount,
                                  patchIndexBuffer: nil,
                                  patchIndexBufferOffset: 0,
                                  instanceCount: 1,
                                  baseInstance: 0)
    }
    
    public func rotateUsing(translation: float2)
    {
        let sensitivity: Float = 0.01
        rotation.x += Float(translation.y) * sensitivity
        rotation.z -= Float(translation.x) * sensitivity
    }
    
    public func zoomUsing(delta: CGFloat, sensitivity: Float)
    {
        position.z += Float(delta) * sensitivity
    }
}


