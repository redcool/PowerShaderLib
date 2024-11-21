/**
    handle Dots Instancing and CBuffer
    Graphics.DrawInstanced not high efficient on srp batch
demo:
    #if defined(UNITY_DOTS_INSTANCING_ENABLED)
    #define _Color GET_VAR(float4,_Color)
    #define _MainTex_ST GET_VAR(float4,_MainTex_ST)
    #endif

    CBUFFER_START(UnityPerMaterial)
        DEF_VAR(float4,_Color)
        DEF_VAR(float4,_MainTex_ST)
    CBUFFER_END
*/
#if !defined(INSTANCING_LIB_HLSL)
#define INSTANCING_LIB_HLSL

#if defined(UNITY_DOTS_INSTANCING_ENABLED)
    // like,  UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    #undef CBUFFER_START
    #define CBUFFER_START(name) cbuffer UnityDOTSInstancing_##name {
    
    #define DEF_VAR(type,name) UNITY_DOTS_INSTANCED_PROP(type,name)
    #define GET_VAR(type,name) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type,name)
#else
    
    #define DEF_VAR(type,name) type name;
    #define GET_VAR(type,name) name
#endif

#endif //INSTANCING_LIB_HLSL