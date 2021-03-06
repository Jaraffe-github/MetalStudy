import MetalKit

protocol Texturable{
    var texture: MTLTexture? { get set }
}

extension Texturable{
    func setTexture(device: MTLDevice, imageName: String) -> MTLTexture?{
        var texture: MTLTexture? = nil
        
        if(imageName != ""){
            let textureLoader = MTKTextureLoader(device: device)
            
            let url = Bundle.main.url(forResource: imageName, withExtension: nil)
            
            let origin = NSString(string: MTKTextureLoader.Origin.bottomLeft.rawValue)
            let options = [MTKTextureLoader.Option.origin: origin]
            
            do{
                texture = try textureLoader.newTexture(URL: url!, options: options)
            }catch let error as NSError{
                print(error)
            }
        }
        
        return texture
    }
}
