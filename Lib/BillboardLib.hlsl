#if !defined(BILLBOARD_LIB_HLSL)
#define BILLBOARD_LIB_HLSL


float3 CalcPosOffsetViewSpace(float3 vertex,bool fullFaceCamera){
    float3x3 camRotMat = float3x3(
        UNITY_MATRIX_V[0].xyz,
        UNITY_MATRIX_V[1].xyz,
        UNITY_MATRIX_V[2].xyz
    );

    float sx = unity_ObjectToWorld._11;
    float sy = unity_ObjectToWorld._22;

    float3 vertexOffset = float3(sx,sy,0) * vertex.xyz;
    float3 vertexRotate = mul(camRotMat,float3(0,vertex.y * sy,0));

    if(!fullFaceCamera){
        vertexOffset.y = 0;
        vertexOffset += vertexRotate;
    }
    return vertexOffset;
}

/**
    rotate vertex ,face to camera
*/
float4 TransformBillboardObjectToHClip(float3 vertex,bool fullFaceCamera){
    float3 vertexOffset = CalcPosOffsetViewSpace(vertex,fullFaceCamera);
    return mul(UNITY_MATRIX_P,
        mul(UNITY_MATRIX_MV,float4(0,0,0,1)) + float4(vertexOffset,1)
    );
}

/**
    2 use cameraYRot

    demo:
    float4x4 _CameraYRot;
    v.vertex.xyz = mul((_CameraYRot),v.vertex).xyz;
*/



#endif //BILLBOARD_LIB_HLSL