//
//  Mesh.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

struct Mesh
{
    let mtkMesh: MTKMesh
    let submeshes: [Submesh]
    
    init(mdlMesh: MDLMesh, mtkMesh: MTKMesh)
    {
        self.mtkMesh = mtkMesh
        submeshes = zip(mdlMesh.submeshes!, mtkMesh.submeshes).map
        {
            mesh in Submesh(mdlSubmesh: mesh.0 as! MDLSubmesh, mtkSubmesh: mesh.1)
        }
    }
}
