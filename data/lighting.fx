const float4x4 matProjectionInverse : PROJECTIONINVERSE;
const float4x4 matView : VIEW;
const float4x4 matViewInverse : VIEWINVERSE;
const float3 fogColor;
const float fogDensity;
const float2 nearFar;

struct VS_OUTPUT {
	float4 pos : POSITION;
	float2 tex : TEXCOORD1;
	float2 dir : TEXCOORD0;
};

VS_OUTPUT vertex(float4 pos : POSITION, float2 tex : TEXCOORD0)
{
	// set up ray
	float4 eyeSpaceNear = mul(float4(pos.xy, 0, 1), matProjectionInverse);
	float4 eyeSpaceFar = mul(float4(pos.xy, 1, 1), matProjectionInverse);
	float3 rayStartEye = eyeSpaceNear.xyz / eyeSpaceNear.w;
	float3 rayTargetEye = eyeSpaceFar.xyz / eyeSpaceFar.w;
	float3 dir = rayTargetEye - rayStartEye;

	VS_OUTPUT o;
	o.pos = pos;
	o.tex = tex;
	o.dir = dir.xy / dir.z;
	return o;
}

texture depth_tex;
sampler depth_samp = sampler_state {
	Texture = (depth_tex);
	MipFilter = NONE;
	MinFilter = POINT;
	MagFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	sRGBTexture = FALSE;
};

texture gbuffer_tex0;
sampler gbuffer_samp0 = sampler_state {
	Texture = (gbuffer_tex0);
	MipFilter = NONE;
	MinFilter = POINT;
	MagFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	sRGBTexture = False;
};

texture gbuffer_tex1;
sampler gbuffer_samp1 = sampler_state {
	Texture = (gbuffer_tex1);
	MipFilter = NONE;
	MinFilter = POINT;
	MagFilter = POINT;
	AddressU = CLAMP;
	AddressV = CLAMP;
	sRGBTexture = True;
};


float4 pixel(VS_OUTPUT In) : COLOR
{
	float2 dir = In.dir;

	float clipDepth = tex2D(depth_samp, In.tex.xy).r;
	float eyeDepth = rcp(clipDepth * nearFar.x + nearFar.y);
	float3 eyePos = float3(dir.xy * eyeDepth, eyeDepth);

	float4 g0 = tex2D(gbuffer_samp0, In.tex.xy);
	float4 g1 = tex2D(gbuffer_samp1, In.tex.xy);

	float3 eyeNormal = g0.rgb;
	float spec = g0.a;
	float3 albedo = g1.rgb;
	float ao = 1 - g1.a;

	float3 col = albedo * ao;

	/*
	float3 viewDir = normalize(eyePos);
	float3 rayOrigin = eyePos;
	float3 rayDir = reflect(viewDir, eyeNormal);
	float fres = pow(saturate(1 + dot(eyeNormal, viewDir.xyz) * 0.95), 0.25);

	if (eyeNormal.z > 0) {
		float factor = eyeNormal.z / (2 * 3.14159265);
		col += albedo * factor;
	}

	col += spec * fres;
	*/

	col.rgb = lerp(fogColor, col.rgb, exp(-eyeDepth * fogDensity));

	if (length(eyeNormal) < 0.1)
		return float4(fogColor, 1);

	return float4(col, 1);
}

technique lighting {
	pass P0 {
		VertexShader = compile vs_3_0 vertex();
		PixelShader  = compile ps_3_0 pixel();
		ZEnable = False;
		CullMode = None;
	}
}
