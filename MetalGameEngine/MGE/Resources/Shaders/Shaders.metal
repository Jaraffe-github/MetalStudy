//
//  Shaders.metal
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

#include <metal_stdlib>
using namespace metal;
#import "Common.h"

constant bool hasSkeleton [[function_constant(5)]];

struct VertexIn
{
    float4 position [[attribute(Position)]];
    float3 normal [[attribute(Normal)]];
    float2 uv [[attribute(UV)]];
    float3 tangent [[attribute(Tangent)]];
    float3 bitangent [[attribute(Bitangent)]];
    ushort4 joints [[attribute(Joints)]];
    float4 weights [[attribute(Weights)]];
};

struct VertexOut
{
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float3 worldTangent;
    float3 worldBitangent;
    float2 uv;
};

vertex VertexOut vertex_main(const VertexIn vertexIn [[ stage_in ]],
                             constant float4x4* jointMatrices [[buffer(22), function_constant(hasSkeleton)]],
                             constant Uniforms& uniforms [[ buffer(BufferIndexUniforms) ]])
{
    float4 position = vertexIn.position;
    float4 normal = float4(vertexIn.normal, 0);
    float4 tangent = float4(vertexIn.tangent, 0);
    float4 bitangent = float4(vertexIn.bitangent, 0);
    
    if (hasSkeleton)
    {
        float4 weights = vertexIn.weights;
        ushort4 joints = vertexIn.joints;
        position = weights.x * (jointMatrices[joints.x] * position) +
                   weights.y * (jointMatrices[joints.y] * position) +
                   weights.z * (jointMatrices[joints.z] * position) +
                   weights.w * (jointMatrices[joints.w] * position);
        normal = weights.x * (jointMatrices[joints.x] * normal) +
                 weights.y * (jointMatrices[joints.y] * normal) +
                 weights.z * (jointMatrices[joints.z] * normal) +
                 weights.w * (jointMatrices[joints.w] * normal);
        tangent = weights.x * (jointMatrices[joints.x] * tangent) +
                  weights.y * (jointMatrices[joints.y] * tangent) +
                  weights.z * (jointMatrices[joints.z] * tangent) +
                  weights.w * (jointMatrices[joints.w] * tangent);
        bitangent = weights.x * (jointMatrices[joints.x] * bitangent) +
                    weights.y * (jointMatrices[joints.y] * bitangent) +
                    weights.z * (jointMatrices[joints.z] * bitangent) +
                    weights.w * (jointMatrices[joints.w] * bitangent);
    }
    
    VertexOut out
    {
        .position = uniforms.projectionMatrix * uniforms.viewMatrix * uniforms.modelMatrix * position,
        .worldPosition = (uniforms.modelMatrix * position).xyz,
        .worldNormal = uniforms.normalMatrix * normal.xyz,
        .worldTangent = uniforms.normalMatrix * tangent.xyz,
        .worldBitangent = uniforms.normalMatrix * bitangent.xyz,
        .uv = vertexIn.uv
    };

    return out;
}
