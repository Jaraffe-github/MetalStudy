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
} FragmentUniforms;

typedef enum
{
    BufferIndexVertices = 0,
    BufferIndexUniforms = 1,
    BufferIndexLights = 2,
    BufferIndexFragmentUniforms = 3
} BufferIndices;

typedef enum
{
    Position = 0,
    Normal = 1
} Attributes;

#endif /* Common_h */
