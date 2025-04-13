static const float PI = 3.14159265359;

float select(bool expression, float whenTrue, float whenFalse) {
	return expression ? whenTrue : whenFalse;
}

float Dither8x8(int2 pos)
{
	static const float thresholdMatrix[64] = {
		 0, 48, 12, 60,  3, 51, 15, 12,
		32, 16, 44, 28, 35, 19, 47, 31,
		 8, 44,  4, 30, 11, 22,  7, 55,
		40, 24, 36, 20, 43, 27, 39, 23,
		 2, 32, 14, 62,  1, 49, 13, 61,
		34, 18, 46, 30, 33, 17, 45, 29,
		10, 44,  6, 54,  9, 57,  5, 53,
		42, 26, 38, 22, 41, 25, 37, 21
	};
	int x = pos.x % 8;
	int y = pos.y % 8;
	int index = y * 8 + x;
	return thresholdMatrix[index] / 64.0;
}

struct GBufferOutput
{
	float4 albedo : SV_Target0;    // RGB: Albedo, A: Opacity
	float4 normal : SV_Target1;    // RGB: Normal, A: Depth
	float4 material : SV_Target2;  // R: Metallic, G: Roughness, B: Specular, A: Ambient Occlusion
	float4 emissive : SV_Target3;  // RGB: Emissive, A: Unused
	float4 viewRay : SV_Target4;  // RGB: ViewRay, A: Unused
};

cbuffer Matrices : register(b0)
{
	column_major matrix matWorld;
	column_major matrix matView;
	column_major matrix matProj;
	column_major matrix matInvView;
	column_major matrix matInvProj;
};

cbuffer CameraParameters : register(b1)
{
	float3 cameraPos;	// Camera position in world space
	float fogStart;	// Distance of fog start
	float fogEnd;		// Distance of fog end
	float3 fogColor;	// Fog color
	row_major matrix inverseCameraView;	// Inverse view matrix
};

cbuffer ScalarParameters : register(b2)
{
	float sScaleUV;
	float sEdgeContrast;
	float sEdgePower;
	float sRoughnessEdge;
	float sRoughness;
};

cbuffer VectorParameters : register(b3)
{
	float4 vEdgeColor;
	float4 vHueColor;
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
	float3 viewPos : TEXCOORD3;
};

// BaseColor
Texture2D texparam0;
SamplerState paramsampler0;

// BuildingNormal
Texture2D texparam1;
SamplerState paramsampler1;

// Normal
Texture2D texparam2;
SamplerState paramsampler2;

float3 GetWorldNormal(float3 tangentSpaceNormal, float3 N, float3 T, float3 B)
{
	// tangentSpaceNormal is usually in range [0,1]. Convert to [-1,1]
	float3 n = tangentSpaceNormal /* * 2.0f - 1.0f*/;

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
	float4 expr_0 = vEdgeColor;

	float3 expr_1 = expr_0.rgb;

	float2 expr_2 = input.uv0;

	float expr_3 = sScaleUV;

	float2 expr_4 = expr_2 * expr_3;

	float4 expr_5 = texparam0.Sample(paramsampler0, expr_4.xy);

	float3 expr_6 = expr_5.rgb;

	float expr_7 = expr_6.r;

	float expr_8 = 0.500000;

	float3 expr_9 = expr_5.rgb;

	float3 expr_10 = 1.0 - expr_9;

	float expr_11 = 2.000000;

	float3 expr_12 = expr_10 * expr_11;

	float4 expr_13 = vHueColor;

	float3 expr_14 = expr_13.rgb;

	float3 expr_15 = 1.0 - expr_14;

	float3 expr_16 = expr_12 * expr_15;

	float3 expr_17 = 1.0 - expr_16;

	float expr_18 = expr_17.r;

	float3 expr_19 = expr_5.rgb;

	float expr_20 = 2.000000;

	float3 expr_21 = expr_19 * expr_20;

	float3 expr_22 = expr_13.rgb;

	float3 expr_23 = expr_21 * expr_22;

	float expr_24 = expr_23.r;

	float expr_25 = select((expr_7 >= expr_8), expr_18, expr_24);

	float3 expr_26 = expr_5.rgb;

	float expr_27 = expr_26.g;

	float expr_28 = expr_17.g;

	float expr_29 = expr_23.g;

	float expr_30 = select((expr_27 >= expr_8), expr_28, expr_29);

	float2 expr_31 = float2(expr_25, expr_30);

	float3 expr_32 = expr_5.rgb;

	float expr_33 = expr_32.b;

	float expr_34 = expr_17.b;

	float expr_35 = expr_23.b;

	float expr_36 = select((expr_33 >= expr_8), expr_34, expr_35);

	float3 expr_37 = float3(expr_31, expr_36);

	float expr_38 = 0.000000;

	float expr_39 = sEdgeContrast;

	float expr_40 = expr_38 - expr_39;

	float expr_41 = 1.000000;

	float expr_42 = expr_39 + expr_41;

	float2 expr_43 = input.uv0;

	float4 expr_44 = (texparam1.Sample(paramsampler1, expr_43.xy) * 2.0 - 1.0);

	float expr_45 = expr_44.b;

	float expr_46 = sEdgePower;

	float expr_47 = pow(expr_45, expr_46);

	float expr_48 = lerp(expr_40, expr_42, expr_47);

	float expr_49 = 0.000000;

	float expr_50 = 1.000000;

	float expr_51 = clamp(expr_48, expr_49, expr_50);

	float3 expr_52 = lerp(expr_1, expr_37, expr_51);

	float3 expr_53 = expr_44.rgb;

	float4 expr_54 = (texparam2.Sample(paramsampler2, expr_4.xy) * 2.0 - 1.0);

	float3 expr_55 = expr_54.rgb;

	float3 expr_56 = lerp(expr_53, expr_55, expr_51);

	float expr_57 = sRoughnessEdge;

	float expr_58 = expr_5.a;

	float expr_59 = sRoughness;

	float expr_60 = expr_58 * expr_59;

	float expr_61 = lerp(expr_57, expr_60, expr_51);

	N = expr_56;

	N = GetWorldNormal(N, input.normal, input.tangent, input.binormal);
	float specular = 0.5;

	float roughness = saturate(expr_61);

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_52;

	if (opacity < 0.333) discard;
	float3 ao = float3(1.0, 1.0, 1.0);

	GBufferOutput output;
	float3 viewPos = mul(float4(input.worldPos, 1.0), matView).xyz;
	float linearDepth = length(viewPos);
	output.viewRay = float4(normalize(input.viewPos), 1.0);
	output.albedo = float4(baseColor, 1.0);
	output.normal = float4(N * 0.5 + 0.5, linearDepth);
	output.material = float4(metallic, roughness, specular, 1.0);
	output.emissive = float4(0.0, 0.0, 0.0, 0.0);
	return output;
}
