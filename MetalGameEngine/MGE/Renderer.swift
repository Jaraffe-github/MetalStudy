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
    
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()
    
    let depthStencilState: MTLDepthStencilState
    
    // Lights
    lazy var directionalLight: Light =
    {
        var light = buildDefaultLight()
        light.position = [1, 2, -2]
        return light;
    }()
    lazy var ambientLight: Light =
    {
        var light = buildDefaultLight()
        light.color = [0.5, 1, 0]
        light.intensity = 0.1
        light.type = AmbientLight
        return light
    }()
    lazy var pointLight: Light =
    {
        var light = buildDefaultLight()
        light.position = [-0, 0.5, -0.5]
        light.color = [1, 0, 0]
        light.attenuation = float3(1, 3, 4)
        light.type = PointLight
        return light
    }()
    lazy var spotlight: Light =
    {
        var light = buildDefaultLight()
        light.position = [0.4, 0.8, 1]
        light.color = [1, 0, 1]
        light.attenuation = float3(1, 0.5, 0)
        light.type = SpotLight
        light.coneAngle = Float(40).degreesToRadians
        light.coneDirection = [-2, 0, -1.5]
        light.coneAttenuation = 12
        return light
    }()
    var lights: [Light] = []
    
    lazy var camera: Camera =
    {
        let camera = ArcballCamera()
        camera.distance = 2.5
        camera.target = [0.5, 0.5, 0]
        camera.rotation.x = Float(-10).degreesToRadians
        return camera
    }()
    
    var models: [Model] = []
    
    lazy var lightPipelineState: MTLRenderPipelineState =
    {
        return buildLightPipelineState()
    }()
    
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
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        depthStencilState = Renderer.buildDepthStencilState()!
        super.init()
        metalView.clearColor = MTLClearColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 1.0)
        metalView.delegate = self
        
        let train = Model(name: "train.obj")
        train.position = [0, 0, 0]
        train.rotation = [0, Float(45).degreesToRadians, 0]
        models.append(train)
        
        let tree = Model(name: "treefir.obj")
        tree.position = [1.4, 0, 0]
        models.append(tree)
        
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
        lights.append(directionalLight)
        lights.append(ambientLight)
        lights.append(pointLight)
        lights.append(spotlight)
        fragmentUniforms.lightCount = UInt32(lights.count)
    }
    
    func buildDefaultLight() -> Light
    {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [0.6, 0.6, 0.6]
        light.intensity = 1
        light.attenuation = float3(1, 0, 0)
        light.type = DirectionalLight
        return light
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
        
        renderEncoder.setFragmentBytes(&lights,
                                       length: MemoryLayout<Light>.stride * lights.count,
                                       index: Int(BufferIndexLights.rawValue))
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        
        for model in models
        {
            uniforms.modelMatrix = model.modelMatrix
            uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
            
            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride,
                                         index: Int(BufferIndexUniforms.rawValue))
            
            renderEncoder.setRenderPipelineState(model.pipelineState)
            
            for mesh in model.meshes
            {
                let vertexBuffer = mesh.mtkMesh.vertexBuffers[0].buffer
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: Int(BufferIndexVertices.rawValue))
                
                for submesh in mesh.submeshes
                {
                    let mtkSubmesh = submesh.mtkSubmesh
                    renderEncoder.drawIndexedPrimitives(type: .triangle,
                                                        indexCount: mtkSubmesh.indexCount,
                                                        indexType: mtkSubmesh.indexType,
                                                        indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                                        indexBufferOffset: mtkSubmesh.indexBuffer.offset)
                }
            }
        }
        
        debugLights(renderEncoder: renderEncoder, lightType: SpotLight)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else
        {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
