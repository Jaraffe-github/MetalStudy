//
//  carScene.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import Foundation
import CoreGraphics

class TestScene: Scene
{
    let car = Model(name: "racing-car.obj", fragmentFunctionName: "fragment_IBL")
    let car2 = Model(name: "racing-car.obj", fragmentFunctionName: "skyboxTest")
    let orthoCamera = OrthographicCamera()

    override func setupScene()
    {
        skybox = Skybox(textureName: "red-sky")
        landscape = Landscape(name: "landscape")
        landscape?.scale = [10, 10, 10]
        
        var bodies: [Node] = []
        
        var oilcan = Model(name: "oilcan.obj")
        oilcan.position = [-9, 0, -6]
        add(node: oilcan)
        bodies.append(oilcan)
        
        oilcan = Model(name: "oilcan.obj")
        oilcan.position = [13, 0, -4]
        add(node: oilcan)
        bodies.append(oilcan)
        
        var treeTransforms: [Transform] = []
        treeTransforms.append(Transform(position: [3, 0, 3]))
        treeTransforms.append(Transform(position: [5, 0, 2]))
        treeTransforms.append(Transform(position: [7, 0, 2]))
        treeTransforms.append(Transform(position: [9, 0, 2]))
        treeTransforms.append(Transform(position: [11, 0, 2]))
        
        var tree = Model(name: "treefir.obj", transforms: treeTransforms)
        add(node: tree)
        bodies.append(tree)
        
        inputController.keyboardDelegate = self

        camera.position = [0, 1.2, -4]
        add(node: car)
        car.position = [-10, -1, 0.1]
        
        add(node: car2)
        car2.position = [-15, -1, 0.1]

        inputController.translationSpeed = 10.0
        inputController.player = camera

        orthoCamera.position = [0, 2, 0]
        orthoCamera.rotation.x = .pi / 2
        cameras.append(orthoCamera)

        physicsController.dynamicBody = car
        for body in bodies
        {
            physicsController.addStaticBody(node: body)
        }
        physicsController.holdAllCollided = true
    }

    override func updateCollidedPlayer() -> Bool
    {
        for body in physicsController.collidedBodies
        {
            if body.name == "oilcan.obj"
            {
                print("power-up")
                remove(node: body)
                physicsController.removeBody(node: body)
                return true
            }
        }
        return false
    }

    override func sceneSizeWillChange(to size: CGSize)
    {
        super.sceneSizeWillChange(to: size)
        let cameraSize: Float = 10
        let ratio = Float(sceneSize.width / sceneSize.height)
        let rect = Rectangle(left: -cameraSize * ratio,
                             right: cameraSize * ratio,
                             top: cameraSize, bottom: -cameraSize)
        orthoCamera.rect = rect
    }

}

#if os(macOS)
extension TestScene: KeyboardDelegate
{
    func keyPressed(key: KeyboardControl, state: InputState) -> Bool
    {
        switch key
        {
        case .key0:
          currentCameraIndex = 0
        case .key1:
          currentCameraIndex = 1
        default:
          break
        }
        return true
    }
}
#endif

