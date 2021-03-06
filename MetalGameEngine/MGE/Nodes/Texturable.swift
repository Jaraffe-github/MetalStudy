//
//  Texturable.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import MetalKit

protocol Texturable {}

extension Texturable
{
    static func loadTexture(imageName: String) throws -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        
        let textureLoaderOption: [MTKTextureLoader.Option: Any] =
        [.origin: MTKTextureLoader.Origin.bottomLeft, .SRGB: false, .generateMipmaps: NSNumber(booleanLiteral: true)]
        let fileExtension = URL(fileURLWithPath: imageName).pathExtension.isEmpty ? "png" : nil
        
        guard let url = Bundle.main.url(forResource: imageName, withExtension: fileExtension)
        else
        {
            let texture = try? textureLoader.newTexture(name: imageName, scaleFactor: 1.0, bundle: Bundle.main, options: nil)
            if texture != nil
            {
                print("loaded: \(imageName) from asset catalog")
            }
            else
            {
                print("Texture not found: \(imageName)")
            }
            return texture
        }
        
        let texture = try textureLoader.newTexture(URL: url, options: textureLoaderOption)
        print("loaded texture: \(url.lastPathComponent)")
        return texture
    }
    
    static func loadTexture(texture: MDLTexture) throws -> MTLTexture?
    {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        let textureLoaderOptions: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.bottomLeft,
                                                                    .SRGB: false,
                                                                    .generateMipmaps: NSNumber(booleanLiteral: true)]
        
        let texture = try? textureLoader.newTexture(texture: texture, options: textureLoaderOptions)
        print("loaded texture from MDLTexture")
        return texture
    }
    
    static func loadCubeTexture(imageName: String) throws -> MTLTexture
    {
        let textureLoader = MTKTextureLoader(device: Renderer.device)
        if let texture = MDLTexture(cubeWithImagesNamed: [imageName])
        {
            let options: [MTKTextureLoader.Option: Any] = [.origin: MTKTextureLoader.Origin.topLeft,
                                                           .SRGB: false,
                                                           .generateMipmaps: NSNumber(booleanLiteral: false)]
            return try textureLoader.newTexture(texture: texture, options: options)
        }
        let texture = try textureLoader.newTexture(name: imageName, scaleFactor: 1.0, bundle: .main)
        return texture
    }
}
