//
//  Renderable.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import MetalKit

protocol Renderable
{
    var name: String { get }
    func render(renderEncoder: MTLRenderCommandEncoder,
                uniforms: Uniforms,
                fragmentUniforms fragment: FragmentUniforms)
}
