//
//  Scene.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import Foundation
import CoreGraphics

class Scene
{
    let inputController = InputController()
    let physicsController = PhysicsController()

    var sceneSize: CGSize
    var cameras = [Camera()]
    var currentCameraIndex = 0
    var camera: Camera
    {
        return cameras[currentCameraIndex]
    }

    init(sceneSize: CGSize)
    {
        self.sceneSize = sceneSize
        setupScene()
        sceneSizeWillChange(to: sceneSize)
    }

    let rootNode = Node()
    var renderables: [Renderable] = []
    var computables: [Computable] = []
    var uniforms = Uniforms()
    var fragmentUniforms = FragmentUniforms()

    func setupScene() {}

    private func updatePlayer(deltaTime: Float)
    {
        guard let node = inputController.player else { return }
        let holdPosition = node.position
        let holdRotation = node.rotation
        inputController.updatePlayer(deltaTime: deltaTime)
        if physicsController.checkCollisions() && !updateCollidedPlayer()
        {
          node.position = holdPosition
          node.rotation = holdRotation
        }
    }

    func updateCollidedPlayer() -> Bool { return false }

    final func update(deltaTime: Float)
    {
        updatePlayer(deltaTime: deltaTime)

        uniforms.projectionMatrix = camera.projectionMatrix
        uniforms.viewMatrix = camera.viewMatrix
        fragmentUniforms.cameraPosition = camera.position

        updateScene(deltaTime: deltaTime)
        update(nodes: rootNode.children, deltaTime: deltaTime)
    }

    private func update(nodes: [Node], deltaTime: Float)
    {
        nodes.forEach
        {
            node in node.update(deltaTime: deltaTime)
            update(nodes: node.children, deltaTime: deltaTime)
        }
    }

    func updateScene(deltaTime: Float) {}

    final func add(node: Node, parent: Node? = nil, render: Bool = true, compute: Bool = true)
    {
        if let parent = parent
        {
            parent.add(childNode: node)
        }
        else
        {
            rootNode.add(childNode: node)
        }
        
        if render == true, let renderable = node as? Renderable
        {
            renderables.append(renderable)
        }
        
        if compute == true, let computable = node as? Computable
        {
            computables.append(computable)
        }
    }

    final func remove(node: Node)
    {
        if let parent = node.parent
        {
          parent.remove(childNode: node)
        }
        else
        {
            for child in node.children
            {
                child.parent = nil
            }
            node.children = []
        }
        if node is Renderable, let index = (renderables.firstIndex { $0 as? Node === node })
        {
            renderables.remove(at: index)
        }
        if node is Computable, let index = (computables.firstIndex { $0 as? Node === node })
        {
            computables.remove(at: index)
        }
    }

    func sceneSizeWillChange(to size: CGSize)
    {
        for camera in cameras
        {
            camera.aspect = Float(size.width / size.height)
        }
        sceneSize = size
    }
}

