//
//  Common.h
//  MGE
//
//  Created by 최승민 on 2021/12/04.
//

#ifndef Common_h
#define Common_h

#import <simd/simd.h>

typedef struct
{
    matrix_float4x4 modelMatrix;
    matrix_float4x4 viewMatrix;
    matrix_float4x4 projectionMatrix;
    matrix_float3x3 normalMatrix;
} Uniforms;

typedef enum
{
    None = 0,
    DirectionalLight = 1,
    SpotLight = 2,
    PointLight = 3,
    AmbientLight = 4
} LightType;

typedef struct
{
    vector_float3 position;
    vector_float3 color;
    vector_float3 specularColor;
    float intensity;
    vector_float3 attenuation;
    LightType type;
    float coneAngle;
    vector_float3 coneDirection;
    float coneAttenuation;
} Light;

typedef struct
{
    uint lightCount;
    vector_float3 cameraPosition;
    uint tiling;
} FragmentUniforms;

typedef enum
{
    Position = 0,
    Normal = 1,
    UV = 2,
    Tangent = 3,
    Bitangent = 4,
    Color = 5,
    Joints = 6,
    Weights = 7
} Attributes;

typedef enum
{
    BaseColorTexture = 0,
    NormalTexture = 1,
    RoughnessTexture = 2,
    MetallicTexture = 3,
    AOTexture = 4
} Textures;

typedef enum
{
    BufferIndexVertices = 0,
    BufferIndexUniforms = 11,
    BufferIndexLights = 12,
    BufferIndexFragmentUniforms = 13,
    BufferIndexMaterials = 14,
    BufferIndexInstances = 15,
    BufferIndexSkybox = 20,
    BufferIndexSkyboxDiffuse = 21,
    BufferIndexBRDFLut = 22
} BufferIndices;

typedef struct
{
    vector_float3 baseColor;
    vector_float3 specularColor;
    float roughness;
    float metallic;
    vector_float3 ambientOcclusion;
    float shininess;
} Material;

typedef struct
{
    vector_float2 size;
    float height;
    uint maxTessellation;
} Terrain;

struct Instances
{
    matrix_float4x4 modelMatrix;
    matrix_float3x3 normalMatrix;
};

#endif /* Common_h */
