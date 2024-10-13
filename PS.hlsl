static const float PI = 3.14159265359;

float select(bool expression, float whenTrue, float whenFalse) {
	return expression ? whenTrue : whenFalse;
}

cbuffer ScalarParameters
{
	float sScaleUV;
	float sScaleMaskDirt;
	float sIntensityMaskDirt;
	float sDirtContrast;
	float sDirtPower;
	float sRougness;
};

cbuffer VectorParameters
{
	float4 vDirtColor;
	float4 vHueColor;
	float4 vHueMaskDirt;
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

// Textures/T_plaster_Mask.htex
Texture2D tex0;
SamplerState sampler0;

// BaseColor
Texture2D texparam0;
SamplerState paramsampler0;

// Normal
Texture2D texparam1;
SamplerState paramsampler1;

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
	float num   = NdotV;
	float denom = NdotV * (1.0 - k) + k;
	return num / denom;
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
	float4 expr_0 = vDirtColor;

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

	float expr_38 = expr_37.r;

	float expr_39 = 0.500000;

	float3 expr_40 = 1.0 - expr_37;

	float expr_41 = 2.000000;

	float3 expr_42 = expr_40 * expr_41;

	float4 expr_43 = vHueMaskDirt;

	float3 expr_44 = expr_43.rgb;

	float3 expr_45 = 1.0 - expr_44;

	float3 expr_46 = expr_42 * expr_45;

	float3 expr_47 = 1.0 - expr_46;

	float expr_48 = expr_47.r;

	float expr_49 = 2.000000;

	float3 expr_50 = expr_37 * expr_49;

	float3 expr_51 = expr_43.rgb;

	float3 expr_52 = expr_50 * expr_51;

	float expr_53 = expr_52.r;

	float expr_54 = select((expr_38 >= expr_39), expr_48, expr_53);

	float expr_55 = expr_37.g;

	float expr_56 = expr_47.g;

	float expr_57 = expr_52.g;

	float expr_58 = select((expr_55 >= expr_39), expr_56, expr_57);

	float2 expr_59 = float2(expr_54, expr_58);

	float expr_60 = expr_37.b;

	float expr_61 = expr_47.b;

	float expr_62 = expr_52.b;

	float expr_63 = select((expr_60 >= expr_39), expr_61, expr_62);

	float3 expr_64 = float3(expr_59, expr_63);

	float3 expr_65 = input.worldPos.xyz;

	float expr_66 = sScaleMaskDirt;

	float expr_67 = abs(expr_66);

	float expr_68 = -1.000000;

	float expr_69 = expr_67 * expr_68;

	float3 expr_70 = expr_65 / expr_69;

	float2 expr_71 = expr_70.rb;

	float4 expr_72 = tex0.Sample(sampler0, expr_71.xy);

	float3 expr_73 = expr_72.rgb;

	float2 expr_74 = expr_70.gb;

	float4 expr_75 = tex0.Sample(sampler0, expr_74.xy);

	float3 expr_76 = expr_75.rgb;

	float expr_77 = 0.000000;

	float expr_78 = 1.000000;

	float expr_79 = expr_77 - expr_78;

	float expr_80 = 1.000000;

	float expr_81 = expr_78 + expr_80;

	float3 expr_82 = N;

	float expr_83 = expr_82.r;

	float expr_84 = abs(expr_83);

	float expr_85 = lerp(expr_79, expr_81, expr_84);

	float expr_86 = 0.000000;

	float expr_87 = 1.000000;

	float expr_88 = clamp(expr_85, expr_86, expr_87);

	float expr_89 = expr_88.r;

	float3 expr_90 = lerp(expr_73, expr_76, expr_89);

	float2 expr_91 = expr_70.rg;

	float4 expr_92 = tex0.Sample(sampler0, expr_91.xy);

	float3 expr_93 = expr_92.rgb;

	float2 expr_94 = expr_82.rb;

	float2 expr_95 = abs(expr_94);

	float expr_96 = lerp(expr_79, expr_81, expr_95);

	float expr_97 = 0.000000;

	float expr_98 = 1.000000;

	float expr_99 = clamp(expr_96, expr_97, expr_98);

	float expr_100 = expr_99.r;

	float3 expr_101 = lerp(expr_90, expr_93, expr_100);

	float expr_102 = expr_101.r;

	float3 expr_103 = lerp(expr_64, expr_37, expr_102);

	float expr_104 = sIntensityMaskDirt;

	float3 expr_105 = lerp(expr_37, expr_103, expr_104);

	float expr_106 = 0.000000;

	float expr_107 = sDirtContrast;

	float expr_108 = expr_106 - expr_107;

	float expr_109 = 1.000000;

	float expr_110 = expr_107 + expr_109;

	float4 expr_111 = texparam1.Sample(paramsampler1, expr_4.xy);

	float expr_112 = expr_111.b;

	float expr_113 = sDirtPower;

	float expr_114 = pow(expr_112, expr_113);

	float expr_115 = lerp(expr_108, expr_110, expr_114);

	float expr_116 = 0.000000;

	float expr_117 = 1.000000;

	float expr_118 = clamp(expr_115, expr_116, expr_117);

	float expr_119 = expr_118.r;

	float3 expr_120 = lerp(expr_1, expr_105, expr_119);

	float3 expr_121 = expr_111.rgb;

	float expr_122 = expr_5.a;

	float expr_123 = sRougness;

	float expr_124 = expr_122 * expr_123;

	N = expr_121 * 2.0 - 1.0;

	N = normalize(mul(N, TBN));
	float roughness = expr_124;

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_120;

	baseColor = pow(baseColor, 2.2);
	float3 ao = float3(1.0, 1.0, 1.0);

	float3 F0 = 0.04;
	F0 = lerp(F0, baseColor, metallic);

	float3 L = normalize(-float3(1.0, -0.5, 1.0));
	float3 H = normalize(V + L);
	float3 radiance = float3(4.0, 4.0, 4.0);

	float NDF = DistributionGGX(N, H, roughness);
	float G   = GeometrySmith(N, V, L, roughness);
	float3 F = fresnelSchlick(max(dot(H, V), 0.0), F0);
	float3 kS = F;
	float3 kD = float3(1.0, 1.0, 1.0) - kS;
	kD *= 1.0 - metallic;
	float3 numerator    = NDF * G * F;
	float denominator = 4.0 * max(dot(N, V), 0.0) * max(dot(N, L), 0.0)  + 0.0001;
	float3 specular     = numerator / denominator;
	float NdotL = max(dot(N, L), 0.0);
	float3 Lo = (kD * baseColor / PI + specular) * radiance * NdotL;
	kS = fresnelSchlick(max(dot(N, V), 0.0), F0);
	kD = float3(1.0, 1.0, 1.0) - kS;
	kD *= 1.0 - metallic;
	float3 irradiance = float3(0.0, 0.29, 0.58);
	float3 diffuse = irradiance * baseColor;
	float3 ambient = (kD * diffuse) * ao;
	float3 color = ambient + Lo;
	color = color / (color + float3(1.0, 1.0, 1.0));
	color = pow(color, float3(1.0/2.2, 1.0/2.2, 1.0/2.2));
	clip( opacity < 0.01f ? -1:1 );
	outputColor = float4(color, opacity);
	return outputColor;
}
