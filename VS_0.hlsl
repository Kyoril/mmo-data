struct VertexIn
{
	float4 pos : SV_POSITION;
	float4 color : COLOR;
	float3 normal : NORMAL;
	float3 binormal : BINORMAL;
	float3 tangent : TANGENT;
	float2 uv0 : TEXCOORD0;
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

cbuffer Matrices
{
	column_major matrix matWorld;
	column_major matrix matView;
	column_major matrix matProj;
	column_major matrix matInvView;
	column_major matrix InverseProjection;
};

VertexOut main(VertexIn input)
{
	VertexOut output;

	float4 transformedPos = float4(input.pos.xyz, 1.0);
	float3 transformedNormal = input.normal;
	float3 transformedBinormal = input.binormal;
	float3 transformedTangent = input.tangent;

	output.pos = mul(transformedPos, matWorld);
	output.worldPos = output.pos.xyz;
	output.viewDir = normalize(matInvView[3].xyz - output.worldPos);
	output.pos = mul(output.pos, matView);
	output.pos = mul(output.pos, matProj);
	output.color = input.color;
	output.uv0 = input.uv0;
	output.binormal = normalize(mul(normalize(transformedBinormal), (float3x3)matWorld));
	output.tangent = normalize(mul(normalize(transformedTangent), (float3x3)matWorld));
	output.normal = normalize(mul(normalize(transformedNormal), (float3x3)matWorld));

	return output;
}

