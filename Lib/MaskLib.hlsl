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

#endif //MASK_LIB_HLSL