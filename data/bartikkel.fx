const float3 up;
const float3 left;
const float4x4 matView : VIEW;
const float4x4 matWorldViewProjection : WORLDVIEWPROJECTION;
const float fogDensity;
const float focal_distance, coc_scale;
const float2 viewport;

texture tex;
sampler tex_samp = sampler_state
{
	Texture = (tex);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	sRGBTexture = True;

	AddressU = BORDER;
	AddressV = BORDER;
	AddressW = CLAMP;
};

struct VS_INPUT {
	float3 pos   : POSITION;
	float  size  : TEXCOORD0;
	float3 color : TEXCOORD1;
	float2 uv    : TEXCOORD2;
};

struct VS_OUTPUT
{
	float4 pos : POSITION;
	float3 tex : TEXCOORD0;
	float  z : TEXCOORD1;
};

float coc(float z)
{
	return coc_scale * ((z - focal_distance) / z);
}

VS_OUTPUT vertex(VS_INPUT In)
{
	VS_OUTPUT Out;

	float3 pos = In.pos;
	float eyeDepth = mul(float4(pos, 1), matView).z;
	float4 screenPos = mul(float4(pos, 1), matWorldViewProjection);

	pos += In.size * (In.uv.x * left + In.uv.y * up);

	Out.pos = mul(float4(pos, 1), matWorldViewProjection);

	Out.z = clamp(exp(-eyeDepth * fogDensity), 0.0, 1.0);

	float2 uv = float2(In.uv.x * 0.5, -In.uv.y * 0.5) + float2(0.5f, 0.5f);
	float size = abs(coc(eyeDepth));
	size += distance(screenPos.xy / screenPos.w, 0.0) * 0.0125 * 0.1;
	size = clamp(size * viewport.y, 2, 150);
	size *= screenPos.w;
	float slice = log2(size) / log2(81);
	slice = clamp(slice, 1.0 / 10, 1 - 1.0 / 10);
	Out.tex = float3(uv, slice);
	return Out;
}

float4 pixel(VS_OUTPUT In) : COLOR
{
	return tex3Dlod(tex_samp, float4(In.tex, 0)) * In.z;
}

technique bartikkel {
	pass P0 {
		VertexShader = compile vs_3_0 vertex();
		PixelShader = compile ps_3_0 pixel();
		AlphaBlendEnable = True;
		ZWriteEnable = False;
		ZEnable = True;
		SrcBlend = One;
		DestBlend = InvSrcAlpha;
	}
}
