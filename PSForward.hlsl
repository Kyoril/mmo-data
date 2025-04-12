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
