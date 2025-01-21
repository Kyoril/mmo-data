static const float PI = 3.14159265359;

float select(bool expression, float whenTrue, float whenFalse) {
	return expression ? whenTrue : whenFalse;
}

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

// Textures/Stones/T_stone_06_basecolor.htex
Texture2D tex0;
SamplerState sampler0;

// Textures/Stones/T_moss_basecolor.htex
Texture2D tex1;
SamplerState sampler1;

// Textures/Stones/T_stone_06_normal.htex
Texture2D tex2;
SamplerState sampler2;

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
	float4 expr_0 = tex0.Sample(sampler0, input.uv0);

	float3 expr_1 = expr_0.rgb;

	float3 expr_2 = input.worldPos.xyz;

	float expr_3 = 0.940000;

	float expr_4 = abs(expr_3);

	float expr_5 = -1.000000;

	float expr_6 = expr_4 * expr_5;

	float3 expr_7 = expr_2 / expr_6;

	float2 expr_8 = expr_7.rb;

	float4 expr_9 = tex1.Sample(sampler1, expr_8.xy);

	float3 expr_10 = expr_9.rgb;

	float2 expr_11 = expr_7.gb;

	float4 expr_12 = tex1.Sample(sampler1, expr_11.xy);

	float3 expr_13 = expr_12.rgb;

	float3 expr_14 = N;

	float expr_15 = expr_14.r;

	float expr_16 = abs(expr_15);

	float3 expr_17 = lerp(expr_10, expr_13, expr_16);

	float2 expr_18 = expr_7.rg;

	float4 expr_19 = tex1.Sample(sampler1, expr_18.xy);

	float3 expr_20 = expr_19.rgb;

	float expr_21 = expr_14.b;

	float expr_22 = abs(expr_21);

	float3 expr_23 = lerp(expr_17, expr_20, expr_22);

	float3 expr_24 = N;

	float4 expr_25 = float4(0, 1, 0, 1);

	float4 expr_26 = normalize(expr_25);

	float3 expr_27 = dot(expr_24, expr_26);

	float expr_28 = 0.500000;

	float3 expr_29 = expr_27 * expr_28;

	float expr_30 = 0.500000;

	float3 expr_31 = expr_29 + expr_30;

	float expr_32 = 16.820000;

	float3 expr_33 = expr_31 * expr_32;

	float expr_34 = -4.620000;

	float expr_35 = 0.500000;

	float expr_36 = expr_32 * expr_35;

	float expr_37 = expr_34 - expr_36;

	float3 expr_38 = expr_33 + expr_37;

	float expr_39 = 0.000000;

	float expr_40 = 1.000000;

	float3 expr_41 = clamp(expr_38, expr_39, expr_40);

	float3 expr_42 = lerp(expr_1, expr_23, expr_41);

	float2 expr_43 = input.uv0;

	float4 expr_44 = tex2.Sample(sampler2, expr_43.xy);

	float3 expr_45 = expr_44.rgb;

	float expr_46 = 0.076000;

	float expr_47 = 1.000000;

	N = expr_45;

	N = GetWorldNormal(N, input.normal, input.tangent, input.binormal);
	float specular = saturate(expr_46);

	float roughness = saturate(expr_47);

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_42;

	if (opacity < 0.3333) { clip(-1); }
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
	outputColor = float4(color, opacity);
	return outputColor;
}
