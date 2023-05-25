#if !defined(MATERIAL_LIB_HLSL)
#define MATERIAL_LIB_HLSL

#undef HALF_MIN
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#undef HALF_MIN_SQRT
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

/**
    float4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMaskMap,sampler_MetallicMaskMap,uv);
    SplitPbrMaskTexture(pbrMask,
        int3(_MetallicChannel,_SmoothnessChannel,_OcclusionChannel), // int3(0,1,2)
        float3(_Metallic,_Smoothness,_Occlusion),
        data.metallic,//out
        data.smoothness, //out
        data.occlusion, //out
        _InvertSmoothnessOn
    );
*/
void SplitPbrMaskTexture(out float m,out float s,out float o,float4 pbrMaskTex,int3 pbrMaskChannels,float3 pbrMaskRatios,bool isSmoothnessReversed=false){
    m = pbrMaskTex[pbrMaskChannels.x] * pbrMaskRatios.x;
    s = pbrMaskTex[pbrMaskChannels.y] * pbrMaskRatios.y;
    s = lerp(s,1-s,isSmoothnessReversed);
    
    o = lerp(1,pbrMaskTex[pbrMaskChannels.z],pbrMaskRatios.z);
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

#endif //MATERIAL_LIB_HLSL