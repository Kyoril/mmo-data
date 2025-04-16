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

struct VertexOut
{
	float4 pos : SV_POSITION;
	float4 color : COLOR;
	float3 worldPos : TEXCOORD0;
	float3 viewDir : TEXCOORD1;
	float3 viewPos : TEXCOORD2;
};

void main(VertexOut input)
{
}
