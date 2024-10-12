/**
    This file for SphereFog

    Macros:
    _SPHERE_FOG_LAYERS   // use _SphereFogId

    Variables:
    need define _SphereFogId
*/
#if !defined(SPHERE_FOG_LIB_HLSL)
#define SPHERE_FOG_LIB_HLSL

#if !defined(_SPHERE_FOG_LAYERS)
    #define _SphereFogId 0
#endif

int _SphereFogLayers;

int GetSphereFogId(){
    return _SphereFogId < _SphereFogLayers ? _SphereFogId : 0;
}
#define SPHERE_FOG_ID GetSphereFogId()

#define USE_STRUCTURED_BUFFER
#if defined(USE_STRUCTURED_BUFFER)
    struct SphereFogData{
        float heightFogMin;
        float heightFogMax;
        float4 heightFogMinColor;
        float4 heightFogMaxColor;
        float heightFogFilterUpFace;

        float4 fogNearColor;
        float4 fogFarColor;
        float2 fogDistance;
        float4 fogNoiseTilingOffset;
        float4 fogNoiseParams; // composite args
        float4 fogParams; // for SIMPLE_FOG
    };

    StructuredBuffer<SphereFogData> _SphereFogDatas;

    // shortcuts
    #define _HeightFogMin _SphereFogDatas[SPHERE_FOG_ID].heightFogMin
    #define _HeightFogMax _SphereFogDatas[SPHERE_FOG_ID].heightFogMax
    #define _HeightFogMinColor _SphereFogDatas[SPHERE_FOG_ID].heightFogMinColor
    #define _HeightFogMaxColor _SphereFogDatas[SPHERE_FOG_ID].heightFogMaxColor
    #define _HeightFogFilterUpFace _SphereFogDatas[SPHERE_FOG_ID].heightFogFilterUpFace

    #define _FogNearColor _SphereFogDatas[SPHERE_FOG_ID].fogNearColor
    #define _FogFarColor _SphereFogDatas[SPHERE_FOG_ID].fogFarColor

    #define _FogDistance _SphereFogDatas[SPHERE_FOG_ID].fogDistance
    #define _FogNoiseTilingOffset _SphereFogDatas[SPHERE_FOG_ID].fogNoiseTilingOffset
     // composite args
    #define _FogNoiseParams _SphereFogDatas[SPHERE_FOG_ID].fogNoiseParams
    #define _FogNoiseStartRate _FogNoiseParams.x
    #define _FogNoiseIntensity _FogNoiseParams.y

#else
    #define MAX_COUNT 16
    CBUFFER_START(SphereFogs)
        float _HeightFogMinArray[MAX_COUNT];
        float _HeightFogMaxArray[MAX_COUNT];
        float4 _HeightFogMinColorArray[MAX_COUNT];
        float4 _HeightFogMaxColorArray[MAX_COUNT];
        half _HeightFogFilterUpFaceArray[MAX_COUNT];

        float4 _FogNearColorArrays[MAX_COUNT];
        float2 _FogDistanceArray[MAX_COUNT];
        half4 _FogNoiseTilingOffsetArray[MAX_COUNT];
        half4 _FogNoiseParamsArray[MAX_COUNT]; // composite args
        half4 _FogParamsArray[MAX_COUNT]; // for SIMPLE_FOG
    CBUFFER_END
#endif //USE_STRUCTURED_BUFFER

#endif // SPHERE_FOG_LIB_HLSL