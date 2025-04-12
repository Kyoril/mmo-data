static const float PI = 3.14159265359;

float select(bool expression, float whenTrue, float whenFalse) {
	return expression ? whenTrue : whenFalse;
}

struct GBufferOutput
{
	float4 albedo : SV_Target0;    // RGB: Albedo, A: Opacity
	float4 normal : SV_Target1;    // RGB: Normal, A: Unused
	float4 material : SV_Target2;  // R: Metallic, G: Roughness, B: Specular, A: Ambient Occlusion
	float4 emissive : SV_Target3;  // RGB: Emissive, A: Unused
};

cbuffer Matrices : register(b0)
{
	column_major matrix matWorld;
	column_major matrix matView;
	column_major matrix matProj;
	column_major matrix matInvView;
};

cbuffer CameraParameters : register(b1)
{
	float3 cameraPos;	// Camera position in world space
	float fogStart;	// Distance of fog start
	float fogEnd;		// Distance of fog end
	float3 fogColor;	// Fog color
	row_major matrix inverseCameraView;	// Inverse view matrix
};

struct VertexOut
{
	float4 pos : SV_POSITION;
	float4 color : COLOR;
	float3 normal : NORMAL;
	float3 binormal : BINORMAL;
	float3 tangent : TANGENT;
	float2 uv0 : TEXCOORD0;
	float3 worldPos : TEXCOORD1;
	float3 viewDir : TEXCOORD2;
};

// Textures/Engine/DefaultGrid/T_Default_Material_Grid_M.htex
Texture2D tex0;
SamplerState sampler0;

// Textures/Engine/DefaultGrid/T_Default_Material_Grid_N.htex
Texture2D tex1;
SamplerState sampler1;

float3 GetWorldNormal(float3 tangentSpaceNormal, float3 N, float3 T, float3 B)
{
	// tangentSpaceNormal is usually in range [0,1]. Convert to [-1,1]
	float3 n = tangentSpaceNormal * 2.0f - 1.0f;

	// Re-orient using T, B, N. (Assuming T,B,N are all normalized & orthonormal)
	float3 worldNormal = normalize(n.x * T + n.y * B + n.z * N);
	return worldNormal;
}

GBufferOutput main(VertexOut input)
{
	float4 outputColor = float4(1, 1, 1, 1);

	float3 N = normalize(input.normal);

	float3 V = normalize(input.viewDir);

	float3 B = normalize(input.binormal);
	float3 T = normalize(input.tangent);
	float3x3 TBN = float3x3(T, B, N);
	float expr_0 = 0.400000;

	float expr_1 = 1.000000;

	float2 expr_2 = input.uv0;

	float expr_3 = 60.000000;

	float2 expr_4 = expr_2 * expr_3;

	float4 expr_5 = tex0.Sample(sampler0, expr_4.xy);

	float expr_6 = expr_5.r;

	float expr_7 = lerp(expr_0, expr_1, expr_6);

	float expr_8 = 1.0 - expr_7;

	float expr_9 = 0.000000;

	float expr_10 = lerp(expr_7, expr_8, expr_9);

	float expr_11 = 0.295000;

	float expr_12 = 0.660000;

	float expr_13 = 0.000000;

	float expr_14 = 0.500000;

	float expr_15 = 0.500000;

	float expr_16 = lerp(expr_13, expr_14, expr_15);

	float expr_17 = lerp(expr_11, expr_12, expr_16);

	float expr_18 = 0.500000;

	float expr_19 = expr_17 * expr_18;

	float expr_20 = expr_10 * expr_19;

	float2 expr_21 = input.uv0;

	float expr_22 = 2.000000;

	float2 expr_23 = expr_21 / expr_22;

	float expr_24 = 0.050000;

	float2 expr_25 = expr_23 / expr_24;

	float4 expr_26 = tex1.Sample(sampler1, expr_25.xy);

	float3 expr_27 = expr_26.rgb;

	float expr_28 = 2.000000;

	float3 expr_29 = expr_27 * expr_28;

	float expr_30 = 1.000000;

	float3 expr_31 = expr_29 - expr_30;

	float4 expr_32 = float4(0.3, 0.3, 1, 1);

	float3 expr_33 = expr_32.rgb;

	float3 expr_34 = expr_31 * expr_33;

	float3 expr_35 = normalize(expr_34);

	float expr_36 = 0.500000;

	float3 expr_37 = expr_35 * expr_36;

	float expr_38 = 0.500000;

	float3 expr_39 = expr_37 + expr_38;

	float4 expr_40 = tex0.Sample(sampler0, expr_23.xy);

	float expr_41 = expr_40.g;

	float expr_42 = 0.100000;

	float2 expr_43 = expr_23 / expr_42;

	float4 expr_44 = tex0.Sample(sampler0, expr_43.xy);

	float expr_45 = expr_44.g;

	float expr_46 = expr_41 + expr_45;

	float expr_47 = expr_46.r;

	float expr_48 = 0.500000;

	float expr_49 = expr_40.g;

	float expr_50 = lerp(expr_47, expr_48, expr_49);

	float expr_51 = 0.700000;

	float expr_52 = 1.000000;

	float expr_53 = expr_44.g;

	float expr_54 = lerp(expr_51, expr_52, expr_53);

	float expr_55 = expr_50 + expr_54;

	float expr_56 = 0.000000;

	float expr_57 = 1.000000;

	float expr_58 = clamp(expr_55, expr_56, expr_57);

	N = expr_39;

	N = GetWorldNormal(N, input.normal, input.tangent, input.binormal);
	float specular = 0.5;

	float roughness = saturate(expr_58);

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_20;

	if (opacity <= 0.333) { clip(-1); }
	float3 ao = float3(1.0, 1.0, 1.0);

	GBufferOutput output;
	float3 viewPos = mul(float4(input.worldPos, 1.0), matView).xyz;
	float linearDepth = -viewPos.z;
	output.albedo = float4(baseColor, opacity);
	output.normal = float4(N * 0.5 + 0.5, linearDepth);
	output.material = float4(metallic, roughness, specular, 1.0);
	output.emissive = float4(0.0, 0.0, 0.0, 0.0);
	return output;
}
