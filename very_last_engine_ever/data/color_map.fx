string XFile = "misc\\teapot.x";
int BCLR = 0xff202060;

float fade  = 0.75f;
float sobel_fade = 0.5f;

float alpha = 1.f;
float xoffs = 0.f;
float yoffs = 0.f;
float time = 0.0f;

float xzoom = 1.f;
float yzoom = 1.f;

float flash = 0.0f;
float fade2 = 1.0f;

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

float texel_width = 1.f / 800;
float texel_height = 1.f / 450;


float2 bloom_nudge = float2(0.5 / 400, 0.5 / 225);

float4 pixel(VS_OUTPUT In) : COLOR
{
   float2 dist = In.tex;
   
//   float tear = frac((In.tex.y*2 - time) / PI) * PI;
//   float tear = In.tex.y - frac(time / PI) * PI;
   float tear = 0; // tan(In.tex.y - time);
/*   tear += tan(In.tex.y - time * 0.2 + 0.2) * 0.5;
   tear += tan(In.tex.y - time * 0.2) * 0.75;
   tear += tan(In.tex.y - time * 0.2 + PI / 2) * 0.75; */
//   if (abs(tear2) > abs(tear)) tear = tear2;
//   tear = max(tear, tan(i.uv.y - time + 0.2));
    
   float hnoise = 0; // tex2D( noiseMap, i.uv.yy * 0.5 + time * 10 ).r;
   hnoise = (hnoise - 0.5) * 0.75;
   hnoise = hnoise * 0.5 + hnoise * min(abs(tear) * 0.1, 1);
   
   tear += hnoise * 2.5 * tear;
//   tear += tex2D( noiseMap, i.uv.yy + sin(time) * 10 ).r * 0.015 * tear;
   dist.x += 0;tear/40;
//   dist.x += frac(tan(time + sin(i.uv.y + time) * 140)/40) * 0.01;
   
   float na = abs(tear)*0.1;
   
   na = saturate(na);
   na = saturate(na + 0.2);
   
   float blur = max(abs(tear) - 0.5, 0) * 2;
 
   float4 c = tex2Dlod( tex2_sampler, float4(dist, 0, 1.5 + blur) );
   c += tex2Dlod( tex_sampler, float4(dist, 0, 1.5 + blur) );
   float n = 0; // (tex2D( noiseMap, i.uv + time * 8 ).r - 0.05) * 60 * hnoise * hnoise;
   
   float sep = 0.01 + n * 0.005;
   sep = 0.002;
   sep += tear * 0.001;
   
   float4 l = 0;
   float4 r = 0;
   for (int j = 0; j < 2; ++j)
   {
      l += tex2Dlod( tex2_sampler, float4(dist.x - sep, In.tex.y, 0, 4 + j + blur) );
      r += tex2Dlod( tex2_sampler, float4(dist.x + sep, In.tex.y, 0, 4 + j + blur) );
   }
   l /= 3;
   r /= 3;
  
   c = float4(c.ggg + float3(l.r - l.g, 0, r.b - r.g) * 3, 1.0);

   float3 col = normalize(float3(0.3, 0.3, 0.5)) * 3;
   c.rgb = lerp(c.rgb, dot(c, col) * col, 0.25);
   c.rgb *= 1.5-length(In.tex*2-1);

	 float lum = c.g;
	 c.rgb = lerp(float3(0,2,0), float3(1,0,0), smoothstep(0.3, 0.5, lum));
	 c.rgb = lerp(c.rgb, float3(0,0,0.5), smoothstep(0.8, 1.3, lum));
	 c.rgb *= lum;
	 c.rgb += max(lum - 1, 0);
	 c.rgb -= max(lum - 1.5, 0) * 10;
	c.rgb = saturate(c.rgb);
	 c.rgb *= pow(1-frac(time), 2) * 2;
	 c.rgb += pow(1-frac(time), 8) * 2.5;
 
//   c.rgb *= tex2D(rasterMap, (i.uv * viewport) / float2(12, 8) + float2(0.5 / 12, 0.5 / 8));
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
