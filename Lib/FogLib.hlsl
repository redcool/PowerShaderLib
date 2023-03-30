#if !defined(FOG_LIB_HLSL)
#define FOG_LIB_HLSL

/** Warning 
    include this file, need define
    half _FogOn
*/

#include "NodeLib.hlsl"

//------------------------------ macros
#undef branch_if
#if defined(USE_URP_SHADER)
    #define branch_if UNITY_BRANCH if
#else
    #define branch_if if
#endif

#define IsFogOn() (_IsGlobalFogOn && _FogOn)
#define _FogNoiseStartRate _FogNoiseParams.x
#define _FogNoiseIntensity _FogNoiseParams.y

//------------------------------ sphere fog params
float _HeightFogMin,_HeightFogMax;
float4 _HeightFogMinColor,_HeightFogMaxColor;
float4 _FogNearColor;
float2 _FogDistance;
half4 _FogDirTiling;
half4 _FogNoiseParams; // composite args

//------------------------------  global fog params
float _GlobalFogIntensity;
half _IsGlobalFogOn;


//----------------------------Sphere Fog
float CalcDepthFactor(float dist){
    // float fogFactor =  max(((1.0-(dist)/_ProjectionParams.y)*_ProjectionParams.z),0);
    float fogFactor = dist * unity_FogParams.z + unity_FogParams.w;
    return fogFactor;
}

float3 GetFogCenter(){
    return _WorldSpaceCameraPos;
}

float2 CalcFogFactor(float3 worldPos){
    float2 fog = 0;

    float height = saturate((worldPos.y - _HeightFogMin) / (_HeightFogMax - _HeightFogMin));

    float dist = distance(worldPos,GetFogCenter());
    float depth = saturate((dist - _FogDistance.x)/(_FogDistance.y-_FogDistance.x));

    fog.x = smoothstep(0.25,1,depth);
    fog.y = saturate( height);
    return fog;
}

void BlendFogSphere(inout float3 mainColor,float3 worldPos,float2 fog,bool hasHeightFog,float fogNoise,bool hasDepthFog=true){
    branch_if(!IsFogOn())
        return;

    branch_if(hasHeightFog){
        float3 heightFogColor = lerp(_HeightFogMinColor,_HeightFogMaxColor,fog.y).xyz;
        float heightFactor = smoothstep(0,0.1,fog.x)* (1-fog.y);

        mainColor = lerp(mainColor,heightFogColor,heightFactor * _GlobalFogIntensity);
        // mainColor = heightFactor;
        // return ;
    }

    branch_if(!hasDepthFog)
        return;
    
    float depthFactor = fog.x;
    branch_if(fogNoise){
        // float gradientNoise = unity_gradientNoise( (worldPos.xz+worldPos.yz) * _FogDirTiling.w+ _FogDirTiling.xz * _Time.y );
        depthFactor = fog.x + fogNoise * _FogNoiseIntensity * (fog.x > _FogNoiseStartRate);
    }

    float3 fogColor = lerp(_FogNearColor.rgb,unity_FogColor.rgb,fog.x);
    mainColor = lerp(mainColor,fogColor, depthFactor * _GlobalFogIntensity);
    // mainColor = depthFactor;
}

void BlendFogSphereKeyword(inout half3 mainColor,float3 worldPos,float2 fog,bool hasHeightFog,float fogNoise,bool hasDepthFog=true){
    // #if ! defined(FOG_LINEAR)
    //     return;
    // #endif
    branch_if(!IsFogOn())
        return;

    // #if defined(_HEIGHT_FOG_ON)
    branch_if(hasHeightFog)
    {
        half3 heightFogColor = lerp(_HeightFogMinColor,_HeightFogMaxColor,fog.y).xyz;
        float heightFactor = smoothstep(0,0.1,fog.x)* (1-fog.y);

        mainColor = lerp(mainColor,heightFogColor,heightFactor * _GlobalFogIntensity);
        // mainColor = heightFactor;
        // return ;
    }
    // #endif

    // #if defined(_DEPTH_FOG_ON)
    branch_if(hasDepthFog)
    {
        // calc depth noise
        half depthFactor = fog.x;
        #if defined(_DEPTH_FOG_NOISE_ON)
        // branch_if(fogNoiseOn)
        {
            // float fogNoise = unity_gradientNoise( (worldPos.xz+worldPos.yz) * _FogDirTiling.w+ _FogDirTiling.xz * _Time.y );
            depthFactor = fog.x + fogNoise * _FogNoiseIntensity * (fog.x > _FogNoiseStartRate);
        }
        #endif

        half3 fogColor = lerp(_FogNearColor.rgb,unity_FogColor.rgb,fog.x);
        mainColor = lerp(mainColor,fogColor, depthFactor * _GlobalFogIntensity);
    }
    // #endif
    // mainColor = depthFactor;
}
#endif //FOG_LIB_HLSL