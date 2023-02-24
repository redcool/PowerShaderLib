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
    diffColor = albedo * (1- metallic);
    specColor = lerp(0.04,albedo,metallic);
}

#endif //MATERIAL_LIB_HLSL