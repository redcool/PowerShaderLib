/** 
    variables(can override):
    _MainTex,sampler_MainTex
    _MainTexChannel
    _Cutoff
    _CustomShadowNormalBias,_CustomShadowDepthBias

    //============================ weather function
    _WIND_ON

    keywords:
    ALPHA_TEST or _ALPHATEST_ON : alpha test
    SHADOW_PASS : shadowCasterPass or depthpass
    USE_SAMPLER2D : use tex2D or SAMPLE_TEXTURE2D
    _CASTING_PUNCTUAL_LIGHT_SHADOW : point,spot light shadow

    //============================
    Demo(PowerVFX ShadowCasterPass):
    #define SHADOW_PASS
    #define USE_SAMPLER2D

    // replace texture
    #define _MainTex _DissolveTex
    
    // replace texture channel
    #define _MainTexChannel _DissolveTexChannel

*/
#if !defined(URP_SHADOW_CASTER_PASS_HLSL)
#define URP_SHADOW_CASTER_PASS_HLSL
#include "../../PowerShaderLib/UrpLib/URP_MainLightShadows.hlsl"
#include "../../PowerShaderLib/Lib/NatureLib.hlsl"
#include "../../PowerShaderLib/Lib/TextureLib.hlsl"

// default values
#if !defined(_MainTexChannel)
#define _MainTexChannel 3
#endif

#if !defined(_CustomShadowNormalBias)
    #define _CustomShadowNormalBias 0
#endif
#if !defined(_CustomShadowDepthBias)
    #define _CustomShadowDepthBias 0
#endif

// #if !defined(_Cutoff)
// #define _Cutoff 0.5
// #endif

struct shadow_appdata
{
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float3 color:COLOR;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct shadow_v2f{
    float2 uv:TEXCOORD0;
    float4 pos:SV_POSITION;
};

float3 _LightDirection;
float3 _LightPosition;
float2 _CustomShadowBias; //x:depth bias,y:normal bias, global ,set by commandbuffer or Shader

//--------- shadow helpers
float4 GetShadowPositionHClip(shadow_appdata input){
    float3 worldPos = TransformObjectToWorld(input.vertex.xyz);
    float3 worldNormal = UnityObjectToWorldNormal(input.normal);

    #if defined(_WIND_ON)
    float4 attenParam = input.color.x; // vertex color atten
    branch_if(IsWindOn()){
        worldPos = WindAnimationVertex(worldPos,input.vertex.xyz,worldNormal,attenParam * _WindAnimParam, _WindDir,_WindSpeed).xyz;
    }
    #endif

    #if _CASTING_PUNCTUAL_LIGHT_SHADOW
        float3 lightDirectionWS = normalize(_LightPosition - worldPos);
    #else
        float3 lightDirectionWS = _LightDirection;
    #endif

    float4 positionCS = UnityWorldToClipPos(ApplyShadowBias(worldPos,worldNormal,lightDirectionWS,_CustomShadowNormalBias + _CustomShadowBias.y,_CustomShadowDepthBias + _CustomShadowBias.x));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}

shadow_v2f vert(shadow_appdata input){
    shadow_v2f output;

    #if defined(SHADOW_PASS)
        output.pos = GetShadowPositionHClip(input);
    #else
        output.pos = TransformObjectToHClip(input.vertex.xyz);
    #endif
    output.uv = TRANSFORM_TEX(input.texcoord,_MainTex);
    return output;
}

float4 frag(shadow_v2f input):SV_Target{
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