string XFile = "misc\\teapot.x";
int BCLR = 0xff202060;

float fade = 1.0f;
float blinky = 1.0f;
float time = 0.0f;

// textures
texture tex;
texture color_map;

sampler tex_sampler = sampler_state
{
	Texture = (tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	
	AddressU = CLAMP;
	AddressV = CLAMP;
};

texture noise;
sampler noise_sampler = sampler_state
{
	Texture = (noise);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	
	AddressU = WRAP;
	AddressV = WRAP;
};


texture tex2;
sampler tex2_sampler = sampler_state
{
	Texture = (tex2);
	MipFilter = NONE;
	MinFilter = POINT;
	MagFilter = POINT;
	
	AddressU = CLAMP;
	AddressV = CLAMP;
};

texture desaturate;
sampler desaturate_sampler = sampler_state
{
	Texture = (desaturate);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	
	AddressU = CLAMP;
	AddressV = CLAMP;
};


sampler color_map_sampler = sampler_state
{
	Texture = (color_map);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	
	AddressU = CLAMP;
	AddressV = CLAMP;
};

struct VS_OUTPUT
{
	float4 pos  : POSITION;
	float2 tex  : TEXCOORD1;
};

VS_OUTPUT vertex(float4 ipos : POSITION, float2 tex  : TEXCOORD0)
{
	VS_OUTPUT Out;
	Out.pos = ipos;
	Out.tex = tex;
	return Out;
}

float luminance(float3 color)
{
	return dot(color, float3(0.299, 0.587, 0.114));
}

float4 pixel(VS_OUTPUT In) : COLOR
{
	float4 c = tex2Dlod(tex2_sampler, float4(In.tex, 0, 0));
//	c += tex2Dlod(noise_sampler, float4(In.tex * 10, 0, 0)) * 0.25;
	float3 col = normalize(float3(0.3, 0.3, 0.5)) * 3;
	c.rgb = lerp(c.rgb, dot(c.rgb, col) * col.rgb, 0.25);
	c.rgb *= 1.5-length(In.tex*2-1);

	float lum = luminance(c.rgb);

#if 0
	float3 c0 = float3(0, 2, 2);
	float3 c1 = float3(1, 0, 1);
	float3 c2 = float3(0.5, 0.5, 0);
#else
	float3 c0 = float3(0,2,0);
	float3 c1 = float3(1,0,0);
	float3 c2 = float3(0,0,0.5);
#endif


	c.rgb = lerp(c0, c1, smoothstep(0.35, 0.45, lum));
	c.rgb = lerp(c.rgb, c2, smoothstep(0.9, 1.1, lum));
	c.rgb *= lum;
	c.rgb += max(lum - 1, 0);
	c.rgb -= max(lum - 1.5, 0) * 10;
	c.rgb = saturate(c.rgb);
	float3 old = c.rgb;
	c.rgb *= pow(1-frac(time), 2) * 2;
	c.rgb += pow(1-frac(time), 8) * 2.5;
	c.rgb = lerp(old, c.rgb, blinky);
	c.rgb = saturate(c.rgb);
	c.rgb *= fade;

//	float pal_sel = tex2D(desaturate_sampler, In.tex).r;
//	c.rgb = lerp(c, luminance(c.rgb).rrr * float3(0.5, 0.5, 1.0), 1 - pal_sel);

	return c;
}

technique blur_ps_vs_2_0
{
	pass P0
	{
		VertexShader = compile vs_3_0 vertex();
		PixelShader  = compile ps_3_0 pixel();
	}
}
