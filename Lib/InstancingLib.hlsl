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
/** macro -> string



UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    UNITY_DOTS_INSTANCED_PROP(float4, _BaseColor)
    UNITY_DOTS_INSTANCED_PROP(float , _Cutoff)
    UNITY_DOTS_INSTANCED_PROP(float , _Glossiness)
    UNITY_DOTS_INSTANCED_PROP(float , _Metallic)
    UNITY_DOTS_INSTANCED_PROP(float , _Surface)
UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)



cbuffer UnityDOTSInstancing_##MaterialPropertyMetadata {
    // unity_DOTSInstancing<Type><Size>_Metadata<Name>;\
    // name ## _DOTSInstancingOverrideMode = kDotsInstancedPropOverrideSupported(0,1,2)

    uint unity_DOTSInstancingF16_Metadata_BaseColor; 
    static const int _BaseColor_DOTSInstancingOverrideMode = kDotsInstancedPropOverrideSupported

}

UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4, _BaseColor);
_BaseColor_DOTSInstancingOverrideMode == kDotsInstancedPropOverrideSupported ?LoadDOTSInstancedData_float4(unity_DOTSInstancingF16_Metadata_BaseColor) :
_BaseColor_DOTSInstancingOverrideMode == kDotsInstancedPropOverrideRequired ? LoadDOTSInstancedDataOverridden_float4(unity_DOTSInstancingF16_Metadata_BaseColor) : _BaseColor

*/
#if !defined(INSTANCING_LIB_HLSL)
#define INSTANCING_LIB_HLSL

/**
          CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _Color;
            CBUFFER_END

            #if defined(UNITY_DOTS_INSTANCING_ENABLED)
            UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
                UNITY_DOTS_INSTANCED_PROP(float4,_Color)
                UNITY_DOTS_INSTANCED_PROP(float4,_MainTex_ST)
            UNITY_DOTS_INSTANCING_END(MaterialPropertyMetadata)

            #define _Color UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4,_Color)
            #define _MainTex_ST UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(float4,_MainTex_ST)
            #endif
*/
#if defined(UNITY_DOTS_INSTANCING_ENABLED)
    // like,  UNITY_DOTS_INSTANCING_START(MaterialPropertyMetadata)
    #define DOTS_CBUFFER_START(name) cbuffer UnityDOTSInstancing_##name {
    #define DOTS_CBUFFER_END }
    #define DEF_VAR(type,name) UNITY_DOTS_INSTANCED_PROP(type,name)
    #define GET_VAR(type,name) UNITY_ACCESS_DOTS_INSTANCED_PROP_WITH_DEFAULT(type,name)


    // complements for UnityDOTSInstancing.hlsl
    #define DEFINE_DOTS_LOAD_INSTANCE_VECTOR(type, width, conv, sizeof_type) \
    type##width LoadDOTSInstancedData_##type##width(uint metadata) \
    { \
        uint address = ComputeDOTSInstanceDataAddress(metadata, sizeof_type * width); \
        return conv(DOTSInstanceData_Load##width(address)); \
    } \
    type##width LoadDOTSInstancedDataOverridden_##type##width(uint metadata) \
    { \
        uint address = ComputeDOTSInstanceDataAddressOverridden(metadata, sizeof_type * width); \
        return conv(DOTSInstanceData_Load##width(address)); \
    } \
    type##width LoadDOTSInstancedData_##type##width(type##width default_value, uint metadata) \
    { \
        uint address = ComputeDOTSInstanceDataAddressOverridden(metadata, sizeof_type * width); \
        return IsDOTSInstancedProperty(metadata) ? \
            conv(DOTSInstanceData_Load##width(address)) : default_value; \
    }    
    //--------- min16floats
    DEFINE_DOTS_LOAD_INSTANCE_VECTOR(min16float, 2, asfloat, 2)
    DEFINE_DOTS_LOAD_INSTANCE_VECTOR(min16float, 3, asfloat, 2)

#endif

#endif //INSTANCING_LIB_HLSL