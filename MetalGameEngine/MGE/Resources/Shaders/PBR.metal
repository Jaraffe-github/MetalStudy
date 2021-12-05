//
//  PBR.metal
//  MetalGameEngine
//
//  Created by 최승민 on 2021/12/05.
//

#include <metal_stdlib>
using namespace metal;

#import "Common.h"

constant bool hasColorTexture [[function_constant(0)]];
constant bool hasNormalTextur [[function_constant(1)]];
constant bool hasRoughnessTexture [[function_constant(2)]];
constant bool hasMetallicTexture [[function_constant(3)]];
constant bool hasAOTexture [[function_constant(4)]];

constant float pi = 3.1415926535897932384626433832795;

struct VertexOut
{
    float4 position [[position]];
    float3 worldPosition;
    float3 worldNormal;
    float3 worldTangent;
    float3 worldBitangent;
    float2 uv;
};

struct Lighting
{
    float3 lightDirection;
    float3 viewDirection;
    float3 baseColor;
    float3 normal;
    float metallic;
    float roughness;
    float ambientOcclusion;
    float3 lightColor;
};

float3 render(Lighting lighting);

fragment float4 fragment_mainPBR(VertexOut in [[stage_in]],
                                 constant Light* lights [[buffer(BufferIndexLights)]],
                                 constant Material& material [[buffer(BufferIndexMaterials)]],
                                 sampler textureSampler [[sampler(0)]],
                                 constant FragmentUniforms& fragmentUniforms [[buffer(BufferIndexFragmentUniforms)]],
                                 texture2d<float> baseColorTexture [[texture(0), function_constant(hasColorTexture)]],
                                 texture2d<float> normalTexture [[texture(1), function_constant(hasNormalTextur)]],
                                 texture2d<float> roughnessTexture [[texture(2), function_constant(hasRoughnessTexture)]],
                                 texture2d<float> metallicTexture [[texture(3), function_constant(hasMetallicTexture)]],
                                 texture2d<float> aoTexture [[texture(4), function_constant(hasAOTexture)]])
{
    // base color
    float3 baseColor;
    if (hasColorTexture)
    {
        baseColor = baseColorTexture.sample(textureSampler, in.uv * fragmentUniforms.tiling).rgb;
    }
    else
    {
        baseColor = material.baseColor;
    }
    
    // metallic
    float metallic;
    if (hasMetallicTexture)
    {
        metallic = metallicTexture.sample(textureSampler, in.uv).r;
    }
    else
    {
        metallic = material.metallic;
    }
    
    // roughness
    float roughness;
    if (hasRoughnessTexture)
    {
        roughness = roughnessTexture.sample(textureSampler, in.uv).r;
    }
    else
    {
        roughness = material.roughness;
    }
    
    // ambient occlusion
    float ambientOcclusion;
    if (hasAOTexture)
    {
        ambientOcclusion = aoTexture.sample(textureSampler, in.uv).r;
    }
    else
    {
        ambientOcclusion = 1.0;
    }
    
    // normal map
    float3 normal;
    if (hasNormalTextur)
    {
        float3 normalValue = normalTexture.sample(textureSampler, in.uv * fragmentUniforms.tiling).xyz * 2.0 - 1.0;
        normal = in.worldNormal * normalValue.z + in.worldTangent * normalValue.x + in.worldBitangent * normalValue.y;
    }
    else
    {
        normal = in.worldNormal;
    }
    normal = normalize(normal);
    
    float3 viewDirection = normalize(fragmentUniforms.cameraPosition - in.worldPosition);
    
    Light light = lights[0];
    float3 lightDirection = normalize(light.position);
    lightDirection = light.position;
    
    Lighting lighting;
    lighting.lightDirection = lightDirection;
    lighting.viewDirection = viewDirection;
    lighting.baseColor = baseColor;
    lighting.normal = normal;
    lighting.metallic = metallic;
    lighting.roughness = roughness;
    lighting.ambientOcclusion = ambientOcclusion;
    lighting.lightColor = light.color;
    
    float3 specularOutput = render(lighting);
    
    float dotProduct = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
    float3 diffuseColor = light.color * baseColor * dotProduct * ambientOcclusion;
    diffuseColor *= 1.0 - metallic;
    
    float4 finalColor = float4(specularOutput + diffuseColor, 1.0);
    return finalColor;
}

float3 render(Lighting lighting)
{
    float nDotl = max(0.001, saturate(dot(lighting.normal, lighting.lightDirection)));
    float3 halfVector = normalize(lighting.lightDirection + lighting.viewDirection);
    float nDoth = max(0.001, saturate(dot(lighting.normal, halfVector)));
    float nDotv = max(0.001, saturate(dot(lighting.normal, lighting.viewDirection)));
    float hDotl = max(0.001, saturate(dot(lighting.lightDirection, halfVector)));
    
    float specularRoughness = lighting.roughness * (1.0 - lighting.metallic) + lighting.metallic;
    
    float Ds;
    if (specularRoughness >= 1.0)
    {
        Ds = 1.0 / pi;
    }
    else
    {
        float roughnessSqr = specularRoughness * specularRoughness;
        float d = (nDoth * roughnessSqr - nDoth) * nDoth + 1;
        Ds = roughnessSqr / (pi * d * d);
    }
    
    float3 Cspec0 = float3(1.0);
    float fresnel = pow(clamp(1.0 - hDotl, 0.0, 1.0), 5.0);
    float3 Fs = float3(mix(float3(Cspec0), float3(1), fresnel));
    
    float alphaG = (specularRoughness * 0.5 + 0.5) * (specularRoughness * 0.5 + 0.5);
    float a = alphaG * alphaG;
    float b1 = nDotl * nDotl;
    float b2 = nDotv * nDotv;
    float G1 = (float)(1.0 / (b1 + sqrt(a + b1 - a*b1)));
    float G2 = (float)(1.0 / (b2 + sqrt(a + b2 - a*b2)));
    float Gs = G1 * G2;
    
    float3 specularOutput = (Ds * Gs * Fs * lighting.lightColor) * (1.0 + lighting.metallic * lighting.baseColor) * lighting.metallic * lighting.lightColor * lighting.baseColor;
    specularOutput = specularOutput * lighting.ambientOcclusion;
    return specularOutput;
}
