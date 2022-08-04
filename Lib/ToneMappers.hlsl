#if !defined(TONE_MAPPERS_HLSL)
#define TONE_MAPPERS_HLSL

//--------------------------------------------------------------------------------------
// AMD Tonemapper
//--------------------------------------------------------------------------------------
// General tonemapping operator, build 'b' term.
float ColToneB(float hdrMax, float contrast, float shoulder, float midIn, float midOut) 
{
    return
        -((-pow(midIn, contrast) + (midOut*(pow(hdrMax, contrast*shoulder)*pow(midIn, contrast) -
            pow(hdrMax, contrast)*pow(midIn, contrast*shoulder)*midOut)) /
            (pow(hdrMax, contrast*shoulder)*midOut - pow(midIn, contrast*shoulder)*midOut)) /
            (pow(midIn, contrast*shoulder)*midOut));
}

// General tonemapping operator, build 'c' term.
float ColToneC(float hdrMax, float contrast, float shoulder, float midIn, float midOut) 
{
    return (pow(hdrMax, contrast*shoulder)*pow(midIn, contrast) - pow(hdrMax, contrast)*pow(midIn, contrast*shoulder)*midOut) /
           (pow(hdrMax, contrast*shoulder)*midOut - pow(midIn, contrast*shoulder)*midOut);
}

// General tonemapping operator, p := {contrast,shoulder,b,c}.
float ColTone(float x, float4 p) 
{ 
    float z = pow(x, p.r); 
    return z / (pow(z, p.g)*p.b + p.a); 
}

float3 AMDTonemapper(float3 color)
{
    static float hdrMax = 16.0; // How much HDR range before clipping. HDR modes likely need this pushed up to say 25.0.
    static float contrast = 2.0; // Use as a baseline to tune the amount of contrast the tonemapper has.
    static float shoulder = 1.0; // Likely don�t need to mess with this factor, unless matching existing tonemapper is not working well..
    static float midIn = 0.18; // most games will have a {0.0 to 1.0} range for LDR so midIn should be 0.18.
    static float midOut = 0.18; // Use for LDR. For HDR10 10:10:10:2 use maybe 0.18/25.0 to start. For scRGB, I forget what a good starting point is, need to re-calculate.

    float b = ColToneB(hdrMax, contrast, shoulder, midIn, midOut);
    float c = ColToneC(hdrMax, contrast, shoulder, midIn, midOut);

    #define EPS 1e-6f
    float peak = max(color.r, max(color.g, color.b));
    peak = max(EPS, peak);

    float3 ratio = color / peak;
    peak = ColTone(peak, float4(contrast, shoulder, b, c) );
    // then process ratio

    // probably want send these pre-computed (so send over saturation/crossSaturation as a constant)
    float crosstalk = 4.0; // controls amount of channel crosstalk
    float saturation = contrast; // full tonal range saturation control
    float crossSaturation = contrast*16.0; // crosstalk saturation

    float white = 1.0;

    // wrap crosstalk in transform
    ratio = pow(abs(ratio), saturation / crossSaturation);
    ratio = lerp(ratio, white, pow(peak, crosstalk));
    ratio = pow(abs(ratio), crossSaturation);

    // then apply ratio to peak
    color = peak * ratio;
    return color;
}

//--------------------------------------------------------------------------------------
// TonemapWithWeight
//--------------------------------------------------------------------------------------
float max3(float3 c){return max(c.x,max(c.y,c.z));}
float3 Tonemap(float3 color){
    return color * rcp(max3(color)+1.0);
}

float3 TonemapWithWeight(float3 color,float w){
    return color * rcp(max3(color)+1.0) * w;
}

//--------------------------------------------------------------------------------------
// Reinhard
//--------------------------------------------------------------------------------------
float3 Reinhard(float3 color){
    return color/(color+1.0);
}
//--------------------------------------------------------------------------------------
// Hable's filmic
//--------------------------------------------------------------------------------------
float3 Uncharted2TonemapOp(float3 x)
{
    float A = 0.15;
    float B = 0.50;
    float C = 0.10;
    float D = 0.20;
    float E = 0.02;
    float F = 0.30;

    return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float3 Uncharted2Tonemap(float3 color)
{
    float W = 11.2;    
    return Uncharted2TonemapOp(2.0 * color) / Uncharted2TonemapOp(W);
}

//--------------------------------------------------------------------------------------
// https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/
//--------------------------------------------------------------------------------------
float3 ACESFilm(float3 x)
{
    float a = 2.51f;
    float b = 0.03f;
    float c = 2.43f;
    float d = 0.59f;
    float e = 0.14f;
    return saturate((x*(a*x + b)) / (x*(c*x + d) + e));
}

//--------------------------------------------------------------------------------------
// The tone mapper used in HDRToneMappingCS11
//--------------------------------------------------------------------------------------
float3 DX11DSK(float3 color)
{
    float  MIDDLE_GRAY = 0.72f;
    float  LUM_WHITE = 1.5f;

    // Tone mapping
    color.rgb *= MIDDLE_GRAY;
    color.rgb *= (1.0f + color/LUM_WHITE);
    color.rgb /= (1.0f + color);
    
    return color;
}

float3 Exposure(float3 color,float exposure){
    return 1 - exp(-color * exposure);
}

float3 GTTone(float3 x){
    /**
    GT Tonemap.
    Uchimura 2017, "HDR theory and practice"
    JP: https://www.desmos.com/calculator/mbkwnuihbd
    EN: https://www.desmos.com/calculator/gslcdxvipg

    P : float
        max display brightness
    a : float
        contrast
    m : float
        linear section start
    l : float
        linear section length
    c : float
        black
    b : float
        pedestal
    */
    float P=2.0f;
    float a = 1.0f;
    float m=0.22f;
    float l = 0.4f;
    float c=1.33f;
    float b=0.0f;

    float l0 = (P-m)*l/a;
    float S0 = m+l0;
    float S1 = m+a*l0;
    float C2 = (a*P)/(P-S1+1e-05);
    float CP = -C2/P;

    float3 w0 = 1.0 - smoothstep(0,m,x);
    float3 w2 = step(m+l0,x);
    float3 w1 = 1.0-w0-w2;

    float3 T = m* pow(x/m,c) + b;
    float3 S = P-(P-S1)* exp(CP * (x-S0));
    float3 L = m+a*(x-m);

    return T*w0 + L*w1+S*w2;
}

#endif //TONE_MAPPERS_HLSL