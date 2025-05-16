#if !defined(AO_LIB_HLSL)
#define AO_LIB_HLSL

float3 WorldToViewPos(float3 worldPos){
    return mul(UNITY_MATRIX_V,float4(worldPos,1)).xyz;
}

float3 WorldToViewNormal(float3 vec){
    return mul(UNITY_MATRIX_V,float4(vec,0)).xyz;
}

/*
    dirCount : part of 360 
    stepCount : calc time alone one direction
    stepScale : a step distance scale
*/
float CalcHBAO(float2 uv,float3 viewNormal,float3 viewPos,half dirCount,half stepCount,half stepScale,half aoRangeMin,half aoRangeMax){
    float radiusSS = 64.0 / 512.0;
    int directionsCount =dirCount;
    int stepsCount = stepCount;

    float theta = 2 * PI /float(directionsCount);
    float2x2 deltaRotationMatrix = float2x2(
        cos(theta),-sin(theta),
        sin(theta),cos(theta)
    );
    float2 deltaUV = float2(radiusSS/(stepsCount+1),0)* stepScale;
    float occlusion = 0;

    for(int x=0;x<directionsCount ; x++){
        float horizonAngle = 0.04;
        deltaUV = mul(deltaRotationMatrix,deltaUV);

        for(int j=1;j<=stepsCount;j++){
            float2 sampleUV = uv + j * deltaUV;
            float3 sampleViewPos = WorldToViewPos(ScreenToWorld(sampleUV));
            float3 sampleDirVS = sampleViewPos - viewPos;

            float angle = (PI*0.5) - acos(dot(viewNormal,normalize(sampleDirVS)));
            if(angle > horizonAngle){
                float value = sin(angle) - sin(horizonAngle);
                float attenuation = saturate(1 - pow(length(sampleDirVS)*0.5 , 2));
                occlusion += value * attenuation;
                horizonAngle = angle;
            }
        }
    }

    occlusion = 1 - occlusion/directionsCount;
    occlusion = smoothstep(aoRangeMin,aoRangeMax,occlusion);
    return occlusion;
}

#endif // AO_LIB_HLSL