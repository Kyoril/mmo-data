static const float PI = 3.14159265359;

float select(bool expression, float whenTrue, float whenFalse) {
	return expression ? whenTrue : whenFalse;
}

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

float3 fresnelSchlick(float cosTheta, float3 F0)
{
	return F0 + (1.0 - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);

}

float DistributionGGX(float3 N, float3 H, float roughness)
{
	float a      = roughness*roughness;
	float a2     = a*a;
	float NdotH  = max(dot(N, H), 0.0);
	float NdotH2 = NdotH*NdotH;

	float num   = a2;
	float denom = (NdotH2 * (a2 - 1.0) + 1.0);
	denom = PI * denom * denom;
	return num / denom;
}

float GeometrySchlickGGX(float NdotV, float roughness)
{
	float r = (roughness + 1.0);
	float k = (r*r) / 8.0;
	float denom = NdotV * (1.0 - k) + k;
	return NdotV / denom;
}

float GeometrySmith(float3 N, float3 V, float3 L, float roughness)
{
	float NdotV = max(dot(N, V), 0.0);
	float NdotL = max(dot(N, L), 0.0);
	float ggx2  = GeometrySchlickGGX(NdotV, roughness);
	float ggx1  = GeometrySchlickGGX(NdotL, roughness);
	return ggx1 * ggx2;
}

float4 main(VertexOut input) : SV_Target
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

	if (opacity <= 0.333) discard;
	baseColor = pow(baseColor, 2.2);
	float3 ao = float3(1.0, 1.0, 1.0);

	float3 F0 = 0.04;
	F0 = lerp(F0, baseColor, metallic);

	float3 L = normalize(-float3(0.5, -1.0, 0.5));
	float3 H = normalize(V + L);
	float3 radiance = float3(4.0, 4.0, 4.0);

	float NDF = DistributionGGX(N, H, roughness);
	float G   = GeometrySmith(N, V, L, roughness);
	float3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);
	float3 kS = F;
	float3 kD = 1.0f.xxx - kS;
	kD *= 1.0 - metallic;
	float3 numerator    = NDF * G * F;
	float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001;
	float3 specularity     = numerator / denominator;
	float NdotL = max(dot(N, L), 0.0);
	float3 Lo = (kD * baseColor / PI + specularity) * radiance * NdotL;
	kS = fresnelSchlick(max(dot(N, V), 0.0), F0);
	kD = 1.0f.xxx - kS;
	kD *= 1.0 - metallic;
	float3 irradiance = float3(0.1f, 0.25f, 0.3f);
	float3 diffuse = irradiance * baseColor;
	float3 ambient = (kD * diffuse) * ao;
	float3 color = ambient + Lo;
	color = color / (color + 1.0f.xxx);
	color = pow(color, (1.0f/2.2f).xxx);
	float distance = length(input.worldPos - cameraPos);
	float fogFactor = saturate((distance - fogStart) / (fogEnd - fogStart));
	color = lerp(color, fogColor, fogFactor);
	outputColor = float4(color, opacity);
	return outputColor;
}
