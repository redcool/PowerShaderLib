#if !defined(MATERIAL_LIB_HLSL)
#define MATERIAL_LIB_HLSL

#include "Colors.hlsl"

#undef HALF_MIN
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#undef HALF_MIN_SQRT
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

/**
    float4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMaskMap,sampler_MetallicMaskMap,uv);
    SplitPbrMaskTexture(
        data.metallic,//out
        data.smoothness, //out
        data.occlusion, //out
        pbrMask, // pbrMask texture
        int3(_MetallicChannel,_SmoothnessChannel,_OcclusionChannel), // int3(0,1,2)
        float3(_Metallic,_Smoothness,_Occlusion), // pbrMask sliders
        _InvertSmoothnessOn // use roughness
    );
*/
void SplitPbrMaskTexture(out half m,out half s,out half o,half4 pbrMaskTex,int3 pbrMaskChannels,half3 pbrMaskRatios,bool isSmoothnessReversed=false){
    m = pbrMaskTex[pbrMaskChannels.x] * pbrMaskRatios.x;
    s = pbrMaskTex[pbrMaskChannels.y] * pbrMaskRatios.y;
    s = isSmoothnessReversed? 1-s : s;
    
    o = lerp(1,pbrMaskTex[pbrMaskChannels.z],pbrMaskRatios.z);
}

/**
    planeMode , 0 : xz,1 : xy, 2 : yz
*/
float2 CalcWorldUV(float3 worldPos,half planeMode,half4 texST){
    float2 uvs[3] = {worldPos.xz,worldPos.xy,worldPos.yz};
    return uvs[planeMode] * texST.xy + texST.zw;
}

void ApplyDetailPbrMask(inout half metallic,inout half smoothness,inout half occlusion,half4 detailPbrMaskTex,half3 detailPbrMaskScale,half3 detailPbrMaskApplyRate){
    SplitPbrMaskTexture(detailPbrMaskTex.x/**/,detailPbrMaskTex.y/**/,detailPbrMaskTex.z/**/,detailPbrMaskTex,int3(0,1,2),detailPbrMaskScale);
    // remove high light flickers
    detailPbrMaskTex.z = saturate(detailPbrMaskTex.z);

    half3 lerpValue = lerp(half3(metallic,smoothness,occlusion),detailPbrMaskTex.xyz,detailPbrMaskApplyRate);
    metallic = lerpValue.x;
    smoothness = lerpValue.y;
    occlusion = lerpValue.z;
}


void CalcRoughness(inout float rough,inout float a,inout float a2,float smoothness){
    rough = 1 - smoothness;
    a = max(rough * rough , HALF_MIN_SQRT);
    a2 = max(a*a,HALF_MIN);
}

void CalcDiffuseSpecularColor(out float3 diffColor,out float3 specColor,float4 albedo,float metallic){
    diffColor = albedo.xyz * (1- metallic);
    specColor = lerp(0.04,albedo.xyz,metallic);
}

float4 TriplanarSample(TEXTURE2D_PARAM(tex,sampler_tex),float3 worldPos,float3 normal,float4 tilingOffset=float4(1,1,0,0)){
    float3 weights = abs(normal)/dot(normal,1);
    float4 c = SAMPLE_TEXTURE2D(tex,sampler_tex,worldPos.yz * tilingOffset.xy + tilingOffset.zw) * weights.x;
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,worldPos.xz * tilingOffset.xy + tilingOffset.zw) * weights.y;
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,worldPos.xy * tilingOffset.xy + tilingOffset.zw) * weights.z;
    return c;
}

void ApplyAlphaPremultiply(inout float3 albedo,inout float alpha,float metallic){
    albedo *= alpha;
    alpha = lerp(alpha + 0.04,1,metallic);
}

/**
    calc albedo,
    alpha,
    alphaTest(ALPHA_TEST),
    isAlphaPremultiply

    ALPHA_TEST
*/
void CalcSurfaceColor(out half3 albedo,out half alpha,half4 mainTex,half4 color,half cutoff,float metallic,bool isAlphaPremultiply,half alphaChanel=3){
    mainTex *= color;
    albedo = mainTex.xyz;
    alpha = mainTex[alphaChanel];
    #if defined(ALPHA_TEST)
        clip(alpha - cutoff);
    #endif
    if(isAlphaPremultiply){
        ApplyAlphaPremultiply(albedo/**/,alpha/**/,metallic);
    }
}

/**
    CalcEmission(emission,_EmissionColor,_EmissionColor.w);
*/
half3 CalcEmission(half4 tex,half3 color,half mask){
    return tex.xyz * tex.w * color * mask;
}

/**
    emissionHeight, [min,maxOffset]

    half upFaceAtten = 1 - saturate(dot(worldNormal,half3(0,1,0)));
    upFaceAtten = lerp(1,upFaceAtten,_EmissionHeightColorNormalAttenOn);

    ApplyHeightEmission(emission,worldPos,upFaceAtten);
*/
void ApplyHeightEmission(inout float3 emissionColor,float3 worldPos,float globalAtten,half2 emissionHeight,half4 emissionHeightColor){
    // get transformed y from M
    float maxHeight = length(half3(UNITY_MATRIX_M._12,UNITY_MATRIX_M._22,UNITY_MATRIX_M._32));
    maxHeight += emissionHeight.y; // apply height offset

    float rate = 1 - saturate((worldPos.y - emissionHeight.x)/ (maxHeight - emissionHeight.x +0.0001));
    rate *= globalAtten;
    // half4 heightEmission = emissionHeightColor * rate;
    half3 heightEmission = lerp(emissionColor.xyz,emissionHeightColor.xyz,rate);
    emissionColor = heightEmission ;
}

half WorldHeightTilingUV(float3 worldPos,float storeyHeight){
    return (worldPos.y/storeyHeight); // remove floor, flicker
}

float NoiseSwitchLight(float2 quantifyNum,float lightOffIntensity){
    float n = N21(quantifyNum);
    return frac(smoothstep(lightOffIntensity,1,n));
}

/**
    storeyWindowInfo : (WindowCountX WindowCountY LightOffPercent LightSwitchPercent)
    storeyLightOpaque : lightOn, alpha = 1
*/
void ApplyStoreyEmission(inout float3 emissionColor,inout float alpha,float3 worldPos,float2 uv,half storeyLightSwitchSpeed,half4 storeyWindowInfo,half storeyLightOpaque){
    // auto light swidth
    float tn = NoiseSwitchLight(round(_Time.x * storeyLightSwitchSpeed) , storeyWindowInfo.w);
    float n = NoiseSwitchLight(floor(uv.xy*storeyWindowInfo.xy) + tn,storeyWindowInfo.z);
    emissionColor *= n;

    branch_if(storeyLightOpaque)
        alpha = Luminance(emissionColor) > 0.1? 1 : alpha;
}

void ApplyStoreyLineEmission(inout float3 emissionColor,half4 lineNoise,float3 worldPos,float4 vertexColor,float nv,float3 storeyLineColor){
    // half lineNoise = InterleavedGradientNoise(screenUV);
    float invNV = 1-nv;
    half atten = vertexColor.x * lineNoise.x * (invNV * invNV);
    half3 lineColor = storeyLineColor.xyz * saturate(atten) ;

    emissionColor = lerp(emissionColor,lineColor,vertexColor.x>0.1);
}



#endif //MATERIAL_LIB_HLSL