/**

*/

#if !defined(BILLBOARD_LIB_HLSL)
#define BILLBOARD_LIB_HLSL


#if defined(ROTATE_X_AXIS) || defined(ROTATE_Y_AXIS) || defined(ROTATE_Z_AXIS)
#define ROTATE_AXIS_ON 
#endif

/**
    get rotated matrix (x,y,z)
    3 keywords for 3 axis

    ROTATE_X_AXIS : x
    ROTATE_Y_AXIS : y
    ROTATE_Z_AXIS : z
*/
float3x3 GetRotMat(half rotDegree){
    float2 cs = (float2)0;
    sincos(radians(rotDegree),cs.y,cs.x);

    #if defined(ROTATE_X_AXIS)
    return float3x3(
        1,0,0,
        0,cs.x,-cs.y,
        0,cs.y,cs.x
    );
    #elif defined(ROTATE_Y_AXIS)
    return float3x3(
        cs.x,0,cs.y,
        0,1,0,
        -cs.y,0,cs.x
    );
    #elif defined(ROTATE_Z_AXIS)
    return float3x3(
        cs.x,-cs.y,0,
        cs.y,cs.x,0,
        0,0,1
    );
    #endif
    return float3x3(1,0,0,0,1,0,0,0,1);
}
/**
    calc vertex (scale,rotate) in view space
*/
float3 CalcPosOffsetViewSpace(float3 vertex,bool isFullFaceCamera,half rotDegree=0){
    float3x3 camRotMat = (float3x3)UNITY_MATRIX_V;
    #if defined(ROTATE_AXIS_ON)
    camRotMat = mul(GetRotMat(rotDegree),camRotMat);
    #endif

    float sx = unity_ObjectToWorld._11;
    float sy = unity_ObjectToWorld._22;
    // exactly axis length
    // sx = length(unity_ObjectToWorld._11_21_31);
    // sy = length(unity_ObjectToWorld._12_22_32);

    float3 vertexOffset = float3(sx,sy,0) * vertex.xyz;
    float3 vertexRotate = mul(camRotMat,float3(0,vertex.y * sy,0));

    vertexOffset = isFullFaceCamera ? vertexOffset : float3(vertexOffset.x,0,vertexOffset.z) + vertexRotate;

    return vertexOffset;
}

/**
    rotate vertex ,face to camera
*/
float4 TransformBillboardObjectToHClip(float3 vertex,bool isFullFaceCamera,half rotDegree=0){
    float3 vertexOffset = CalcPosOffsetViewSpace(vertex,isFullFaceCamera,rotDegree);
    return mul(UNITY_MATRIX_P,
        mul(UNITY_MATRIX_MV,float4(0,0,0,1)) + float4(vertexOffset,0)
    );
}

/**
    2 use cameraYRot

    demo:
    float4x4 _CameraYRot;
    v.vertex.xyz = mul((_CameraYRot),v.vertex).xyz;
*/



#endif //BILLBOARD_LIB_HLSL