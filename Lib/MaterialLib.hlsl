#if !defined(MATERIAL_LIB_HLSL)
#define MATERIAL_LIB_HLSL

/**
    float4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMaskMap,sampler_MetallicMaskMap,uv);
    SplitPbrMaskTexture(pbrMask,
        int3(_MetallicChannel,_SmoothnessChannel,_OcclusionChannel),
        float3(_Metallic,_Smoothness,_Occlusion),
        data.metallic,//out
        data.smoothness, //out
        data.occlusion, //out
        _InvertSmoothnessOn
    );
*/
void SplitPbrMaskTexture(float4 pbrMaskTex,int3 pbrMaskChannels,float3 pbrMaskRatios,out float m,out float s,out float o,bool isSmoothnessReversed=false){
    m = pbrMaskTex[pbrMaskChannels.x] * pbrMaskRatios.x;
    s = pbrMaskTex[pbrMaskChannels.y] * pbrMaskRatios.y;
    s = lerp(s,1-s,isSmoothnessReversed);
    
    o = lerp(1,pbrMaskTex[pbrMaskChannels.z],pbrMaskRatios.z);
}

void SplitDiffuseSpecularColor(float4 albedo,float metallic,out float3 diffColor,out float3 specColor){
    diffColor = albedo.xyz * (1- metallic);
    specColor = lerp(0.04,albedo.xyz,metallic);
}

float4 TriplanarSample(TEXTURE2D_PARAM(tex,sampler_tex),float3 worldPos,float3 normal,float4 tilingOffset=float4(1,1,0,0)){
    float3 weights = normal/dot(normal,1);
    float4 c = SAMPLE_TEXTURE2D(tex,sampler_tex,worldPos.yz * tilingOffset.xy + tilingOffset.zw) * weights.x;
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,worldPos.xz * tilingOffset.xy + tilingOffset.zw) * weights.y;
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,worldPos.xy * tilingOffset.xy + tilingOffset.zw) * weights.z;
    return c;
}

#endif //MATERIAL_LIB_HLSL