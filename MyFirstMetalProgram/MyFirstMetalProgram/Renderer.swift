import MetalKit

class Renderer: NSObject{

    var commandQueue: MTLCommandQueue!
    var depthStencilState: MTLDepthStencilState!
    var samplerState: MTLSamplerState!
    var scene: Scene!
    var wireFrameOn:Bool = false
    var mousePosition = SIMD2<Float>(0, 0)
    
    init(device: MTLDevice){
        super.init()
        commandQueue = device.makeCommandQueue()
        self.scene = TerrainScene(device: device)
        buildDepthStencilState(device: device)
        buildSamplerState(device: device)
    }
    
    func buildDepthStencilState(device: MTLDevice){
        let depthStencilDescriptor = MTLDepthStencilDescriptor()
        depthStencilDescriptor.isDepthWriteEnabled = true
        depthStencilDescriptor.depthCompareFunction = .less
        depthStencilState = device.makeDepthStencilState(descriptor: depthStencilDescriptor)
    }
    
    func buildSamplerState(device: MTLDevice){
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
}

extension Renderer: MTKViewDelegate{
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize){
        scene.camera.aspectRatio = Float(Float(view.bounds.width) / Float(view.bounds.height))
        updateTrackingArea(view: view)
    }
    
    func updateTrackingArea(view: MTKView){
        let area = NSTrackingArea(rect: view.bounds, options: [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseMoved, NSTrackingArea.Options.enabledDuringMouseDrag], owner: view, userInfo: nil)
        view.addTrackingArea(area)
    }
    
    func updateInput(view: MTKView){
        let mousePosition = MetalView.getMousePosition()
        
        let posX: Float = Float(mousePosition.x)
        let posY: Float = Float(-mousePosition.y) + Float(view.bounds.height)
        
        InputHandler.setMousePosition(position: SIMD2<Float>(posX, posY))
    }
    
    func draw(in view: MTKView){
        view.clearColor = Preferences.clearColor
        guard let drawable = view.currentDrawable, let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let commandEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        commandEncoder?.setDepthStencilState(depthStencilState)
        commandEncoder?.setFragmentSamplerState(samplerState, index: 0)
        
        if(Preferences.useWireFrame){
            commandEncoder?.setTriangleFillMode(.lines)
        }
        
        updateInput(view: view)
        
        let deltaTime = 1 / Float(view.preferredFramesPerSecond)
        scene.render(commandEncoder: commandEncoder!, deltaTime: deltaTime)
        
        commandEncoder?.endEncoding()
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
    }
}
