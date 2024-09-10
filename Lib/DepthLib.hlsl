#if !defined(DEPTH_LIB_HLSL)
#define DEPTH_LIB_HLSL

/*
    Linearize depth value sampled from the camera depth texture.
    return [0,1]

    z : depth texture
*/
float LinearizeDepth(float z)
{
    float isOrtho = unity_OrthoParams.w;
    float isPers = 1 - unity_OrthoParams.w;
    z *= _ZBufferParams.x;
    return (1 - isOrtho * z) / (isPers * z + _ZBufferParams.y);
    /**
    z = (1-far/near) * z
    ortho: (1-z)/(far/near)
    pers : 1/(z + far/near)

    */
}

/**
    screenUV -> ndc -> clip -> view
    UNITY_MATRIX_I_VP unity_MatrixInvVP

    uv : screen uv
    rawDepth : depth texture
    invVP : UNITY_MATRIX_I_VP
*/
float3 ScreenToWorldPos(float2 uv,float rawDepth,float4x4 invVP){
    #if defined(UNITY_UV_STARTS_AT_TOP)
        uv.y = 1-uv.y;
    #endif

    // linearize
    // rawDepth = Linear01Depth(rawDepth,_ZBufferParams);

    #if ! defined(UNITY_REVERSED_Z)
        rawDepth = lerp(UNITY_NEAR_CLIP_VALUE, 1, rawDepth);
    #endif

    #if defined(SHADER_API_GLES3)
    #endif

    float4 p = float4(uv*2-1,rawDepth,1);

    p = mul(invVP,p);
    return p.xyz/p.w;
}

float3 ScreenToWorldPos(float2 uv,float rawDepth){
    return ScreenToWorldPos(uv,rawDepth,UNITY_MATRIX_I_VP);
}

bool IsOrthographicCamera(){return unity_OrthoParams.w;}

/**
    return z distance to camera near plane,[near,far]

    rawDepth : depth texture
*/
float OrthographicDepthBufferToLinear(float rawDepth/*depth buffer [0,1]*/){
    #if UNITY_REVERSED_Z
        rawDepth = 1 - rawDepth;
    #endif
    return (_ProjectionParams.z - _ProjectionParams.y) * rawDepth + _ProjectionParams.y;
}

/**
    output linear hclip pos.z, all projection
*/
float CalcLinearEyeDepth(float4 posHClip){
    return IsOrthographicCamera()? OrthographicDepthBufferToLinear(posHClip.z) : LinearEyeDepth(posHClip.w,_ZBufferParams);
}

/*
    rawDepth : depth texture,all projection

    float eyeDepth = far * near / ((near - far) * depthTex + far);
*/
float CalcLinearEyeDepth(float rawDepth){
    // return IsOrthographicCamera()? OrthographicDepthBufferToLinear(rawDepth) : LinearEyeDepth(rawDepth,_ZBufferParams);
    return lerp(_ProjectionParams.y,_ProjectionParams.z,LinearizeDepth(rawDepth));
}
/**
    too far or to near
*/
bool IsTooFar(float rawDepth){
    return rawDepth > 0.99999 || rawDepth < 0.00001;
}

#endif //DEPTH_LIB_HLSL