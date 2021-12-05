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
    static var fps: Int!
    
    var fragmentUniforms = FragmentUniforms()
    let depthStencilState: MTLDepthStencilState
    let lighting = Lighting()
    var scene: Scene?

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
        Renderer.fps = metalView.preferredFramesPerSecond
        
        metalView.device = device
        metalView.depthStencilPixelFormat = .depth32Float
        
        depthStencilState = Renderer.buildDepthStencilState()!
        super.init()
        metalView.clearColor = MTLClearColor(red: 0.49, green: 0.62, blue: 0.75, alpha: 1.0)
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
       
        fragmentUniforms.lightCount = lighting.count
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
        scene?.sceneSizeWillChange(to: size)
    }
    
    func draw(in view: MTKView)
    {
        guard
            let scene = scene,
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer(),
            let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        else
        {
            return
        }
        
        let deltaTime = 1 / Float(Renderer.fps)
        scene.update(deltaTime: deltaTime)
        
        renderEncoder.setDepthStencilState(depthStencilState)
        
        var lights = lighting.lights
        renderEncoder.setFragmentBytes(&lights,
                                       length: MemoryLayout<Light>.stride * lights.count,
                                       index: Int(BufferIndexLights.rawValue))
    
        for renderable in scene.renderables
        {
            renderEncoder.pushDebugGroup(renderable.name)
            renderable.render(renderEncoder: renderEncoder,
                              uniforms: scene.uniforms,
                              fragmentUniforms: scene.fragmentUniforms)
            renderEncoder.popDebugGroup()
        }
        
        // debugLights(renderEncoder: renderEncoder, lightType: SpotLight)
        
        renderEncoder.endEncoding()
        guard let drawable = view.currentDrawable else
        {
            return
        }
        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
}
