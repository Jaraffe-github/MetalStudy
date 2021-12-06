//
//  Node.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

class Node
{
    var name: String = "untitled"
    var position: float3 = [0, 0, 0]
    var rotation: float3 = [0, 0, 0]
    {
        didSet
        {
            let rotationMatrix = float4x4(rotation: rotation)
            quaternion = simd_quatf(rotationMatrix)
        }
    }
    var quaternion = simd_quatf()
    var scale:float3 = [1, 1, 1]

    var modelMatrix: float4x4
    {
        let translateMatrix = float4x4(translation: position)
        let rotateMatrix = float4x4(quaternion)
        let scaleMatrix = float4x4(scaling: scale)
        return translateMatrix * rotateMatrix * scaleMatrix
    }

    var boundingBox = MDLAxisAlignedBoundingBox()
    var size: float3
    {
        return boundingBox.maxBounds - boundingBox.minBounds
    }

    var parent: Node?
    var children: [Node] = []

    func update(deltaTime: Float) {}

    final func add(childNode: Node)
    {
        children.append(childNode)
        childNode.parent = self
    }

    final func remove(childNode: Node)
    {
        for child in childNode.children
        {
            child.parent = self
            children.append(child)
        }
        childNode.children = []
        guard let index = (children.firstIndex { $0 === childNode }) else { return }
        children.remove(at: index)
        childNode.parent = nil
    }

    var worldTransform: float4x4
    {
        if let parent = parent
        {
            return parent.worldTransform * self.modelMatrix
        }
        return modelMatrix
    }

    var forwardVector: float3
    {
        return normalize([sin(rotation.y), 0, cos(rotation.y)])
    }

    var rightVector: float3
    {
        return [forwardVector.z, forwardVector.y, -forwardVector.x]
    }
}

