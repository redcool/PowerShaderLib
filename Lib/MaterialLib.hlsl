#if !defined(MATERIAL_LIB_HLSL)
#define MATERIAL_LIB_HLSL

void SplitPbrMaskTexture(float4 pbrMaskTex,int3 pbrMaskChannels,float3 pbrMaskRatios,out float m,out float s,out float o,bool isSmoothnessReversed=false){
    m = pbrMaskTex[pbrMaskChannels.x] * pbrMaskRatios.x;
    s = pbrMaskTex[pbrMaskChannels.y] * pbrMaskRatios.y;
    s = lerp(s,1-s,isSmoothnessReversed);
    
    o = lerp(1,pbrMaskTex[pbrMaskChannels.z],pbrMaskRatios.z);
}

#endif //MATERIAL_LIB_HLSL