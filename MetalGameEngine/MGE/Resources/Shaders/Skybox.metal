//
//  Skybox.metal
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/06.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

struct VertexIn
{
  float4 position [[ attribute(0) ]];
};

struct VertexOut
{
  float4 position [[ position ]];
  float3 textureCoordinates;
};

vertex VertexOut vertexSkybox(const VertexIn in [[stage_in]], constant float4x4 &vp [[buffer(1)]] )
{
    VertexOut out;
    out.position = (vp * in.position).xyww;
    out.textureCoordinates = in.position.xyz;
    return out;
}

fragment half4 fragmentSkybox(VertexOut in [[stage_in]], texturecube<half> cubeTexture [[texture(BufferIndexSkybox)]])
{
    constexpr sampler default_sampler(filter::linear);
    half4 color = cubeTexture.sample(default_sampler, in.textureCoordinates);
    return color;
}
