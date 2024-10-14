/**
    This file for SphereFog

    Macros:
    _SPHERE_FOG_LAYERS   // use _SphereFogId
    USE_STRUCTURED_BUFFER //

    Variables:
    need define _SphereFogId
*/
#if !defined(SPHERE_FOG_LIB_HLSL)
#define SPHERE_FOG_LIB_HLSL
// force use structedBuffer
// #define USE_STRUCTURED_BUFFER

#if !defined(_SPHERE_FOG_LAYERS)
    #define _SphereFogId 0
#endif

// total fog layers, by PowerLitFogControl
int _SphereFogLayers;

int GetSphereFogId(){
    return _SphereFogId < _SphereFogLayers ? _SphereFogId : 0;
}
#define SPHERE_FOG_ID GetSphereFogId()
// global macros

#define _FogNoiseStartRate _FogNoiseParams.x
#define _FogNoiseIntensity _FogNoiseParams.y

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


#else
    #define MAX_COUNT 16
    CBUFFER_START(SphereFogs)
        float _HeightFogMinArray[MAX_COUNT];
        float _HeightFogMaxArray[MAX_COUNT];
        float4 _HeightFogMinColorArray[MAX_COUNT];
        float4 _HeightFogMaxColorArray[MAX_COUNT];
        half _HeightFogFilterUpFaceArray[MAX_COUNT];

        float4 _FogNearColorArrays[MAX_COUNT];
        float4 _FogFarColorArrays[MAX_COUNT];
        float2 _FogDistanceArray[MAX_COUNT];
        half4 _FogNoiseTilingOffsetArray[MAX_COUNT];
        half4 _FogNoiseParamsArray[MAX_COUNT]; // composite args
        half4 _FogParamsArray[MAX_COUNT]; // for SIMPLE_FOG
    CBUFFER_END
    // shortcuts
    #define _HeightFogMin _HeightFogMinArray[SPHERE_FOG_ID]
    #define _HeightFogMax _HeightFogMaxArray[SPHERE_FOG_ID]
    #define _HeightFogMinColor _HeightFogMinColorArray[SPHERE_FOG_ID]
    #define _HeightFogMaxColor _HeightFogMaxColorArray[SPHERE_FOG_ID]
    #define _HeightFogFilterUpFace _HeightFogFilterUpFaceArray[SPHERE_FOG_ID]

    #define _FogNearColor _FogNearColorArrays[SPHERE_FOG_ID]
    #define _FogFarColor _FogFarColorArrays[SPHERE_FOG_ID]
    #define _FogDistance _FogDistanceArray[SPHERE_FOG_ID]
    #define _FogNoiseTilingOffset _FogNoiseTilingOffsetArray[SPHERE_FOG_ID]
    // composite args
    #define _FogNoiseParams _FogNoiseParamsArray[SPHERE_FOG_ID]
#endif //USE_STRUCTURED_BUFFER

#endif // SPHERE_FOG_LIB_HLSL