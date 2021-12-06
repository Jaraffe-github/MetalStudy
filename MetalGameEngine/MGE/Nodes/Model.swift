//
//  Model.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

class Model: Node
{
    let meshes: [Mesh]
    var tiling: UInt32 = 1
    let samplerState: MTLSamplerState?
    static var vertexDescriptor: MDLVertexDescriptor = MDLVertexDescriptor.defaultVertexDescriptor
    
    let animations: [String: AnimationClip]
    var currentTime: Float = 0
    var currentAnimation: AnimationClip?
    var animationPaused = true
    
    private var transforms: [Transform]
    let instanceCount: Int
    var instanceBuffer: MTLBuffer
    
    let debugBoundingBox: DebugBoundingBox
    
    init(name: String, vertexFunctionName: String = "vertex_main", fragmentFunctionName: String = "fragment_IBL", transforms: [Transform] = [Transform()])
    {
        guard let assetUrl = Bundle.main.url(forResource: name, withExtension: nil)
        else
        {
            fatalError("Model: \(name) not found")
        }
        let allocator = MTKMeshBufferAllocator(device: Renderer.device)
        let asset = MDLAsset(url: assetUrl, vertexDescriptor: MDLVertexDescriptor.defaultVertexDescriptor, bufferAllocator: allocator)
        
        asset.loadTextures()
        
        var mtkMeshes: [MTKMesh] = []
        let mdlMeshes = asset.childObjects(of: MDLMesh.self) as! [MDLMesh]
        _ = mdlMeshes.map
        {
            mdlMesh in mdlMesh.addTangentBasis(forTextureCoordinateAttributeNamed: MDLVertexAttributeTextureCoordinate,
                                               tangentAttributeNamed: MDLVertexAttributeTangent,
                                               bitangentAttributeNamed: MDLVertexAttributeBitangent)
            Model.vertexDescriptor = mdlMesh.vertexDescriptor
            mtkMeshes.append(try! MTKMesh(mesh: mdlMesh, device: Renderer.device))
        }
        
        meshes = zip(mdlMeshes, mtkMeshes).map
        {
            Mesh(mdlMesh: $0.0, mtkMesh: $0.1,
                 startTime: asset.startTime,
                 endTime: asset.endTime,
                 vertexFunctionName: vertexFunctionName,
                 fragmentFunctionName: fragmentFunctionName)
        }
        samplerState = Model.buildSamplerState()
        
        // animations
        let assetAnimations = asset.animations.objects.compactMap
        {
            $0 as? MDLPackedJointAnimation
        }
        let animations: [String: AnimationClip] =
            Dictionary(uniqueKeysWithValues: assetAnimations.map
            {
                let name = URL(fileURLWithPath: $0.name).lastPathComponent
                return (name, AnimationComponent.load(animation: $0))
            })
        self.animations = animations
        
        self.instanceCount = transforms.count
        self.transforms = transforms
        instanceBuffer = Model.buildInstanceBuffer(transforms: transforms)
        
        debugBoundingBox = DebugBoundingBox(boundingBox: asset.boundingBox)
        
        super.init()
        self.boundingBox = asset.boundingBox
        self.name = name
    }
    
    func updateBuffer(instance: Int, transform: Transform)
    {
        transforms[instance] = transform
        var pointer = instanceBuffer.contents().bindMemory(to: Instances.self, capacity: transforms.count)
        pointer = pointer.advanced(by: instance)
        pointer.pointee.modelMatrix = transforms[instance].modelMatrix
        pointer.pointee.normalMatrix = transforms[instance].normalMatrix
    }
    
    static func buildInstanceBuffer(transforms: [Transform]) -> MTLBuffer
    {
        let instances = transforms.map
        {
            Instances(modelMatrix: $0.modelMatrix, normalMatrix: float3x3(normalFrom4x4: $0.modelMatrix))
        }
        
        guard let instanceBuffer = Renderer.device.makeBuffer(bytes: instances,
                                                            length: MemoryLayout<Instances>.stride * instances.count)
        else { fatalError("Failed to create instance buffer") }
        return instanceBuffer
    }
    
    private static func buildSamplerState() -> MTLSamplerState?
    {
        let descriptor = MTLSamplerDescriptor()
        descriptor.sAddressMode = .repeat
        descriptor.tAddressMode = .repeat
        descriptor.mipFilter = .linear
        descriptor.maxAnisotropy = 8
        let samplerState = Renderer.device.makeSamplerState(descriptor: descriptor)
        return samplerState
    }
    
