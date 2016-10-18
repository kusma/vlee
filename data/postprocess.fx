const float flash, fade, overlay_alpha;
const float2 noffs, nscale;
const float2 dist_offset;
const float2 viewport;
const float color_map_lerp;
const float bloom_weight[7];
const float block_thresh, line_thresh;
const float flare_amount;
const float distCoeff;
const float overlayGlitch;

texture color_tex;
sampler color_samp = sampler_state {
	Texture = (color_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = BORDER;
	AddressV = BORDER;
	sRGBTexture = FALSE;
};

texture bloom_tex;
sampler bloom_samp = sampler_state {
	Texture = (bloom_tex);
	MipFilter = POINT;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = BORDER;
	AddressV = BORDER;
	sRGBTexture = FALSE;
};

texture flare_tex;
sampler flare_samp = sampler_state {
	Texture = (flare_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = BORDER;
	AddressV = BORDER;
	sRGBTexture = FALSE;
};

texture spectrum_tex;
sampler spectrum_samp = sampler_state {
	Texture = (spectrum_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	sRGBTexture = FALSE;
};
sampler spectrum_samp2 = sampler_state {
	Texture = (spectrum_tex);
	MipFilter = NONE;
	MinFilter = POINT;
	MagFilter = POINT;
	AddressU = WRAP;
	AddressV = WRAP;
	sRGBTexture = FALSE;
};

texture noise_tex;
sampler noise_samp = sampler_state {
	Texture = (noise_tex);
	MipFilter = NONE;
	MinFilter = POINT;
	MagFilter = POINT;
	AddressU = WRAP;
	AddressV = WRAP;
	sRGBTexture = FALSE;
};

texture overlay_tex;
sampler overlay_samp = sampler_state {
	Texture = (overlay_tex);
	MipFilter = LINEAR;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	sRGBTexture = TRUE;
};

texture color_map1_tex;
sampler3D color_map1_samp = sampler_state {
	Texture = (color_map1_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	sRGBTexture = FALSE;
};

texture color_map2_tex;
sampler3D color_map2_samp = sampler_state {
	Texture = (color_map2_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	sRGBTexture = FALSE;
};

texture lensdirt_tex;
sampler2D lensdirt_samp = sampler_state {
	Texture = (lensdirt_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	sRGBTexture = FALSE;
};

texture vignette_tex;
sampler2D vignette_samp = sampler_state {
	Texture = (vignette_tex);
	MipFilter = NONE;
	MinFilter = LINEAR;
	MagFilter = LINEAR;
	AddressU = CLAMP;
	AddressV = CLAMP;
	AddressW = CLAMP;
	sRGBTexture = TRUE;
};

struct VS_OUTPUT {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
	float2 npos : TEXCOORD1;
};

VS_OUTPUT vertex(float4 ipos : POSITION, float2 uv : TEXCOORD0)
{
	VS_OUTPUT Out;
	Out.pos = ipos;
	Out.uv = uv;
	Out.npos = uv * 2 - 1;
	Out.npos.x *= viewport.x / viewport.y;
	return Out;
}

float3 sample_spectrum(sampler2D tex, float2 start, float2 stop, int samples, float lod)
{
	float2 delta = (stop - start) / samples;
	float2 pos = start;
	float3 sum = 0, filter_sum = 0;
	for (int i = 0; i < samples; ++i) {
		float3 sample = tex2Dlod(tex, float4(pos, 0, lod)).rgb;
		float t = (i + 0.5) / samples;
		float3 filter = tex2Dlod(spectrum_samp, float4(t, 0, 0, 0)).rgb;
		sum += sample * filter;
		filter_sum += filter;
		pos += delta;
	}
	return sum / filter_sum;
}

float3 color_correct(float3 color)
{
#if 1
	float3 uvw = pow(color, 1.0 / 2.2) * (31.0 / 32) + 0.5 / 32;
	return lerp(tex3Dlod(color_map1_samp, float4(uvw, 0)).rgb,
	            tex3Dlod(color_map2_samp, float4(uvw, 0)).rgb,
	            color_map_lerp);
#else
	return sqrt(color);
#endif
}

float3 sample_bloom(float2 pos)
{
	float3 bloom = tex2Dlod(bloom_samp, float4(pos, 0, 0)).rgb * bloom_weight[0];
	bloom += tex2Dlod(bloom_samp, float4(pos, 0, 1)).rgb * bloom_weight[1];
	bloom += tex2Dlod(bloom_samp, float4(pos, 0, 2)).rgb * bloom_weight[1];
	bloom += tex2Dlod(bloom_samp, float4(pos, 0, 3)).rgb * bloom_weight[3];
	bloom += tex2Dlod(bloom_samp, float4(pos, 0, 4)).rgb * bloom_weight[4];
	bloom += tex2Dlod(bloom_samp, float4(pos, 0, 5)).rgb * bloom_weight[5];
	bloom += tex2Dlod(bloom_samp, float4(pos, 0, 6)).rgb * bloom_weight[6];
	return bloom;
}

float3 sample_lensflare(float2 pos)
{
	return tex2Dlod(flare_samp, float4(pos, 0, 0)).rgb * flare_amount;
}

float srgb_decode(float v)
{
	if (v <= 0.04045)
		return v / 12.92;
	else
		return pow((v + 0.055) / 1.055, 2.4);
}

float3 posterize(float3 v, int3 levels)
{
	float3 value = v * levels;
	float3 vfract = frac(value);
	float3 vfloor = floor(value);
	float3 fw = fwidth(value) * 0.5;
	return (vfloor + smoothstep(0.5 - fw, 0.5 + fw, vfract)) / levels;
}

float4 pixel(VS_OUTPUT In, float2 vpos : VPOS) : COLOR
{
	float haspect = viewport.x / viewport.y;
	float r2 = dot(In.npos, In.npos);
	float f = (1 + r2 * (2 * distCoeff * sqrt(r2))) / (1 + distCoeff * 4);
	float2 pos = f * (In.uv - 0.5) + 0.5;

	float3 col = tex2Dlod(color_samp, float4(pos, 0, 0)).rgb;

	float dirt = srgb_decode(tex2Dlod(lensdirt_samp, float4(pos, 0, 0)));
	col += sample_bloom(pos) * dirt;
	col += sample_lensflare(pos) * dirt;

	// blend overlay
	float4 o = tex2D(overlay_samp, pos);
	col = lerp(col, o.rgb, o.a * overlay_alpha);

	// apply flashes
	col = col * fade + flash;

	// a tad of noise makes everything look cooler
	col += (tex2D(noise_samp, In.uv * nscale + noffs).r - 0.5) * (1.0 / 3);

	col = posterize(col.ggg, int3(3, 3, 3));

	col *= 1 - tex2Dlod(vignette_samp, float4(pos, 0, 0)).a * 0.5;

	return float4(col, 1);
}

technique postprocess {
	pass P0 {
		VertexShader = compile vs_3_0 vertex();
		PixelShader  = compile ps_3_0 pixel();
		ZEnable = False;
	}
}
