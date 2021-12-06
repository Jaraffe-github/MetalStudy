//
//  Lighting.swift
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

import Foundation

struct Lighting
{
    let directionalLight: Light =
    {
        var light = Lighting.buildDefaultLight()
        light.position = [3, 2, 0]
        light.type = DirectionalLight
        return light;
    }()
    let lights: [Light];
    let count: UInt32
    
    init()
    {
        lights = [directionalLight]
        count = UInt32(lights.count)
    }
    
    static func buildDefaultLight() -> Light
    {
        var light = Light()
        light.position = [0, 0, 0]
        light.color = [1, 1, 1]
        light.specularColor = [1, 1, 1]
        light.intensity = 0.6
        light.attenuation = float3(1, 0, 0)
        light.type = DirectionalLight
        return light
    }
}
