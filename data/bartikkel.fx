const float3 up;
const float3 left;
const float4x4 matView : VIEW;
const float4x4 matWorldViewProjection : WORLDVIEWPROJECTION;
const float fogDensity;

texture tex;
sampler tex_samp = sampler_state
{
	Texture = (tex);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;

	AddressU = CLAMP;
	AddressV = CLAMP;
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
	float2 tex : TEXCOORD0;
	float  z : TEXCOORD1;
};

VS_OUTPUT vertex(VS_INPUT In)
{
	VS_OUTPUT Out;

	float3 pos = In.pos;
	float eyeDepth = mul(float4(pos, 1), matView).z;

	pos += In.size * (In.uv.x * left + In.uv.y * up);

	Out.pos = mul(float4(pos, 1), matWorldViewProjection);

	Out.z = clamp(exp(-eyeDepth * fogDensity), 0.0, 1.0);

	Out.tex = float2(In.uv.x * 0.5, -In.uv.y * 0.5);
	Out.tex += float2(0.5f, 0.5f);
	return Out;
}

float4 pixel(VS_OUTPUT In) : COLOR
{
	float4 col = tex2D(tex_samp, In.tex);
	return float4(col.rgb, col.a * In.z);
}

technique bartikkel {
	pass P0 {
		VertexShader = compile vs_3_0 vertex();
		PixelShader = compile ps_3_0 pixel();
		AlphaBlendEnable = True;
		ZWriteEnable = False;
		ZEnable = True;
		SrcBlend = SrcAlpha;
		DestBlend = InvSrcAlpha;
	}
}
