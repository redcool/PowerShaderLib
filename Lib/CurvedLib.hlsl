#if !defined(CURVED_LIB_HLSL)
#define CURVED_LIB_HLSL

/**
    return an offset position

    sidewayScale : x pos offset
    backwardScale : y pos offset 
*/
float2 CalcCurvedPos(float3 camPos,float3 worldPos,float sidewayScale,float backwardScale){
    float3 dir = camPos - worldPos;
    float z2 = dir.z * dir.z;
    return float2(sidewayScale,backwardScale) * z2;
}

#endif //CURVED_LIB_HLSL