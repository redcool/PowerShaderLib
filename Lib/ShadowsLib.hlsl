#if ! defined(SHADOWS_LIB_HLSL)
#define SHADOWS_LIB_HLSL

/**
    // retarget other texelSize
    #define _MainLightShadowmapSize _BigShadowMap_TexelSize 

*/
float SampleShadowmap(TEXTURE2D_SHADOW_PARAM(shadowMap,sampler_ShadowMap),float4 shadowCoord,float shadowSoftScale){

#if defined(SHADER_API_MOBILE)
    static const int SOFT_SHADOW_COUNT = 2;
    static const float SOFT_SHADOW_WEIGHTS[] = {0.2,0.4,0.4};
#else
    static const int SOFT_SHADOW_COUNT = 4;
    static const float SOFT_SHADOW_WEIGHTS[] = {0.2,0.25,0.25,0.15,0.15};
#endif 

    float shadow = SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_ShadowMap, shadowCoord.xyz);

    // return shadow;
    #if defined(_SHADOWS_SOFT)
        shadow *= SOFT_SHADOW_WEIGHTS[0];

        float2 psize = _MainLightShadowmapSize.xy * shadowSoftScale;
        const float2 uvs[] = { float2(-psize.x,0),float2(0,psize.y),float2(psize.x,0),float2(0,-psize.y) };

        float2 offset = 0;
        for(int x=0;x< SOFT_SHADOW_COUNT;x++){
            offset = uvs[x] ;
            shadow +=SAMPLE_TEXTURE2D_SHADOW(shadowMap,sampler_ShadowMap, float3(shadowCoord.xy + offset,shadowCoord.z)) * SOFT_SHADOW_WEIGHTS[x+1];
        }
    #endif 
    
    return shadow;
}


#endif //SHADOWS_LIB_HLSL