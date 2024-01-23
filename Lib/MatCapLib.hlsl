#if !defined(MAT_CAP_LIB_HLSL)
#define MAT_CAP_LIB_HLSL

half4 SampleMatCap(TEXTURE2D_PARAM(matcapTex,samplerMatCap),float3 normal,float4 mapCap_ST){
    float3 normalView = mul(UNITY_MATRIX_V,float4(normal,0)).xyz;
    normalView = normalView*0.5+0.5;

    float2 matUV = (normalView.xy) * mapCap_ST.xy + mapCap_ST.zw;
    float4 matCap = SAMPLE_TEXTURE2D(matcapTex,samplerMatCap,matUV);
    return matCap;
}

#endif //MAT_CAP_LIB_HLSL