/**
    Tools for Convert CG to HLSL

*/

#if !defined(UNITY_CG_COMPATIBLE_HLSL)
#define UNITY_CG_COMPATIBLE_HLSL

#define fixed half
#define fixed2 half2
#define fixed3 half3
#define fixed4 half4

// macros UnityCG.cginc
#define UnityWorldToClipPos(worldPos) TransformWorldToHClip(worldPos)
#define UnityObjectToWorldDir(worldDir) TransformObjectToWorldDir(worldDir)
#define UnityObjectToWorldNormal(normal) TransformObjectToWorldNormal(normal)

#define UnityWorldSpaceViewDir(worldPos) GetWorldSpaceViewDir(worldPos.xyz)

#define WorldSpaceViewDir(localPos) UnityWorldSpaceViewDir(mul(UNITY_MATRIX_M,localPos).xyz)

#define UnityObjectToClipPos(objectPos) TransformObjectToHClip(objectPos.xyz)
#define UnityWorldSpaceLightDir(worldPos) GetWorldSpaceLightDir(worldPos)

#define UNITY_INITIALIZE_OUTPUT(type,name) name = (type)0;

#endif //UNITY_CG_COMPATIBLE_HLSL