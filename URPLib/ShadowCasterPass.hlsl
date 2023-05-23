#if !defined(URP_SHADOW_CASTER_PASS_HLSL)
#define URP_SHADOW_CASTER_PASS_HLSL
#include "../../PowerShaderLib/UrpLib/URP_MainLightShadows.hlsl"
/**
    variables(can override):
    _MainTex,sampler_MainTex
    _MainTexChannel
    _Cutoff

    keywords:
    ALPHA_TEST or _ALPHATEST_ON : alpha test
    SHADOW_PASS : shadowCasterPass or depthpass
    USE_SAMPLER2D : use tex2D or SAMPLE_TEXTURE2D

    //============================
    Demo(PowerVFX ShadowCasterPass):
    #define SHADOW_PASS
    #define USE_SAMPLER2D
    #define _MainTex _DissolveTex
    #define _MainTexChannel _DissolveTexChannel
*/

// default values
#if !defined(_MainTexChannel)
#define _MainTexChannel 3
#endif

// #if !defined(_Cutoff)
// #define _Cutoff 0.5
// #endif

struct appdata
{
    float4 vertex   : POSITION;
    float3 normal     : NORMAL;
    float2 texcoord     : TEXCOORD0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f{
    float2 uv:TEXCOORD0;
    float4 pos:SV_POSITION;
};

float3 _LightDirection;

//--------- shadow helpers
float4 GetShadowPositionHClip(appdata input){
    float3 worldPos = mul(unity_ObjectToWorld,input.vertex).xyz;
    float3 worldNormal = UnityObjectToWorldNormal(input.normal);
    float4 positionCS = UnityWorldToClipPos(ApplyShadowBias(worldPos,worldNormal,_LightDirection));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}

v2f vert(appdata input){
    v2f output;

    #if defined(SHADOW_PASS)
        output.pos = GetShadowPositionHClip(input);
    #else
        output.pos = mul(unity_ObjectToWorld,input.vertex);
    #endif
    output.uv = TRANSFORM_TEX(input.texcoord,_MainTex);
    return output;
}

float4 frag(v2f input):SV_Target{
    #if defined(ALPHA_TEST) || defined(_ALPHATEST_ON)
        #if defined(USE_SAMPLER2D)
        float4 tex = tex2D(_MainTex,input.uv);
        #else
        float4 tex = SAMPLE_TEXTURE2D(_MainTex,sampler_MainTex,input.uv);
        #endif
        
        clip(tex[_MainTexChannel] - _Cutoff -0.000001);
    #endif
    return 0;
}


#endif //URP_SHADOW_CASTER_PASS_HLSL