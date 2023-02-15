#if !defined(MATERIAL_LIB_HLSL)
#define MATERIAL_LIB_HLSL

float4 SplitPbrMaskTexture(float4 pbrMaskTex,int3 pbrChannels,float3 pbrMaskRatios,bool isSmoothnessReversed=false){
    float m = pbrMaskTex[pbrChannels.x];
    float s = pbrMaskTex[pbrChannels.y];
    float o = pbrMaskTex[pbrChannels.z];
    s = lerp(s,1-s,isSmoothnessReversed);
    return float4(float3(m,s,o)*pbrMaskRatios,pbrMaskTex.w);
}

#endif //MATERIAL_LIB_HLSL