    override func update(deltaTime: Float)
    {
        if animationPaused == false
        {
            currentTime += deltaTime
        }

        for mesh in meshes
        {
            if let animationClip = currentAnimation
            {
                mesh.skeleton?.updatePose(animationClip: animationClip, at: currentTime)
                mesh.transform?.currentTransform = .identity()
            }
            else
            {
                if let animationClip = currentAnimation
                {
                    mesh.skeleton?.updatePose(animationClip: animationClip, at: currentTime)
                }
                mesh.transform?.setCurrentTransform(at: currentTime)
            }
        }
    }
}

extension Model: Renderable
{
    func render(renderEncoder: MTLRenderCommandEncoder, submesh: Submesh)
    {
        let mtkSubmesh = submesh.mtkSubmesh
        renderEncoder.drawIndexedPrimitives(type: .triangle,
                                            indexCount: mtkSubmesh.indexCount,
                                            indexType: mtkSubmesh.indexType,
                                            indexBuffer: mtkSubmesh.indexBuffer.buffer,
                                            indexBufferOffset: mtkSubmesh.indexBuffer.offset,
                                            instanceCount: instanceCount)
    }
    
    func render(renderEncoder: MTLRenderCommandEncoder, uniforms vertex: Uniforms,
                fragmentUniforms fragment: FragmentUniforms)
    {
        var uniforms = vertex
        renderEncoder.setVertexBuffer(instanceBuffer, offset: 0, index: Int(BufferIndexInstances.rawValue))
        
        var fragmentUniforms = fragment
        fragmentUniforms.tiling = tiling
        renderEncoder.setFragmentBytes(&fragmentUniforms,
                                       length: MemoryLayout<FragmentUniforms>.stride,
                                       index: Int(BufferIndexFragmentUniforms.rawValue))
        renderEncoder.setFragmentSamplerState(samplerState, index: 0)
        
        for mesh in meshes
        {
            if let paletteBuffer = mesh.skeleton?.jointMatrixPaletteBuffer
            {
                renderEncoder.setVertexBuffer(paletteBuffer, offset: 0, index: 22)
            }
            
            let currentLocalTransform = mesh.transform?.currentTransform ?? .identity()
            uniforms.modelMatrix = worldTransform * currentLocalTransform
        
            uniforms.normalMatrix = uniforms.modelMatrix.upperLeft
            renderEncoder.setVertexBytes(&uniforms,
                                         length: MemoryLayout<Uniforms>.stride,
                                         index: Int(BufferIndexUniforms.rawValue))
            
            for (index, vertexBuffer) in mesh.mtkMesh.vertexBuffers.enumerated()
            {
                renderEncoder.setVertexBuffer(vertexBuffer.buffer, offset: 0, index: index)
            }
            
            for submesh in mesh.submeshes
            {
                renderEncoder.setFragmentTexture(submesh.textures.baseColor, index: Int(BaseColorTexture.rawValue))
                renderEncoder.setFragmentTexture(submesh.textures.normal, index: Int(NormalTexture.rawValue))
                renderEncoder.setFragmentTexture(submesh.textures.roughness, index: Int(RoughnessTexture.rawValue))
                renderEncoder.setFragmentTexture(submesh.textures.metallic, index: Int(MetallicTexture.rawValue))
                renderEncoder.setFragmentTexture(submesh.textures.ao, index: Int(AOTexture.rawValue))
                
                renderEncoder.setRenderPipelineState(submesh.pipelineState)
                var material = submesh.material
                renderEncoder.setFragmentBytes(&material, length: MemoryLayout<Material>.stride, index: Int(BufferIndexMaterials.rawValue))
                render(renderEncoder: renderEncoder, submesh: submesh)
            }
            if debugRenderBoundingBox
            {
                debugBoundingBox.render(renderEncoder: renderEncoder, uniforms: uniforms)
            }
        }
    }
}

extension Model
{
    func runAnimation(name: String)
    {
        currentAnimation = animations[name]
        if currentAnimation != nil
        {
            animationPaused = false
            currentTime = 0
        }
    }
    
    func pauseAnimation()
    {
        animationPaused = true
    }
    
    func resumeAnimation()
    {
        animationPaused = false
    }
    
    func stopAnimation()
    {
        animationPaused = true
        currentAnimation = nil
    }
}
