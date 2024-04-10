#if !defined(MAT_CAP_LIB_HLSL)
#define MAT_CAP_LIB_HLSL

#include "MathLib.hlsl"

/**
    keyword : 
    MATCAP_UV_ROTATE
*/
half4 SampleMatCap(TEXTURE2D_PARAM(matcapTex,samplerMatCap),float3 normal,float4 mapCap_ST,float rotAngle=0){
    float3 normalView = mul(UNITY_MATRIX_V,float4(normal,0)).xyz;
    normalView = normalView*0.5+0.5;

    float2 matUV = (normalView.xy) * mapCap_ST.xy + mapCap_ST.zw;
    #if defined(MATCAP_UV_ROTATE)
        RotateUV(rotAngle,0.5,matUV/**/);
    #endif

    float4 matCap = SAMPLE_TEXTURE2D(matcapTex,samplerMatCap,matUV);
    return matCap;
}

#endif //MAT_CAP_LIB_HLSL