//
//  carScene.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import Foundation
import CoreGraphics

class CarScene: Scene
{
    let ground = Model(name: "ground.obj")
    let car = Model(name: "racing-car.obj")
    let orthoCamera = OrthographicCamera()

    override func setupScene()
    {
        var bodies: [Node] = []
        var oilcan = Model(name: "oilcan.obj")
        oilcan.position = [-9, 0, -6]
        add(node: oilcan)
        bodies.append(oilcan)
        oilcan = Model(name: "oilcan.obj")
        oilcan.position = [13, 0, -4]
        add(node: oilcan)
        bodies.append(oilcan)
        var tree = Model(name: "treefir.obj")
        tree.position = [-7, 0, 3]
        add(node: tree)
        bodies.append(tree)
        tree = Model(name: "treefir.obj")
        tree.position = [5, 0, 2]
        add(node: tree)
        bodies.append(tree)
        inputController.keyboardDelegate = self
        ground.tiling = 32
        add(node: ground)

        camera.position = [0, 1.2, -4]
        add(node: car, parent: camera)
        car.position = [0.35, -1, 0.1]

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
extension CarScene: KeyboardDelegate
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

