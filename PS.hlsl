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

// BaseColor
Texture2D texparam0;
SamplerState paramsampler0;

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
	float2 expr_0 = input.uv0;

	float4 expr_1 = texparam0.Sample(paramsampler0, expr_0.xy);

	float3 expr_2 = expr_1.rgb;

	float roughness = 1.0;

	float metallic = 0.0;

	float opacity = 1.0;

	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_2;

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