#if !defined(KERNEL_DEFINES_HLSL)
#define KERNEL_DEFINES_HLSL
//-- define 
#define DEF_OFFSETS_3X3(varName,texelSize)\
static const float2 varName[] = {\
    float2(-texelSize.x,texelSize.y),\
    float2(0,texelSize.y),\
    float2(texelSize.x,texelSize.y),\
    float2(-texelSize.x,0),\
    float2(0,0),\
    float2(texelSize.x,0),\
    float2(-texelSize.x,-texelSize.y),\
    float2(0,-texelSize.y),\
    float2(texelSize.x,-texelSize.y),\
}

/**
            (0,1)
    (-1,0)  (0,0)     (1,0)
            (0,-1)
*/
#define DEF_OFFSETS_2X2(varName,texelSize)\
static const float2 varName[] = {\
    float2(-texelSize.x,0),\
    float2(texelSize.x,0),\
    float2(0,0),\
    float2(0,-texelSize.y),\
    float2(0,texelSize.y),\
}

/**
    (-1,1)      (1,1)
           (0,0)
    (-1,-1)     (1,-1)
*/
#define DEF_OFFSETS_2X2_CROSS(varName,texelSize)\
static const float2 varName[] = {\
    float2(-texelSize.x,texelSize.y),\
    float2(texelSize.x,texelSize.y),\
    float2(0,0),\
    float2(-texelSize.x,-texelSize.y),\
    float2(texelSize.x,-texelSize.y),\
}

#define DEF_KERNELS_3X3(varName,i0,i1,i2,i3,i4,i5,i6,i7,i8)\
static const float varName[] = {\
    i0,i1,i2,i3,i4,i5,i6,i7,i8\
}

#define DEF_KERNELS_2X2(varName,i0,i1,i2,i3,i4)\
static const float varName[] = {\
    i0,i1,i2,i3,i4\
}
/**
    define calc kernels
*/
#define DEF_CALC_KERNELS(funcName,tex,uv,texelSizeScale,count)\
float4 funcName(sampler2D tex,float2 uv,float texelSizeScale,float2 offsets[count],float kernels[count]){\
    float4 col = 0;\
    for(int x=0;x<count;x++){\
        col += tex2D(tex,uv + offsets[x] * texelSizeScale) * kernels[x];\
    }\
    return col;\
}

#define DEF_CALC_KERNELS_TEXTURE(funcName,tex,texState,uv,texelSizeScale,count)\
float4 funcName(TEXTURE2D_PARAM(tex,texState),float2 uv,float texelSizeScale,float2 offsets[count],float kernels[count]){\
    float4 col = 0;\
    for(int x=0;x<count;x++){\
        col += SAMPLE_TEXTURE2D(tex,texState,uv + offsets[x] * texelSizeScale) * kernels[x];\
    }\
    return col;\
}



// ====== kernels 3x3
#define rcp16 0.0625
DEF_KERNELS_3X3(kernels_sharpen,-1,-1,-1,-1,9,-1,-1,-1,-1);
DEF_KERNELS_3X3(kernels_blur,1*rcp16,2*rcp16,1*rcp16,2*rcp16,4*rcp16,2*rcp16,1*rcp16,2*rcp16,1*rcp16);
DEF_KERNELS_3X3(kernels_edgeDetection,1,1,1,1,-8,1,1,1,1);

// ====== kernels 2x2
DEF_KERNELS_2X2(kernels_sharpen_2x2,-1,-1,5,-1,-1);
DEF_KERNELS_2X2(kernels_blur_2x2,1.5*rcp16,1.5*rcp16,4*rcp16,1.5*rcp16,1.5*rcp16);
DEF_KERNELS_2X2(kernels_edgeDetection_2x2,1,1,-8,1,1);

/* functions, call
col = CalcKernel_3x3(_CameraOpaqueTexture, screenUV,_TexelSizeScale,offsets_3x3,kernels_edgeDetection);
col = CalcKernel_2x2(_CameraOpaqueTexture,screenUV,_TexelSizeScale,offsets_2x2,kernels_sharpen_2x2);
*/
DEF_CALC_KERNELS(CalcKernel_3x3,tex,uv,texelSizeScale,9);
DEF_CALC_KERNELS(CalcKernel_2x2,tex,uv,texelSizeScale,5);


DEF_CALC_KERNELS_TEXTURE(CalcKernelTexture_3x3,tex,texState,uv,texelSizeScale,9);
DEF_CALC_KERNELS_TEXTURE(CalcKernelTexture_2x2,tex,texState,uv,texelSizeScale,5);

#endif //KERNEL_DEFINES_HLSL