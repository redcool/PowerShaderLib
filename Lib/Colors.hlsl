#if !defined(COLORS_HLSL)
#define COLORS_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

half3 ThinFilm(half invertNV,half scale,half offset,half saturate,half brightness){
    half h = invertNV * scale + offset;
    half s = saturate;
    half v = brightness;
    return HsvToRgb(half3(h,s,v));
}

float3 ColorGradingExposure(float3 c,float m){
    return c*m;
}
float3 ColorGradingContrast(float3 c,float m){
    c = LinearToLogC(c);
    c = (c - ACEScc_MIDGRAY) * m + ACEScc_MIDGRAY;
    c = LogCToLinear(c);
    return max(0,c);
}
float3 ColorGradingFilter(float3 c,float3 filter){
    return c * filter.xyz;
}

float3 ColorGradingHSV(float3 c,float2 hueScaleOffset,float saturateScale,float brightScale){
    c = RgbToHsv(c);
    c.x = c.x * hueScaleOffset.x + hueScaleOffset.y;
    c.y *= saturateScale;
    c.z *= brightScale;
    return HsvToRgb(c);
}

float3 ColorGradingWhiteBalance(float3 c,float3 whiteBalanceColor){
    c = LinearToLMS(c);
    c *= whiteBalanceColor;
    return LMSToLinear(c);
}

float4 _ColorAdjustments; // {x:exposure,y:constrast}
float4 _ColorFilter; //{xyz:rgb}
float4 _ColorAdjustHSV; //{xy:hue scale,offset,z:saturate,w:value}
float4 _WhiteBalanceFactors;
float3 ColorGrading(float3 c){
    c = min(60,c);
    c = ColorGradingExposure(c,_ColorAdjustments.x);
    c = ColorGradingWhiteBalance(c,_WhiteBalanceFactors.xyz);
    c = ColorGradingContrast(c,_ColorAdjustments.y);
    c = ColorGradingFilter(c,_ColorFilter);
    c = ColorGradingHSV(c,_ColorAdjustHSV.xy,_ColorAdjustHSV.z,_ColorAdjustHSV.w);
    return max(0,c);
}

#endif //COLORS_HLSL