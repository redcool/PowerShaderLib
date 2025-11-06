/** 
    variables(can override):
    _MainTex,sampler_MainTex
    _MainTexChannel  // mainTex's alpha
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
    #define _MainTex_ST _DissolveTex_ST
    
    // replace texture channel
    #define _MainTexChannel _DissolveTexChannel
    // define outside file
    #define _CURVED_WORLD
*/
#if !defined(URP_SHADOW_CASTER_PASS_HLSL)
#define URP_SHADOW_CASTER_PASS_HLSL
#include "../../PowerShaderLib/UrpLib/URP_MainLightShadows.hlsl"
#include "../../PowerShaderLib/Lib/NatureLib.hlsl"
#include "../../PowerShaderLib/Lib/TextureLib.hlsl"
#include "../../PowerShaderLib/Lib/CurvedLib.hlsl"

#if defined(_ANIM_TEX_ON) || defined(_GPU_SKINNED_ON)
    #include "../../PowerShaderLib/Lib/Skinned/AnimTextureLib.hlsl"
#endif

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
#if !defined(_MainTex_ST)
    #define _MainTex_ST half4(1,1,0,0)
#endif

// define curved_world variables
#if !defined(_CURVED_WORLD)
    float _CurvedSidewayScale,_CurvedBackwardScale;
#endif

// #if !defined(_Cutoff)
// #define _Cutoff 0.5
// #endif

struct shadow_appdata
{
    float4 vertex : POSITION;
    float4 normal : NORMAL;
    float2 texcoord : TEXCOORD0;
    float4 color:COLOR;

    UNITY_VERTEX_INPUT_INSTANCE_ID
    //AnimTextureLib
    uint vertexId:SV_VertexID;
    float4 weights:BLENDWEIGHTS;
    uint indices:BLENDINDICES;
    float4 tangent:TANGENT;
};

struct shadow_v2f{
    float2 uv:TEXCOORD0;
    float4 pos:SV_POSITION;
};

float3 _LightDirection;
float3 _LightPosition;

//--------- shadow helpers
/**
    return shadow position hclip space
*/
float4 GetShadowPositionHClip(float3 worldPos,float3 worldNormal){
    #if _CASTING_PUNCTUAL_LIGHT_SHADOW
        float3 lightDirectionWS = normalize(_LightPosition - worldPos);
    #else
        float3 lightDirectionWS = _LightDirection;
    #endif

    float4 positionCS = TransformWorldToHClip(ApplyShadowBias(worldPos,worldNormal,lightDirectionWS,_CustomShadowNormalBias,_CustomShadowDepthBias));
    #if UNITY_REVERSED_Z
        positionCS.z = min(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #else
        positionCS.z = max(positionCS.z, positionCS.w * UNITY_NEAR_CLIP_VALUE);
    #endif
    return positionCS;
}

/**
    worldPos apply wind(WindAnimationVertex)
*/
void CaclWaveAnimationWorldPos(float3 vertex,float3 vertexColor,float3 normal,inout float3 worldPos,inout float3 worldNormal){
    worldPos = TransformObjectToWorld(vertex.xyz);
    worldNormal = UnityObjectToWorldNormal(normal);

    #if defined(_WIND_ON)
    float4 attenParam = vertexColor.x; // vertex color atten
    branch_if(IsWindOn()){
        worldPos = WindAnimationVertex(worldPos,vertex.xyz,worldNormal,attenParam * _WindAnimParam, _WindDir,_WindSpeed).xyz;
    }
    #endif
    worldPos.xy += CalcCurvedPos(_WorldSpaceCameraPos,worldPos,_CurvedSidewayScale,_CurvedBackwardScale);
}

shadow_v2f vert(shadow_appdata v){
    shadow_v2f output = (shadow_v2f)0;

    // AnimTextureLib
    #if defined(_ANIM_TEX_ON)
        CalcBlendAnimPos(v.vertexId,v.vertex/**/,v.normal/**/,v.tangent/**/,v.weights,v.indices);
    #elif defined(_GPU_SKINNED_ON)
        CalcSkinnedPos(v.vertexId,v.vertex/**/,v.normal/**/,v.tangent/**/,v.weights,v.indices);
    #endif

    float3 worldPos,worldNormal;
    CaclWaveAnimationWorldPos(v.vertex.xyz,v.color.xyz,v.normal.xyz,worldPos/**/,worldNormal/**/);

    #if defined(SHADOW_PASS)
        output.pos = GetShadowPositionHClip(worldPos,worldNormal);
    #else
        output.pos = TransformWorldToHClip(worldPos);
    #endif

    // #if defined(ALPHA_TEST) || defined(_ALPHATEST_ON)
    output.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
    // #endif
    
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