#if !defined(TEXTURE_LIB_HLSL)
#define TEXTURE_LIB_HLSL

/**
    USE_SAMPLER2D : sampler2D
    !USE_SAMPLER2D : Texture2D
*/

#if defined(USE_SAMPLER2D)
    #undef TEXTURE2D_PARAM
    #define TEXTURE2D_PARAM(textureName, samplerName)  sampler2D textureName

    #undef TEXTURE2D_ARGS
    #define TEXTURE2D_ARGS(textureName,samplerName) textureName

    #undef SAMPLE_TEXTURE2D
    #define SAMPLE_TEXTURE2D(textureName,samplerName,uv) tex2D(textureName,(uv))

    #undef TEXTURE2D
    #define TEXTURE2D(textureName) sampler2D textureName

    #undef SAMPLE_TEXTURE2D_LOD
    #define SAMPLE_TEXTURE2D_LOD(tex,sampler_Tex,uv,lod) tex2Dlod(tex,float4(uv,0,lod))
#endif

/**
    _MainTex,_BaseMap
*/
#if defined(USE_BASEMAP) || defined(MAINTEX_TO_BASEMAP)
    #define _MainTex _BaseMap 
    #define _MainTex_ST _BaseMap_ST
    #define sampler_MainTex sampler_BaseMap
#endif

#if defined(USE_MAINTEX) || defined(BASEMAP_TO_MAINTEX)
    #define _BaseMap _MainTex
    #define _BaseMap_ST _MainTex_ST
    #define sampler_BaseMap sampler_MainTex
#endif

#endif //TEXTURE_LIB_HLSL