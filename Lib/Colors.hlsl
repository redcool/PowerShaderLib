#if !defined(COLORS_HLSL)
#define COLORS_HLSL

/**
    https://munsell.com/color-blog/difference-chroma-saturation/
*/

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
#include "NoiseLib.hlsl"

half3 ThinFilm(half invertNV,half scale,half offset,half saturate,half brightness){
    half h = invertNV * scale + offset;
    half s = saturate;
    half v = brightness;
    return HsvToRgb(half3(h,s,v));
}

float Luminance(float3 c,bool useACES){
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
float4 _ColorGradingLUTParams; //{x:height,y:1/width,z:1/height,w: height/(height-1)}
bool _ColorGradingUseLogC;



float3 ColorGrading(float3 c,bool useACES=false){
    // c = min(60,c);
    c = ColorGradingExposure(c,_ColorAdjustments.x);
    c = ColorGradingWhiteBalance(c,_WhiteBalanceFactors.xyz);
    c = ColorGradingContrast(c,_ColorAdjustments.y,useACES);
    c = ColorGradingFilter(c,_ColorFilter.xyz);
    c = max(c,0);

    c = ColorGradingSplitToning(c,_SplitToningShadows.xyz,_SplitToningHighlights.xyz,_SplitToningShadows.w,useACES);
    c = ColorGradingChannelMixer(c,_ChannelMixerRed.xyz,_ChannelMixerGreen.xyz,_ChannelMixerBlue.xyz);
    c = max(c,0);

    c = ColorGradingShadowsMidtonesHighlights(c,_SMHShadows.xyz,_SMHMidtones.xyz,_SMHHighlights.xyz,_SMHRange,useACES);

    c = ColorGradingHSV(c,_ColorAdjustHSV.xy,_ColorAdjustHSV.z,_ColorAdjustHSV.w);
    return max(useACES ? ACEScg_to_ACES(c) : c,0);
}

// generat color grading lut
float3 ColorGradingLUT(float2 uv,bool useACES = false){
    float3 c = GetLutStripValue(uv,_ColorGradingLUTParams);
    return ColorGrading(_ColorGradingUseLogC ? LogCToLinear(c) : c,useACES);
}

// apply color grading lut
SAMPLER(sampler_linear_clamp);
TEXTURE2D(_ColorGradingLUT);
float4 _ColorGradingLUT_TexelSize;
// float4 _ColorGradingLUTParams; //{x:1/width,y:1/height,z:height-1} 

real3 _ApplyLut2D(TEXTURE2D_PARAM(tex, samplerTex), float3 uvw, float3 scaleOffset)
{
    float w = 1/1024.0;
    float h = 1/32.0;
    float z = 31;

    uvw.z *= z;
    float s = floor(uvw.z);
    uvw.xy = (uvw.xy * z + 0.5) * float2(w,h);
    uvw.x += s * h;
    uvw.xyz = lerp(
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy, 0.0).rgb,
        SAMPLE_TEXTURE2D_LOD(tex, samplerTex, uvw.xy + float2(h, 0.0), 0.0).rgb,
        uvw.z - s
    );
    return uvw;
}

float3 ApplyColorGradingLUT(float3 c){
    return ApplyLut2D(
        TEXTURE2D_ARGS(_ColorGradingLUT,sampler_linear_clamp),
        saturate(_ColorGradingUseLogC ? LinearToLogC(c) : c),
        _ColorGradingLUTParams.xyz
    );
}

/**
    _ColorGradingUseLogC : logC space
    _ColorGradingLUTParams : //{x:1/width,y:1/height,z:height-1} 
*/
float3 ApplyColorGradingLUT(float3 c,bool _ColorGradingUseLogC,half3 _ColorGradingLUTParams){
    return ApplyLut2D(
        TEXTURE2D_ARGS(_ColorGradingLUT,sampler_linear_clamp),
        saturate(_ColorGradingUseLogC ? LinearToLogC(c) : c),
        _ColorGradingLUTParams.xyz
    );
}

