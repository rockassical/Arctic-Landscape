uniform sampler2D _MaskSurface;
uniform float4 _MaskSurface_ST;
uniform half _SurfaceOpacity;
uniform half3 _ColorSurface;

uniform half3 _ColorShallow;
uniform half3 _ColorDeep;
uniform half _Depth;

uniform sampler2D _NormalMap;
uniform float4 _NormalMap_ST;
uniform half _NormalStrength;

uniform half _Refraction;
uniform half _Smoothness;

uniform half _AmbientFresnel;
uniform half3 _ColorAmbient;

uniform bool _IsCaustics;
uniform sampler2D _MaskCaustics;
uniform float4 _MaskCaustics_ST;

uniform bool _IsFoam;
uniform sampler2D _MaskFoam;
uniform float4 _MaskFoam_ST;
uniform half _FoamAmount;
uniform half _FoamCutoff;
uniform half3 _ColorFoam;

#include "Effects.hlsl"
#include "Normals.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

void FragmentFunction(Interpolators varyings, out half4 outColor : SV_Target)
{
	half3 viewDir = normalize(varyings.viewVector_ws);
	float2 uv_ss = varyings.position_ss.xy / varyings.position_ss.w;

	// Calculating Normal
	half3 normal = SampleNormalMap(_NormalMap, varyings.uv_ws * _NormalMap_ST.xy + _Time * _NormalMap_ST.zw);
	normal = NormalStrength(normal, _NormalStrength);
	normal = TransformNormalToWS(half3(1, 0, 0), half3(0, 1, 0), half3(0, 0, 1), normal);

	// Calculating Direct Depth
	half depth = Linear01Depth(SampleSceneDepth(uv_ss), _ZBufferParams) * _ProjectionParams.z - (varyings.position_ss.w - 1);
	half depthMask = saturate(depth - _Depth);

	// Calculating Refracted Depth
	half refDepth = Linear01Depth(SampleSceneDepth(uv_ss + normal.xz * _Refraction), _ZBufferParams) * _ProjectionParams.z - (varyings.position_ss.w - 1);
	half refMask = saturate(refDepth - _Depth);

	// Shallow-Deep Coloring
	half3 waterColor = lerp(_ColorShallow, _ColorDeep, refMask);

	// Specular Coloring
	half3 halfVector = normalize(_MainLightPosition.xyz + viewDir);
	half specMask = pow(saturate(dot(normal, halfVector)), _Smoothness * 1000) * sqrt(_Smoothness);
	waterColor = lerp(waterColor, half3(1, 1, 1), specMask);

	// Surface Mask Coloring
	half surfaceMask = tex2D(_MaskSurface, varyings.uv_ws * _MaskSurface_ST.xy + _Time.y * _MaskSurface_ST.zw);
	waterColor = lerp(waterColor, _ColorSurface, surfaceMask * _SurfaceOpacity);

	// Fade Fresnel Coloring
	half fresnel = saturate(Fresnel(normal, viewDir, _AmbientFresnel) + Fresnel(half3(0, 1, 0), viewDir, _AmbientFresnel));
	waterColor = lerp(waterColor, _ColorAmbient, fresnel);

	// Caustics Coloring
	if(_IsCaustics)
	{
		half3 causticsMask = tex2D(_MaskCaustics, varyings.uv_ws * _MaskCaustics_ST.xy + _Time.y * _MaskCaustics_ST.zw).rgb;
		waterColor = lerp(waterColor, half3(1, 1, 1), causticsMask * (1 - depthMask));
	}

	// Foam Coloring
	if(_IsFoam)
	{
		half foamMask = tex2D(_MaskFoam, varyings.uv_ws * _MaskFoam_ST.xy + _Time.y * _MaskFoam_ST.zw).r * (1 - saturate(depth - _FoamAmount));
		foamMask = step(_FoamCutoff, foamMask);
		waterColor = lerp(waterColor, _ColorFoam, foamMask);
	}

	outColor = half4(waterColor.rgb, 1);
}