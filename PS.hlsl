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

// Models/Trees/T_tree_bark_basecolor.htex
Texture2D tex0;
SamplerState sampler0;

// Models/Trees/T_tree_bark_normal.htex
Texture2D tex1;
SamplerState sampler1;

static const float3 DirectionalLightDirection = normalize(float3(0.5f, -1.0f, 0.5f));
static const float3 DirectionalLightColor = float3(1.0f, 1.0f, 1.0f); // white
static const float3 SkyLightColor = float3(0.2f, 0.25f, 0.3f);        // subtle bluish sky
float3 GetWorldNormal(float3 tangentSpaceNormal, float3 N, float3 T, float3 B)
{
	// tangentSpaceNormal is usually in range [0,1]. Convert to [-1,1]
	float3 n = tangentSpaceNormal * 2.0f - 1.0f;

	// Re-orient using T, B, N. (Assuming T,B,N are all normalized & orthonormal)
	float3 worldNormal = normalize(n.x * T + n.y * B + n.z * N);
	return worldNormal;
}

float3 FresnelSchlick(float cosTheta, float3 F0)
{
	return F0 + (1.0f - F0) * pow(1.0f - cosTheta, 5.0f);
}

float D_GGX(float NdotH, float alpha){	float alpha2 = alpha * alpha;	float denom = (NdotH * NdotH) * (alpha2 - 1.0f) + 1.0f;	return alpha2 / (3.14159f * denom * denom);}

float G_SmithGGX_1(float NdotV, float alpha)
{
	float k = (alpha + 1.0f) * (alpha + 1.0f) / 8.0f;
	return NdotV / (NdotV * (1.0f - k) + k);
}

float G_SmithGGX_1_Correlated(float NdotV, float NdotL, float alpha)
{
	// This is a correlated version, can also be done separately
	float k = (alpha + 1.0f) * (alpha + 1.0f) / 8.0f;
	float gv = NdotV / (NdotV * (1.0f - k) + k);
	float gl = NdotL / (NdotL * (1.0f - k) + k);
	return gv * gl;
}

float3 CookTorranceBRDF(
	float3 N, float3 V, float3 L,
	float3 F0, float roughness)
{
	float alpha = roughness * roughness;

	float3 H = normalize(V + L);

	float NdotL = saturate(dot(N, L));
	float NdotV = saturate(dot(N, V));
	float NdotH = saturate(dot(N, H));
	float VdotH = saturate(dot(V, H));

	// Normal Distribution Function
	float D = D_GGX(NdotH, alpha);

	// Geometry
	float G = G_SmithGGX_1_Correlated(NdotV, NdotL, alpha);

	// Fresnel
	float3 F = FresnelSchlick(VdotH, F0);

	// Cook-Torrance denominator factor
	float denominator = 4.0f * NdotV * NdotL + 0.0001f;

	// Final specular
	float3 specular = (D * G * F) / denominator;

	return specular;
}float3 DiffuseLambert(float3 albedo){	return albedo / 3.14159f;}float4 main(VertexOut input) : SV_Target
{
	float4 outputColor = float4(1, 1, 1, 1);

	float3 N = input.normal;

	float3 V = normalize(input.viewDir);

	float3 B = input.binormal;
	float3 T = input.tangent;
	float3x3 TBN = float3x3(T, B, N);
	////////////////////////////////////////////////////////////
	// BEGIN - MATERIAL COMPILER EXPRESSIONS
	////////////////////////////////////////////////////////////
	float2 expr_0 = input.uv0;

	float4 expr_1 = tex0.Sample(sampler0, expr_0.xy);

	float3 expr_2 = expr_1.rgb;

	float4 expr_3 = tex1.Sample(sampler1, expr_0.xy);

	float3 expr_4 = expr_3.rgb;

	float expr_5 = 0.900000;


	////////////////////////////////////////////////////////////
	// END - MATERIAL COMPILER EXPRESSIONS
	////////////////////////////////////////////////////////////

	N = expr_4;

	N = GetWorldNormal(N, input.normal, input.tangent, input.binormal);
	float specular = 0.5;

	float roughness = saturate(expr_5);

	float metallic = 0.0;

	float opacity = 1.0;

	clip(opacity < 0.33333f ? -1:1);
	float3 baseColor = float3(1.0, 1.0, 1.0);

	baseColor = expr_2;

	baseColor = pow(baseColor, 1.0/2.2);
	float3 ao = float3(1.0, 1.0, 1.0);

	float3 skyColor = float3(0.5, 0.55, 0.7);
	float3 groundColor = float3(0.1, 0.15, 0.1);
	float NdotUp = saturate(dot(N, float3(0, 1, 0)));
	float3 diffuseIBL = lerp(groundColor, skyColor, NdotUp);

	// Compute the reflectance at normal incidence (F0).
	// For metals, F0 is baseColor; for dielectrics, it's 'specular' (e.g. 0.04 or user input).
	float3 F0 = lerp(specular.xxx, baseColor, metallic);

    // Directional light direction
    float3 L = normalize(-DirectionalLightDirection); // negative if direction is 'to the surface'
    float3 H = normalize(L + V);

    // Dot products
    float NdotL = saturate(dot(N, L));
    float NdotV = saturate(dot(N, V));

    // Cook-Torrance specular
    float3 specularTerm = CookTorranceBRDF(N, V, L, F0, 1.0 - roughness);

    // Diffuse (Lambert). For metals, we reduce the diffuse contribution.
    float3 diffuseColor = lerp(baseColor, 0.0f.xxx, metallic);
    float3 diffuseTerm  = DiffuseLambert(diffuseColor);

    // Direct lighting from directional light
    float3 directLighting = (diffuseTerm + specularTerm) * NdotL * DirectionalLightColor;
	float3 diffuseIblContribution = diffuseIBL * diffuseColor;
	float3 ambient = SkyLightColor * diffuseColor;
	float3 color = directLighting + diffuseIblContribution;

	outputColor = float4(color, opacity);
	return outputColor;
}