/**

*/
float4 GlitchUV(float2 uv,
    float SnowFlakeIntensity=1,
    float JitterBlockSize=0.5, // [0,1]
    float JitterIntensity=0.5,
    float VerticalJumpIntensity=0.15,
    float HorizontalShake=0.5,
    float ColorDriftSpeed=0.1,float ColorDriftIntensity=1,
    float HorizontalIntensity=0.1,
    half JitterHorizontalIntensity=1,half JitterVerticalIntensity=0
    ){
    float u = uv.x;
    float v = uv.y;
    float2 time = frac(_Time.zy+0.5);

    float snowFlackPeriod = sin(N21(uv+time.x))*2;

    float snowFlake = (N21(uv * snowFlackPeriod)*2-1) * SnowFlakeIntensity;

// jitter & block
    float2 jitterUV = ceil(uv.yx * JitterBlockSize)*time.x;
    jitterUV *= lerp(0,1,half2(JitterHorizontalIntensity,JitterVerticalIntensity));

    // float jitter = N21(float2(ceil(v * JitterBlockSize),time.x)) *2-1;
    float jitter = N21(jitterUV) * 2-1;
    float jitterThreshold = 0.002+pow(JitterIntensity,3)*0.05;
    jitter *= step(jitterThreshold,abs(jitter)) * JitterIntensity;

// vertical 
    float verticalJumpTime = time.y * VerticalJumpIntensity * 10.0;
    float jump = lerp(v, frac(v + verticalJumpTime), VerticalJumpIntensity);

    float hshake = N21(float2(time.x,2)-0.5) * HorizontalShake;

    float drift = sin(jump + ColorDriftSpeed * time.x) * ColorDriftIntensity;
// return frac(drift);

    float u1 = (jitter + snowFlake + hshake) * HorizontalIntensity;
    float u2 = (jitter + snowFlake + hshake + drift ) * HorizontalIntensity;
    return float4(frac(float2(u + u1,jump)) , frac(float2(u + u2 ,jump)));
}

float4 Glitch(
    TEXTURE2D_PARAM(tex,sampler_tex),
    float2 uv,
    float SnowFlakeIntensity=1,
    float JitterBlockSize=0.5, // [0,1]
    float JitterIntensity=0.5,
    float VerticalJumpIntensity=0.15,
    float HorizontalShake=0.5,
    float ColorDriftSpeed=0.1,float ColorDriftIntensity=1,
    float HorizontalIntensity=0.1,
    float JitterHorizontalIntensity=1,float JitterVerticalIntensity=0
){
    float4 glitchUV = GlitchUV(uv,SnowFlakeIntensity,JitterBlockSize,JitterIntensity,VerticalJumpIntensity,
        HorizontalShake,ColorDriftSpeed,ColorDriftIntensity,HorizontalIntensity,
        JitterHorizontalIntensity,JitterVerticalIntensity);

    float4 c1 = SAMPLE_TEXTURE2D(tex,sampler_tex,glitchUV.xy);
    float4 c2 = SAMPLE_TEXTURE2D(tex,sampler_tex,glitchUV.zw);
    return float4(c1.r,c2.g,c1.b,1);
}

/**
    Calc vignette color

    screenUV : screen space uv[0,1]
    centerUV : screen space center ,default 0.5
    isRound : round circle or oval shape
    oval : blink eye
    vignetteRange : smooth curve 

    demo:
    float2 screenUV = i.vertex.xy / _ScaledScreenParams.xy;
    half4 col = CalcVignette(screenUV,_RoundOn,_Oval,_VignetRange,_Color1,_Color2,_Intensity);
*/
half4 CalcVignette(float2 screenUV,float2 centerUV,half isRound,half2 oval,half2 vignetteRange,half4 color1,half4 color2,half intensity){
    float aspect = _ScaledScreenParams.x/_ScaledScreenParams.y;
    float2 dir = (screenUV - centerUV) ;
    dir.x *= isRound ? aspect : 1;
    dir /= oval;

    float dist = length(dir) ;
    float atten = smoothstep(vignetteRange.x,vignetteRange.y,dist);
    // return _Color1 * atten * _Intensity;

    half4 col = lerp(color1,color2,atten)* intensity;
    return col;
}
/**
    fisheye 
*/
void ApplyLensDistorionUVOffset(inout float2 screenUV,float2 screenParams,float intensity,float amplitude=0.02,float2 centerUV=0.5,float scaleuv=1,float moveSpeed=0){
    // intensity = sin(intensity + _Time.x * moveSpeed);

    float aspect = screenParams.x/screenParams.y;
    float2 scale = float2(intensity,intensity* aspect)  * amplitude;
    float2 uv= (screenUV - centerUV) * scaleuv;

    float2 offset = uv * (1-uv.yx*uv.yx) * scale.yx;
    screenUV += offset;
}

#endif //COLORS_HLSL