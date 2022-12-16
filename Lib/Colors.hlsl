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

float3 Luminance(float3 c,bool useACES){
    return useACES ? AcesLuminance(c) : Luminance(c);
}

float3 ColorGradingExposure(float3 c,float scale){
    return c*scale;
}

float3 ColorGradingContrast(float3 c,float scale,bool useACES){
    c = useACES ? ACES_to_ACEScc(unity_to_ACES(c)) : LinearToLogC(c);
    c = (c - ACEScc_MIDGRAY) * scale + ACEScc_MIDGRAY;
    c = useACES ? ACES_to_ACEScg(ACEScc_to_ACES(c)) : LogCToLinear(c);
    return c;
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

float3 ColorGradingSplitToning(float3 c,float3 shadows,float3 highlights,float balance,bool useACES){
    c = PositivePow(c,1/2.2);

    float t = saturate(Luminance(c,useACES) + balance);
    shadows = lerp(0.5,shadows, 1 - t);
    highlights = lerp(0.5,highlights, t);

    c = SoftLight(c,shadows);
    c = SoftLight(c,highlights);
    return PositivePow(c,2.2);
}

float3 ColorGradingChannelMixer(float3 c,float3 red,float3 green,float3 blue){
    return mul(float3x3(red,green,blue),c);
}

float3 ColorGradingShadowsMidtonesHighlights(float3 c,float3 shadowColor,float3 midtoneColor,float3 highlightColor,float4 range,bool useACES){
    float luma = Luminance(c,useACES);
    float shadowsWeight = 1 - smoothstep(range.x,range.y,luma);
    float highlightsWeight = smoothstep(range.z,range.w,luma);
    float midtonesWeight = 1 - shadowsWeight - highlightsWeight;
    return c * shadowColor * shadowsWeight +
        c * midtoneColor * midtonesWeight + 
        c * highlightColor * highlightsWeight;
}

float4 _ColorAdjustments; // {x:exposure,y:constrast}
float4 _ColorFilter; //{xyz:rgb}
float4 _ColorAdjustHSV; //{xy:hue scale,offset,z:saturate,w:value}
float4 _WhiteBalanceFactors;
float4 _SplitToningHighlights,_SplitToningShadows;//{xyz:rgb,w:balance}
float4 _ChannelMixerRed,_ChannelMixerGreen,_ChannelMixerBlue;

float4 _SMHShadows,_SMHMidtones,_SMHHighlights,_SMHRange;
float3 ColorGrading(float3 c,bool useACES=false){
    c = min(60,c);
    c = ColorGradingExposure(c,_ColorAdjustments.x);
    c = ColorGradingWhiteBalance(c,_WhiteBalanceFactors.xyz);
    c = ColorGradingContrast(c,_ColorAdjustments.y,useACES);
    c = ColorGradingFilter(c,_ColorFilter);
    c = max(c,0);

    c = ColorGradingSplitToning(c,_SplitToningShadows.xyz,_SplitToningHighlights.xyz,_SplitToningShadows.w,useACES);
    c = ColorGradingChannelMixer(c,_ChannelMixerRed.xyz,_ChannelMixerGreen.xyz,_ChannelMixerBlue.xyz);
    c = max(c,0);

    c = ColorGradingShadowsMidtonesHighlights(c,_SMHShadows,_SMHMidtones,_SMHHighlights,_SMHRange,useACES);

    c = ColorGradingHSV(c,_ColorAdjustHSV.xy,_ColorAdjustHSV.z,_ColorAdjustHSV.w);
    return max(useACES ? ACEScg_to_ACES(c) : c,0);
}

#endif //COLORS_HLSL