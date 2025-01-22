#if !defined(FOG_LIB_HLSL)
#define FOG_LIB_HLSL

/** Warning 
    include this file, material need define

    half _FogOn
    half _FogNoiseOn
    half _DepthFogOn
    half _HeightFogOn


1 shader

    [Header(Fog)]
    [GroupToggle()]_FogOn("_FogOn",int) = 1
    [GroupToggle(_,_DEPTH_FOG_NOISE_ON)]_FogNoiseOn("_FogNoiseOn",int) = 0
    [GroupToggle(_)]_DepthFogOn("_DepthFogOn",int) = 1
    [GroupToggle(_)]_HeightFogOn("_HeightFogOn",int) = 1

//--------------------------------- Fog define
    UNITY_DEFINE_INSTANCED_PROP(half ,_FogOn)
    UNITY_DEFINE_INSTANCED_PROP(half ,_FogNoiseOn)
    UNITY_DEFINE_INSTANCED_PROP(half ,_DepthFogOn)
    UNITY_DEFINE_INSTANCED_PROP(half ,_HeightFogOn)

//--------------------------------- Fog access
    #define _FogOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FogOn)
    #define _FogNoiseOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_FogNoiseOn)
    #define _DepthFogOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_DepthFogOn)
    #define _HeightFogOn UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial,_HeightFogOn)    

2 shader's vertex function
    float2 fogCoord = CalcFogFactor(worldPos);
3 shader's fragment function
    BlendFogSphere(color.rgb ,worldPos,sphereFogCoord,_HeightFogOn,fogNoise,_DepthFogOn,1);
*/

#include "NodeLib.hlsl"
#include "SphereFogLib.hlsl"
#include "../URPLib/URP_Fog.hlsl"

//------------------------------ macros
#undef branch_if
#if defined(USE_URP_SHADER)
    #define branch_if UNITY_BRANCH if
#else
    #define branch_if if
#endif


// #define _FogNoiseStartRate _FogNoiseParams.x
// #define _FogNoiseIntensity _FogNoiseParams.y
//------------------------------ sphere fog global params
// float _HeightFogMin,_HeightFogMax;
// float4 _HeightFogMinColor,_HeightFogMaxColor;
// half _HeightFogFilterUpFace;

// float4 _FogNearColor;
// float4 _FogFarColor;
// float2 _FogDistance;
// half4 _FogNoiseTilingOffset;
// half4 _FogNoiseParams; // composite args


//------------------------------  global fog params
float _GlobalFogIntensity;
half _IsGlobalFogOn;

// unity 2020, macro define not work
// #define IsFogOn() (_IsGlobalFogOn && _FogOn)
bool IsFogOn() {
    return _IsGlobalFogOn && _FogOn;
}

//----------------------------Sphere Fog
float3 GetFogCenter(){
    return _WorldSpaceCameraPos;
}

float CalcHeightFactor(float3 worldPos){
    float height = saturate((worldPos.y - _HeightFogMin) / (_HeightFogMax - _HeightFogMin));
    return height;
}

float CalcDepthFactor(float3 worldPos){
    float dist = distance(worldPos,GetFogCenter());
    float depth = saturate((dist - _FogDistance.x)/(_FogDistance.y-_FogDistance.x));
    return depth;
}

/**
    define FOG_LINEAR, simple fog
*/
float2 CalcFogFactor(float3 worldPos,float clipZ_01=1,bool hasHeightFog=true,bool hasDepthFog=true){
    float height = CalcHeightFactor(worldPos);
    float depth = CalcDepthFactor(worldPos);

    #if defined(SIMPLE_FOG)
        //max(ComputeFogFactor(clipZ_01) * hasDepthFog,height * hasHeightFog);

        float2 fog=0;
        fog.x = height * hasHeightFog;
        fog.y = clipZ_01;

        return fog;
    #else
        return float2(smoothstep(0.25,1,depth),height);
    #endif
}

void BlendFogSphere(inout float3 mainColor,float3 worldPos,float2 fog,bool hasHeightFog,float fogNoise,bool hasDepthFog=true,half fogAtten=1,float3 viewPos=0){
    branch_if(!IsFogOn())
        return;

    #if defined(SIMPLE_FOG) // simple fog
        // calc fogFactor(viewPos.z in fog.y)
        // float zFactor = max(fog.y - _ProjectionParams.y,0);
        float zFactor = fog.y;
        fog.x = ComputeFogFactor(zFactor) ;
        mainColor = lerp(_FogFarColor,mainColor,fog.x);
    #else   // sphere fog
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
            depthFactor += fogNoise * _FogNoiseIntensity * (fog.x > _FogNoiseStartRate);

        fogAtten = _HeightFogFilterUpFace? fogAtten : 1;

        float3 fogColor = lerp(_FogNearColor.rgb,_FogFarColor.rgb,fog.x);
        mainColor = lerp(mainColor,fogColor,saturate(depthFactor * fogAtten * _GlobalFogIntensity));
        // mainColor = depthFactor;
    #endif //SIMPLE_FOG
}

float CalcFogNoise(float3 worldPos,float3 windDir=1){
    float fogNoise = unity_gradientNoise( (worldPos.xz+worldPos.yz) * _FogNoiseTilingOffset.xy + _FogNoiseTilingOffset.zw * windDir.xz * _Time.y );
    return fogNoise;
}

void BlendFogSphereKeyword(inout half3 mainColor,float3 worldPos,float2 fog,bool hasHeightFog,float fogNoise,bool hasDepthFog=true,half fogAtten=1){
    BlendFogSphere(mainColor/**/,worldPos,fog,hasHeightFog,fogNoise,hasDepthFog,fogAtten);
}
#endif //FOG_LIB_HLSL