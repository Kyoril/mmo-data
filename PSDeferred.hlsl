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

struct VertexOut
{
	float4 pos : SV_POSITION;
	float4 color : COLOR;
	float3 worldPos : TEXCOORD0;
	float3 viewDir : TEXCOORD1;
	float3 viewPos : TEXCOORD2;
};

GBufferOutput main(VertexOut input)
{
	float4 outputColor = float4(1, 1, 1, 1);

	float3 V = normalize(input.viewDir);

	float4 expr_0 = float4(1, 0, 0, 1);

	float3 N = float3(0.0, 0.0, 1.0);

	float specular = 0.5;

	float roughness = 1.0;

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_0.rgb;

	if (opacity < 0.333) discard;
	float3 ao = float3(1.0, 1.0, 1.0);

	GBufferOutput output;
	float3 viewPos = mul(float4(input.worldPos, 1.0), matView).xyz;
	float linearDepth = length(viewPos);
	output.viewRay = float4(normalize(input.viewPos), 1.0);
	output.albedo = float4(0.0, 0.0, 0.0, 1.0);
	output.normal = float4(0.5, 0.5, 1.0, linearDepth);
	output.material = float4(metallic, roughness, specular, 1.0);
	output.emissive = float4(baseColor, 0.0);
	return output;
}
