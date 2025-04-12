// Copyright (C) 2019 - 2025, Kyoril. All rights reserved.

// Input structure from the vertex shader
struct PS_INPUT
{
    float4 Position : SV_POSITION;
    float4 Color : COLOR0;
    float3 Normal : NORMAL0;
    float2 TexCoord : TEXCOORD0;
    float3 WorldPos : TEXCOORD1;
};

// Output structure for the G-Buffer
struct PS_OUTPUT
{
    float4 Albedo : SV_Target0;    // RGB: Albedo, A: Opacity
    float4 Normal : SV_Target1;    // RGB: Normal, A: Unused
    float4 Material : SV_Target2;  // R: Metallic, G: Roughness, B: Specular, A: Ambient Occlusion
    float4 Emissive : SV_Target3;  // RGB: Emissive, A: Unused
};

// Texture samplers
Texture2D DiffuseTexture : register(t0);
SamplerState DiffuseSampler : register(s0);

// Material parameters
cbuffer MaterialParams : register(b0)
{
    float Metallic;
    float Roughness;
    float Specular;
    float AmbientOcclusion;
    float3 EmissiveColor;
    float EmissiveIntensity;
}

PS_OUTPUT main(PS_INPUT input)
{
    PS_OUTPUT output;
    
    // Sample the diffuse texture
    float4 diffuseColor = DiffuseTexture.Sample(DiffuseSampler, input.TexCoord);
    
    // Combine with vertex color
    float4 albedo = diffuseColor * input.Color;
    
    // Normalize the normal
    float3 normal = normalize(input.Normal);
    
    // Transform normal from [-1, 1] to [0, 1] for storage
    float3 packedNormal = normal * 0.5f + 0.5f;
    
    // Output to G-Buffer
    output.Albedo = albedo;
    output.Normal = float4(packedNormal, 1.0f);
    output.Material = float4(Metallic, Roughness, Specular, AmbientOcclusion);
    output.Emissive = float4(EmissiveColor * EmissiveIntensity, 1.0f);
    
    return output;
}
