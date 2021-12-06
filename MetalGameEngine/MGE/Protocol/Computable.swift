//
//  computable.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/06.
//

import MetalKit

protocol Computable
{
    var name: String { get }
    func compute(computeEncoder: MTLComputeCommandEncoder, uniforms: Uniforms)
}
