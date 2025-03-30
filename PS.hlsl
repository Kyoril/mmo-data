static const float PI = 3.14159265359;

float select(bool expression, float whenTrue, float whenFalse) {
	return expression ? whenTrue : whenFalse;
}

cbuffer ScalarParameters
{
	float sTiling01;
	float sTiling02;
	float sTiling03;
	float sTiling04;
	float sDefaultRoughness;
	float sStrength01;
	float sStrength02;
	float sStrength03;
	float sStrength04;
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

// Albedo01
Texture2D texparam0;
SamplerState paramsampler0;

// Splatting
Texture2D texparam1;
SamplerState paramsampler1;

// Albedo02
Texture2D texparam2;
SamplerState paramsampler2;

// Albedo03
Texture2D texparam3;
SamplerState paramsampler3;

// Albedo04
Texture2D texparam4;
SamplerState paramsampler4;

// Normal01
Texture2D texparam5;
SamplerState paramsampler5;

// Normal02
Texture2D texparam6;
SamplerState paramsampler6;

// Normal03
Texture2D texparam7;
SamplerState paramsampler7;

// Normal04
Texture2D texparam8;
SamplerState paramsampler8;

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
	float4 expr_0 = input.color;

	float3 expr_1 = expr_0.rgb;

	float3 expr_2 = input.worldPos.xyz;

	float2 expr_3 = expr_2.rb;

	float expr_4 = sTiling01;

	float2 expr_5 = expr_3 / expr_4;

	float4 expr_6 = texparam0.Sample(paramsampler0, expr_5.xy);

	float3 expr_7 = expr_6.rgb;

	float2 expr_8 = input.uv0;

	float4 expr_9 = texparam1.Sample(paramsampler1, expr_8.xy);

	float3 expr_10 = expr_9.rgb;

	float expr_11 = expr_10.r;

	float3 expr_12 = expr_9.rgb;

	float expr_13 = expr_12.g;

	float expr_14 = expr_11 + expr_13;

	float3 expr_15 = expr_9.rgb;

	float expr_16 = expr_15.b;

	float expr_17 = expr_14 + expr_16;

	float expr_18 = expr_9.a;

	float expr_19 = expr_17 + expr_18;

	float4 expr_20 = expr_9 / expr_19;

	float expr_21 = expr_20.r;

	float3 expr_22 = expr_7 * expr_21;

	float3 expr_23 = input.worldPos.xyz;

	float2 expr_24 = expr_23.rb;

	float expr_25 = sTiling02;

	float2 expr_26 = expr_24 / expr_25;

	float4 expr_27 = texparam2.Sample(paramsampler2, expr_26.xy);

	float3 expr_28 = expr_27.rgb;

	float expr_29 = expr_20.g;

	float3 expr_30 = expr_28 * expr_29;

	float3 expr_31 = expr_22 + expr_30;

	float3 expr_32 = input.worldPos.xyz;

	float2 expr_33 = expr_32.rb;

	float expr_34 = sTiling03;

	float2 expr_35 = expr_33 / expr_34;

	float4 expr_36 = texparam3.Sample(paramsampler3, expr_35.xy);

	float3 expr_37 = expr_36.rgb;

	float expr_38 = expr_20.b;

	float3 expr_39 = expr_37 * expr_38;

	float3 expr_40 = expr_31 + expr_39;

	float3 expr_41 = input.worldPos.xyz;

	float2 expr_42 = expr_41.rb;

	float expr_43 = sTiling04;

	float2 expr_44 = expr_42 / expr_43;

	float4 expr_45 = texparam4.Sample(paramsampler4, expr_44.xy);

	float3 expr_46 = expr_45.rgb;

	float expr_47 = expr_20.a;

	float3 expr_48 = expr_46 * expr_47;

	float3 expr_49 = expr_40 + expr_48;

	float3 expr_50 = expr_1 * expr_49;

	float expr_51 = 0.500000;

	float4 expr_52 = texparam5.Sample(paramsampler5, expr_5.xy);

	float3 expr_53 = expr_52.rgb;

	float expr_54 = 2.000000;

	float3 expr_55 = expr_53 * expr_54;

	float expr_56 = 1.000000;

	float3 expr_57 = expr_55 - expr_56;

	float3 expr_58 = expr_57 * expr_21;

	float4 expr_59 = texparam6.Sample(paramsampler6, expr_26.xy);

	float3 expr_60 = expr_59.rgb;

	float expr_61 = 2.000000;

	float3 expr_62 = expr_60 * expr_61;

	float expr_63 = 1.000000;

	float3 expr_64 = expr_62 - expr_63;

	float3 expr_65 = expr_64 * expr_29;

	float3 expr_66 = expr_58 + expr_65;

	float4 expr_67 = texparam7.Sample(paramsampler7, expr_35.xy);

	float3 expr_68 = expr_67.rgb;

	float expr_69 = 2.000000;

	float3 expr_70 = expr_68 * expr_69;

	float expr_71 = 1.000000;

	float3 expr_72 = expr_70 - expr_71;

	float3 expr_73 = expr_72 * expr_38;

	float3 expr_74 = expr_66 + expr_73;

	float4 expr_75 = texparam8.Sample(paramsampler8, expr_44.xy);

	float3 expr_76 = expr_75.rgb;

	float expr_77 = 2.000000;

	float3 expr_78 = expr_76 * expr_77;

	float expr_79 = 1.000000;

	float3 expr_80 = expr_78 - expr_79;

	float3 expr_81 = expr_80 * expr_47;

	float3 expr_82 = expr_74 + expr_81;

	float3 expr_83 = normalize(expr_82);

	float3 expr_84 = expr_51 * expr_83;

	float expr_85 = 0.500000;

	float3 expr_86 = expr_84 + expr_85;

	float expr_87 = 0.500000;

	float expr_88 = sDefaultRoughness;

	float expr_89 = expr_6.a;

	float expr_90 = sStrength01;

	float expr_91 = expr_90 * expr_11;

	float expr_92 = 0.000000;

	float expr_93 = 1.000000;

	float expr_94 = clamp(expr_91, expr_92, expr_93);

	float expr_95 = lerp(expr_88, expr_89, expr_94);

	float expr_96 = expr_27.a;

	float expr_97 = sStrength02;

	float expr_98 = expr_97 * expr_13;

	float expr_99 = 0.000000;

	float expr_100 = 1.000000;

	float expr_101 = clamp(expr_98, expr_99, expr_100);

	float expr_102 = lerp(expr_95, expr_96, expr_101);

	float expr_103 = expr_36.a;

	float expr_104 = sStrength03;

	float expr_105 = expr_104 * expr_16;

	float expr_106 = 0.000000;

	float expr_107 = 1.000000;

	float expr_108 = clamp(expr_105, expr_106, expr_107);

	float expr_109 = lerp(expr_102, expr_103, expr_108);

	float expr_110 = expr_45.a;

	float expr_111 = sStrength04;

	float expr_112 = expr_9.a;

	float expr_113 = expr_111 * expr_112;

	float expr_114 = 0.000000;

	float expr_115 = 1.000000;

	float expr_116 = clamp(expr_113, expr_114, expr_115);

	float expr_117 = lerp(expr_109, expr_110, expr_116);

	float expr_118 = 0.000000;

	N = expr_86;

	N = GetWorldNormal(N, input.normal, input.tangent, input.binormal);
	float specular = saturate(expr_87);

	float roughness = saturate(expr_117);

	float metallic = saturate(expr_118);

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_50;

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
	outputColor = float4(color, opacity);
	return outputColor;
}
