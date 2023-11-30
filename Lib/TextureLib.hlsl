#if !defined(TEXTURE_LIB_HLSL)
#define TEXTURE_LIB_HLSL

/**
    USE_TEXTURE2D : Texture
    USE_SAMPLER2D : sampler2D
*/

#if defined(USE_SAMPLER2D)
    #define TEXTURE2D_PARAM(textureName, samplerName)  sampler2D textureName
    #define TEXTURE2D_ARGS(textureName,samplerName) textrueName
    #define SAMPLE_TEXTURE2D(depthTex,depthTexSampler,uv) tex2D(depthTex,uv)
    
#endif

/**
    _MainTex,_BaseMap
*/
#if defined(USE_BASEMAP)
    #define _MainTex _BaseMap 
    #define _MainTex_ST _BaseMap_ST
    #define sampler_MainTex sampler_BaseMap
#endif

#if defined(USE_MAINTEX)
    #define _BaseMap _MainTex
    #define _BaseMap_ST _MainTex_ST
    #define sampler_BaseMap sampler_MainTex
#endif

#endif //TEXTURE_LIB_HLSL