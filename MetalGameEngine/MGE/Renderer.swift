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

    var semaphore: DispatchSemaphore
    let dispatchQueue = DispatchQueue(label: "Queue", attributes: .concurrent)
    
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
        
        semaphore = DispatchSemaphore(value: Scene.buffersInFlight)
        
        depthStencilState = Renderer.buildDepthStencilState()!
        super.init()
        metalView.clearColor = MTLClearColor(red: 0.49, green: 0.62, blue: 0.75, alpha: 1.0)
        metalView.delegate = self
        mtkView(metalView, drawableSizeWillChange: metalView.bounds.size)
       
        fragmentUniforms.lightCount = lighting.count
        
        #if os(OSX)
        let devices = MTLCopyAllDevices()
        for device in devices
        {
            if #available(macOS 10.15, *)
            {
                if device.supportsFamily(.mac2)
                {
                    print("\(device.name) is a mac 2 family gpu running on macOS Catalina.")
                }
                else
                {
                    print("\(device.name) is a mac 1 family gpu running on macOS Catalina.")
                }
            }
            else
            {
                if device.supportsFeatureSet(.macOS_GPUFamily2_v1)
                {
                    print("You are using a recent GPU with an older version of macOS.")
                }
                else
                {
                    print("You are using on older GPU with an older version of macOS.")
                }
            }
        }
        #endif
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
        _ = semaphore.wait(timeout: .distantFuture)
        
        guard
            let scene = scene,
            let descriptor = view.currentRenderPassDescriptor,
            let commandBuffer = Renderer.commandQueue.makeCommandBuffer()
        else
        {
            return
        }
        
        let deltaTime = 1 / Float(Renderer.fps)
        scene.update(deltaTime: deltaTime)
        
        let uniforms = scene.uniforms[scene.currentUniformIndex]
        
        if let computeEncoder = commandBuffer.makeComputeCommandEncoder()
        {
            scene.landscape?.compute(computeEncoder: computeEncoder, uniforms: uniforms)
            
            for computable in scene.computables
            {
                computeEncoder.pushDebugGroup(computable.name)
                computable.compute(computeEncoder: computeEncoder, uniforms: uniforms)
                computeEncoder.popDebugGroup()
            }
            computeEncoder.endEncoding()
        }

        if let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        {
            renderEncoder.setDepthStencilState(depthStencilState)
            
            scene.landscape?.render(renderEncoder: renderEncoder, uniforms: uniforms)
            
            var lights = lighting.lights
            renderEncoder.setFragmentBytes(&lights,
                                           length: MemoryLayout<Light>.stride * lights.count,
                                           index: Int(BufferIndexLights.rawValue))
            
            scene.skybox?.update(renderEncoder: renderEncoder)
            
            for renderable in scene.renderables
            {
                renderEncoder.pushDebugGroup(renderable.name)
                renderable.render(renderEncoder: renderEncoder,
                                  uniforms: uniforms,
                                  fragmentUniforms: scene.fragmentUniforms)
                renderEncoder.popDebugGroup()
            }
            
            scene.skybox?.render(renderEncoder: renderEncoder, uniforms: uniforms)
            
            // debugLights(renderEncoder: renderEncoder, lightType: SpotLight)
            renderEncoder.endEncoding()
        }

        guard let drawable = view.currentDrawable else
        {
            return
        }
        commandBuffer.present(drawable)
        
        commandBuffer.enqueue()
        
        weak var sem = semaphore
        dispatchQueue.async
        {
            commandBuffer.addCompletedHandler{_ in sem?.signal() }
            commandBuffer.commit()
        }
        
        __dispatch_barrier_sync(dispatchQueue) {}
    }
}
