//-----
// pbr1.shader ,used MetaPass
//
#if !defined(PBR1_META_PASS_HLSL)
#define PBR1_META_PASS_HLSL

// default USE_SAMPLER2D
#if !defined(USE_TEXTURE2D)
    #define USE_SAMPLER2D
#endif

// define baseMap
// #define _BaseMap _MainTex
// #define _EmissionMap _EmissionMap1
// _PbrMask


#include "MetaPass.hlsl"
#include "../Lib/MaterialLib.hlsl"
#include "../Lib/TextureLib.hlsl"

float4 frag(Varyings input):SV_Target{
    float2 mainUV = input.uv.xy;

    float4 pbrMask = SAMPLE_TEXTURE2D(_PbrMask,sampler_PbrMask,mainUV);
    float metallic = 0;
    float smoothness =0;
    float occlusion =0;
    SplitPbrMaskTexture(metallic/**/,smoothness/**/,occlusion/**/,pbrMask,int3(0,1,2),float3(_Metallic,_Smoothness,_Occlusion),false);
    float roughness = 1-smoothness;

    float4 mainTex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex, mainUV) * _Color;
    float3 albedo = mainTex.xyz;
    float alpha = mainTex.w;

    #if defined(ALPHA_TEST)
        clip(alpha - _Cutoff);
    #endif

    float3 specColor = lerp(0.04,albedo,metallic);
    float3 diffColor = albedo.xyz * (1- metallic);  
    float3 emissionColor = 0;

    #if defined(_EMISSION)
        emissionColor = CalcEmission(SAMPLE_TEXTURE2D(_EmissionMap,sampler_EmissionMap,mainUV),_EmissionColor.xyz,_EmissionColor.w);
    #endif

    MetaInput metaInput = (MetaInput)0;
    metaInput.albedo = diffColor + specColor * roughness * 0.5;
    metaInput.emission = emissionColor;

    return CalcMetaFragment(metaInput);
}


#endif //PBR1_META_PASS_HLSL