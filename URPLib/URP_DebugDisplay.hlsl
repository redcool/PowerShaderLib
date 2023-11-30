#if !defined(URP_DEBUG_DISPLAY_HLSL) && defined(DEBUG_DISPLAY)
#define URP_DEBUG_DISPLAY_HLSL

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/DebuggingCommon.hlsl"

half3 CalculateDebugLightingComplexityColor(float2 screenUV, half3 albedo)
{
    // Assume a main light and add 1 to the additional lights.
    int numLights = GetAdditionalLightsCount() + 1;

    const uint2 tileSize = uint2(32,32);
    const uint maxLights = 9;
    const float opacity = 0.8f;

    uint2 pixelCoord = uint2(screenUV * _ScreenParams.xy);
    half3 base = albedo;
    half4 overlay = half4(OverlayHeatMap(pixelCoord, tileSize, numLights, maxLights, opacity));

    uint2 tileCoord = (float2)pixelCoord / tileSize;
    uint2 offsetInTile = pixelCoord - tileCoord * tileSize;
    bool border = any(offsetInTile == 0 || offsetInTile == tileSize.x - 1);
    if (border)
        overlay = half4(1, 1, 1, 0.4f);

    return lerp(base.rgb, overlay.rgb, overlay.a);
}

half3 CalculateDebugShadowCascadeColor(float3 positionWS)
{
    half cascadeIndex = ComputeCascadeIndex(positionWS);

    switch (uint(cascadeIndex))
    {
        case 0: return kDebugColorShadowCascade0.rgb;
        case 1: return kDebugColorShadowCascade1.rgb;
        case 2: return kDebugColorShadowCascade2.rgb;
        case 3: return kDebugColorShadowCascade3.rgb;
        default: return kDebugColorBlack.rgb;
    }
}

bool CalculateValidationMetallic(half3 albedo, half metallic, inout half4 debugColor)
{
    if (metallic < _DebugValidateMetallicMinValue)
    {
        debugColor = _DebugValidateBelowMinThresholdColor;
    }
    else if (metallic > _DebugValidateMetallicMaxValue)
    {
        debugColor = _DebugValidateAboveMaxThresholdColor;
    }
    else
    {
        half luminance = Luminance(albedo);

        debugColor = half4(luminance, luminance, luminance, 1);
    }
    return true;
}

/**
    Get urp debug display color
*/

half3 CalcDebugColor(
    inout bool isBreak/**/,
    inout half3 albedo,
    inout half3 specular,
    half alpha,
    inout half metallic,
    inout half smoothness,
    inout half occlusion,
    inout half3 emission,
    inout float3 worldNormal,
    inout float3 tangentNormal,
    float2 screenUV,
    float3 worldPos,
    float4 tSpace0,
    float4 tSpace1,
    float4 tSpace2
){
    isBreak = _DebugMaterialValidationMode != 0 
    || _DebugMaterialMode != 0
    || _DebugSceneOverrideMode != 0
    ;

    // run scene debug
    if(_DebugSceneOverrideMode != DEBUGSCENEOVERRIDEMODE_NONE)
        return _DebugColor.xyz;
    
    // run material check mode
    switch(_DebugMaterialMode)
    {
        case DEBUGMATERIALMODE_ALBEDO:
            return albedo;
        case DEBUGMATERIALMODE_SPECULAR:
            return specular;
        case DEBUGMATERIALMODE_ALPHA:
            return alpha;

        case DEBUGMATERIALMODE_METALLIC:
            return metallic;
        case DEBUGMATERIALMODE_SMOOTHNESS:
            return smoothness;
        case DEBUGMATERIALMODE_AMBIENT_OCCLUSION:
            return occlusion;

        case DEBUGMATERIALMODE_EMISSION:
            return emission;
        case DEBUGMATERIALMODE_NORMAL_WORLD_SPACE:
            return worldNormal*0.5+0.5;
        case DEBUGMATERIALMODE_NORMAL_TANGENT_SPACE:
            return tangentNormal*0.5+0.5;
        case DEBUGMATERIALMODE_LIGHTING_COMPLEXITY:
            return CalculateDebugLightingComplexityColor(screenUV,albedo);
    }

    // run validate mode
    half4 debugColor = 0;
    switch(_DebugMaterialValidationMode)
    {
        case DEBUGMATERIALVALIDATIONMODE_ALBEDO:
            CalculateValidationAlbedo(albedo,debugColor/**/);
            return debugColor.xyz;
        case DEBUGMATERIALVALIDATIONMODE_METALLIC:
            CalculateValidationMetallic(albedo,metallic,debugColor/**/);
            return debugColor.xyz;
    }

    // lighting mode
    if (_DebugLightingMode == DEBUGLIGHTINGMODE_SHADOW_CASCADES){
        albedo = CalculateDebugShadowCascadeColor(worldPos);
    }else if(_DebugLightingMode != 0){
        albedo = emission = specular = occlusion = metallic = smoothness = 0;
        if (_DebugLightingMode == DEBUGLIGHTINGMODE_LIGHTING_WITHOUT_NORMAL_MAPS || _DebugLightingMode == DEBUGLIGHTINGMODE_LIGHTING_WITH_NORMAL_MAPS)
        {
            albedo = 1;
            occlusion = 1;
        }else if(_DebugLightingMode == DEBUGLIGHTINGMODE_REFLECTIONS || _DebugLightingMode == DEBUGLIGHTINGMODE_REFLECTIONS_WITH_SMOOTHNESS)
        {
            occlusion = 1;
            specular =1;
            smoothness = _DebugLightingMode == DEBUGLIGHTINGMODE_REFLECTIONS;
        }

        if (_DebugLightingMode == DEBUGLIGHTINGMODE_LIGHTING_WITHOUT_NORMAL_MAPS || _DebugLightingMode == DEBUGLIGHTINGMODE_REFLECTIONS)
        {
            tangentNormal = half3(0,0,1);
            worldNormal = float3(dot(tSpace0.xyz,tangentNormal),dot(tSpace1.xyz,tangentNormal),dot(tSpace2.xyz,tangentNormal));
        }
    }
    
    return TryGetDebugColorInvalidMode(debugColor);
}

#endif //URP_DEBUG_DISPLAY_HLSL