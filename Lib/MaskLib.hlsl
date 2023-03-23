#if !defined(MASK_LIB_HLSL)
#define MASK_LIB_HLSL

/**
    Get Target Mask as intenstiy
*/
half GetMaskForIntensity(half3 maskData,half maskFrom,half maskUsage,half maskExpectUsage){
    half mask = maskData[maskFrom];
    return lerp(1,mask,maskUsage == maskExpectUsage);
}

half GetMaskForIntensity(half4 maskData,half maskFrom,half maskUsage,half maskExpectUsage){
    half mask = maskData[maskFrom];
    return lerp(1,mask,maskUsage == maskExpectUsage);
}

/**
    Get Target Mask
*/
half GetMask(half3 maskData,half maskFrom){
    return maskData[maskFrom];
}

half GetMask(half4 maskData,half maskFrom){
    return maskData[maskFrom];
}

/**
    unity gui mask
*/
half4 GetUIMask(float4 vertex,float hclipPosW,float4 clipRect,float2 uiMaskSoftness){
    float2 pixelSize = hclipPosW;
    pixelSize /= abs(mul((float2x2)UNITY_MATRIX_P,_ScreenParams.xy));

    float4 clampedRect = clamp(clipRect,-2e10,2e10);
    float2 maskUV = (vertex.xy - clampedRect.xy)/(clampedRect.zw - clampedRect.xy);
    float4 mask = half4(vertex.xy*2 - clampedRect.xy - clampedRect.zw, 0.25/(0.25*half2(uiMaskSoftness)+abs(pixelSize)) );
    return mask;
}

#endif //MASK_LIB_HLSL