#if !defined(AO_LIB_HLSL)
#define AO_LIB_HLSL

float3 WorldToViewPos(float3 worldPos){
    return mul(UNITY_MATRIX_V,float4(worldPos,1)).xyz;
}

float3 WorldToViewNormal(float3 vec){
    return mul(UNITY_MATRIX_V,float4(vec,0)).xyz;
}

/*
    Horizon Base Ambient Occlusion
    一句话总结: 根据周围像素在摄影机空间位置,当前像素的明度(可见度)
    计算采样点方向与当前像素方向的夹角(水平角),若夹角<88度,表示当前像素未被周围遮挡

    算法大致过程: 
    360度切分dirCount,
    对每个dir进行步进stepCount,
    当前的screenUV+步进的deltaUV,采样深度图,转换到viewSpace
    获取采样点的viewPos到当前viewPos的方向
    计算采样方向与当前像素法线的夹角,若夹角在88度内,表示当前像素未被遮挡.
    累计未被遮挡系数ao,并重置当前角度为水平角
        ao += (当前角的正弦 - 目标水平角正弦) * (1 - 采样方向长度一半的平方)
        目标水平角 = 当前角
    最后输出,反向的未遮挡系统

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
        float horizonAngle = 0.04; // 2.3 deg
        deltaUV = mul(deltaRotationMatrix,deltaUV);

        for(int j=1;j<=stepsCount;j++){
            float2 sampleUV = uv + j * deltaUV;
            float3 sampleViewPos = WorldToViewPos(ScreenToWorld(sampleUV));
            float3 sampleDirVS = sampleViewPos - viewPos;

            float angle = (PI*0.5) - acos(dot(viewNormal,normalize(sampleDirVS))); // 1.57 - [0,1.57] , same direction will greater, mean not occlusion
            if(angle > horizonAngle){ // angle different in 88 deg
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