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
	float sScaleTextures;
	float sEdgeContrast;
	float sEdgePower;
	float sNormalPower;
	float sRoughnessEdge;
	float sRoughnessA;
	float sRoughnessB;
	float sRoughnessContrast;
	float sRoughnessPower;
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

	float3 expr_2 = input.worldPos.xyz;

	float expr_3 = sScaleTextures;

	float3 expr_4 = expr_2 / expr_3;

	float2 expr_5 = expr_4.rb;

	float4 expr_6 = texparam0.Sample(paramsampler0, expr_5.xy);

	float3 expr_7 = expr_6.rgb;

	float3 expr_8 = N;

	float3 expr_9 = abs(expr_8);

	float expr_10 = 10.000000;

	float3 expr_11 = pow(expr_9, expr_10);

	float expr_12 = expr_11.r;

	float expr_13 = expr_11.g;

	float expr_14 = expr_12 + expr_13;

	float expr_15 = expr_11.b;

	float expr_16 = expr_14 + expr_15;

	float3 expr_17 = expr_11 / expr_16;

	float expr_18 = expr_17.g;

	float3 expr_19 = expr_7 * expr_18;

	float2 expr_20 = expr_4.rg;

	float4 expr_21 = texparam0.Sample(paramsampler0, expr_20.xy);

	float3 expr_22 = expr_21.rgb;

	float expr_23 = expr_17.b;

	float3 expr_24 = expr_22 * expr_23;

	float3 expr_25 = expr_19 + expr_24;

	float2 expr_26 = expr_4.gb;

	float4 expr_27 = texparam0.Sample(paramsampler0, expr_26.xy);

	float3 expr_28 = expr_27.rgb;

	float expr_29 = expr_17.r;

	float3 expr_30 = expr_28 * expr_29;

	float3 expr_31 = expr_25 + expr_30;

	float expr_32 = expr_31.r;

	float expr_33 = 0.500000;

	float3 expr_34 = 1.0 - expr_31;

	float expr_35 = 2.000000;

	float3 expr_36 = expr_34 * expr_35;

	float4 expr_37 = vHueColor;

	float3 expr_38 = expr_37.rgb;

	float3 expr_39 = 1.0 - expr_38;

	float3 expr_40 = expr_36 * expr_39;

	float3 expr_41 = 1.0 - expr_40;

	float expr_42 = expr_41.r;

	float expr_43 = 2.000000;

	float3 expr_44 = expr_31 * expr_43;

	float3 expr_45 = expr_37.rgb;

	float3 expr_46 = expr_44 * expr_45;

	float expr_47 = expr_46.r;

	float expr_48 = select((expr_32 >= expr_33), expr_42, expr_47);

	float expr_49 = expr_31.g;

	float expr_50 = expr_41.g;

	float expr_51 = expr_46.g;

	float expr_52 = select((expr_49 >= expr_33), expr_50, expr_51);

	float2 expr_53 = float2(expr_48, expr_52);

	float expr_54 = expr_31.b;

	float expr_55 = expr_41.b;

	float expr_56 = expr_46.b;

	float expr_57 = select((expr_54 >= expr_33), expr_55, expr_56);

	float3 expr_58 = float3(expr_53, expr_57);

	float expr_59 = 0.000000;

	float expr_60 = sEdgeContrast;

	float expr_61 = expr_59 - expr_60;

	float expr_62 = 1.000000;

	float expr_63 = expr_60 + expr_62;

	float2 expr_64 = input.uv0;

	float4 expr_65 = (texparam1.Sample(paramsampler1, expr_64.xy) * 2.0 - 1.0);

	float expr_66 = expr_65.b;

	float expr_67 = sEdgePower;

	float expr_68 = pow(expr_66, expr_67);

	float expr_69 = lerp(expr_61, expr_63, expr_68);

	float expr_70 = 0.000000;

	float expr_71 = 1.000000;

	float expr_72 = clamp(expr_69, expr_70, expr_71);

	float expr_73 = expr_72.r;

	float3 expr_74 = lerp(expr_1, expr_58, expr_73);

	float3 expr_75 = expr_65.rgb;

	float3 expr_76 = expr_65.rgb;

	float2 expr_77 = expr_76.rg;

	float3 expr_78 = expr_65.rgb;

	float expr_79 = expr_78.b;

	float expr_80 = 1.000000;

	float expr_81 = expr_79 + expr_80;

	float3 expr_82 = float3(expr_77, expr_81);

	float3 expr_83 = N;

	float expr_84 = expr_83.r;

	float4 expr_85 = (texparam2.Sample(paramsampler2, input.uv0) * 2.0 - 1.0);

	float expr_86 = expr_85.b;

	float expr_87 = expr_84 * expr_86;

	float expr_88 = expr_83.g;

	float expr_89 = expr_85.r;

	float expr_90 = expr_88 + expr_89;

	float2 expr_91 = float2(expr_87, expr_90);

	float expr_92 = expr_83.b;

	float expr_93 = expr_85.g;

	float expr_94 = expr_92 + expr_93;

	float3 expr_95 = float3(expr_91, expr_94);

	float3 expr_96 = expr_95 * expr_18;

	float4 expr_97 = (texparam2.Sample(paramsampler2, input.uv0) * 2.0 - 1.0);

	float expr_98 = expr_97.r;

	float expr_99 = expr_84 + expr_98;

	float expr_100 = expr_97.b;

	float expr_101 = expr_88 * expr_100;

	float2 expr_102 = float2(expr_99, expr_101);

	float expr_103 = expr_97.g;

	float expr_104 = expr_92 + expr_103;

	float3 expr_105 = float3(expr_102, expr_104);

	float3 expr_106 = expr_105 * expr_23;

	float3 expr_107 = expr_96 + expr_106;

	float4 expr_108 = (texparam2.Sample(paramsampler2, input.uv0) * 2.0 - 1.0);

	float expr_109 = expr_108.r;

	float expr_110 = expr_84 + expr_109;

	float expr_111 = expr_108.g;

	float expr_112 = expr_88 + expr_111;

	float2 expr_113 = float2(expr_110, expr_112);

	float expr_114 = expr_108.b;

	float expr_115 = expr_92 * expr_114;

	float3 expr_116 = float3(expr_113, expr_115);

	float3 expr_117 = expr_116 * expr_29;

	float3 expr_118 = expr_107 + expr_117;

	float3 expr_119 = normalize(expr_118);

	float3 expr_120 = mul(TBN, expr_119);

	float4 expr_121 = float4(0, 0, 1, 1);

	float expr_122 = sNormalPower;

	float3 expr_123 = lerp(expr_120, expr_121, expr_122);

	float2 expr_124 = expr_123.rg;

	float expr_125 = -1.000000;

	float2 expr_126 = expr_124 * expr_125;

	float expr_127 = expr_123.b;

	float3 expr_128 = float3(expr_126, expr_127);

	float expr_129 = dot(expr_82, expr_128);

	float3 expr_130 = expr_82 * expr_129;

	float3 expr_131 = expr_81 * expr_128;

	float3 expr_132 = expr_130 - expr_131;

	float3 expr_133 = normalize(expr_132);

	float3 expr_134 = lerp(expr_75, expr_133, expr_73);

	float expr_135 = 0.500000;

	float expr_136 = sRoughnessEdge;

	float expr_137 = sRoughnessA;

	float expr_138 = sRoughnessB;

	float expr_139 = 0.000000;

	float expr_140 = sRoughnessContrast;

	float expr_141 = expr_139 - expr_140;

	float expr_142 = 1.000000;

	float expr_143 = expr_140 + expr_142;

	float expr_144 = expr_31.r;

	float expr_145 = sRoughnessPower;

	float expr_146 = pow(expr_144, expr_145);

	float expr_147 = lerp(expr_141, expr_143, expr_146);

	float expr_148 = 0.000000;

	float expr_149 = 1.000000;

	float expr_150 = clamp(expr_147, expr_148, expr_149);

	float expr_151 = expr_150.r;

	float expr_152 = lerp(expr_137, expr_138, expr_151);

	float expr_153 = lerp(expr_136, expr_152, expr_73);

	N = expr_134;

	N = GetWorldNormal(N, input.normal, input.tangent, input.binormal);
	float specular = saturate(expr_135);

	float roughness = saturate(expr_153);

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_74;

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
