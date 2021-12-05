//
//  Renderer.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

class Renderer: NSObject
{
    static var device: MTLDevice!
    static var commandQueue: MTLCommandQueue!
    static var library: MTLLibrary!
    static var colorPixelFormat: MTLPixelFormat!
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    let depthStencilState: MTLDepthStencilState
    let lighting = Lighting()
    
    lazy var camera: Camera =
    {
        let camera = ArcballCamera()
        camera.distance = 3
        camera.target = [0, 1, 0]
        camera.rotation.x = Float(-10).degreesToRadians
        return camera
    }()
    
    var models: [Model] = []
    
    init(metalView: MTKView)
    {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let commandQueue = device.makeCommandQueue()
        else
        {
            fatalError("GPU not available")
        }
        Renderer.device = device
        Renderer.commandQueue = commandQueue
        Renderer.library = device.makeDefaultLibrary()
        Renderer.colorPixelFormat = metalView.colorPixelFormat
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        depthStencilState = Renderer.buildDepthStencilState()!
        super.init()
        metalView.clearColor = MTLClearColor(red: 0.93, green: 0.97, blue: 1.0, alpha: 1.0)
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
       
        fragmentUniforms.lightCount = lighting.count
        
        let model = Model(name: "chest.obj")
        model.position = [0, 0, 0]
        models.append(model)
    }
    
    static func buildDepthStencilState() -> MTLDepthStencilState?
    {
        let descriptor = MTLDepthStencilDescriptor()
        descriptor.depthCompareFunction = .less
        descriptor.isDepthWriteEnabled = true
        return Renderer.device.makeDepthStencilState(descriptor: descriptor)
    }
}

extension Renderer: MTKViewDelegate
{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize)
    {
        camera.aspect = Float(view.bounds.width) / Float(view.bounds.height)
    }
    
    func draw(in view: MTKView)
    {
        guard
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else
        {
            return
        }
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position
        
        var lights = lighting.lights
        renderEncoder.setFragmentBytes(&lights,
                                       length: MemoryLayout<Light>.stride * lights.count,
                                       index: Int(BufferIndexLights.rawValue))
    
        for model in models
        {
            fragmentUniforms.tiling = model.tiling
            renderEncoder.setFragmentBytes(&fragmentUniforms,
                                           length: MemoryLayout<FragmentUniforms>.stride,
                                           index: Int(BufferIndexFragmentUniforms.rawValue))
            
            renderEncoder.setFragmentSamplerState(model.samplerState, index: 0)
            
            uniforms.modelMatrix = model.modelMatrix
            uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
            
            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride,
                                         index: Int(BufferIndexUniforms.rawValue))
            
            for mesh in model.meshes
            {
                for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated()
                {
                    renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
                }

                for submesh in mesh.submeshes
                {
                    renderEncoder.setRenderPipelineState(submesh.pipelineState)
                    
                    renderEncoder.setFragmentTexture(submesh.textures.baseColor, index: Int(BaseColorTexture.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(NormalTexture.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.roughness, index: Int(RoughnessTexture.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.metallic, index: Int(MetallicTexture.rawValue))
                    renderEncoder.setFragmentTexture(submesh.textures.ao, index: Int(AOTexture.rawValue))
                    
                    var material = submesh.material
                    renderEncoder.setFragmentBytes(&material,
                                                   length: MemoryLayout<Material>.stride,
                                                   index: Int(BufferIndexMaterials.rawValue))
                    
                    let mtkSubmesh = submesh.mtkSubmesh
                    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                        indexCount: mtkSubmesh.indexCount,
                                                        indexType: mtkSubmesh.indexType,
                                                        indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                                        indexBufferOffset: mtkSubmesh.indexBuffer.offset)
                }
            }
        }
        
        // debugLights(renderEncoder: renderEncoder, lightType: SpotLight)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else
        {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
