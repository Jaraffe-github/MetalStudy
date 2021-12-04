//
//  Submesh.swift
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

import MetalKit

class Submesh
{
    var mtkSubmesh: MTKSubmesh
    
    init(mdlSubmesh: MDLSubmesh, mtkSubmesh: MTKSubmesh)
    {
        self.mtkSubmesh = mtkSubmesh
    }
}
