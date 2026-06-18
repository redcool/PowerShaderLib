/**
    Box Volume Scattering Library
    
    盒体体积散射库，提供两种实现:
    
    A) 3D纹理版本 (推荐，移动端首选)
       — 预烘焙 3D 噪声纹理，沿视线 3 次采样
       — 硬件三线性过滤，平滑且高效
       — 要求: 声明 TEXTURE3D(_VolumeTex) + SAMPLER(sampler_VolumeTex)
    
    B) 解析噪声版本 (无纹理依赖，纯数学)
       — GradientNoise 单点采样，零纹理开销
       — 适合不需要 3D 纹理的场景
    
    用法:
      // 1. 计算 AABB 包围盒 (世界空间)
      float3 right   = UNITY_MATRIX_M._11_21_31;
      float3 up      = UNITY_MATRIX_M._12_22_32;
      float3 forward = UNITY_MATRIX_M._13_23_33;
      float3 center  = UNITY_MATRIX_M._14_24_34;
      float3 halfExt = (abs(right) + abs(up) + abs(forward)) * 0.5;
      float3 boundsMin = center - halfExt;
      float3 boundsMax = center + halfExt;
      
      // 2. 计算体积散射 (3D纹理版)
      float3 viewDir = normalize(worldPos - _WorldSpaceCameraPos);
      half4 vol = BoxVolumeScattering_3DTex(
          boundsMin, boundsMax,
          worldPos, viewDir,
          _LightColor.rgb, light.distanceAttenuation,
          _VolumeDensity, _VolumeExtinction,
          _VolumeTexScale, _VolumeTexSpeed);
      
      radiance += vol.rgb;   // 累加散射光
    
    Keywords:
      _BOX_VOLUME_ON — 开启体积散射
      _BOX_VOLUME_ANALYTICAL — 使用解析噪声版(无3D纹理)
*/

#ifndef BOX_VOLUME_LIB_HLSL
#define BOX_VOLUME_LIB_HLSL

#include "SDF.hlsl"
#include "NoiseLib.hlsl"

// 声明在引用此库的 shader 中
TEXTURE3D(_VolumeTex);
SAMPLER(sampler_VolumeTex);

//=====================================================================
//  A) 3D纹理版本 —— 沿视线 3 次采样，硬件三线性过滤
//=====================================================================

/**
    盒体体积散射 (3D纹理版——移动端推荐)
    
    在体积内沿视线方向取 3 个采样点，用 3D 噪声纹理查询密度。
    3次采样保证体积感，无 raymarching。
    
    需要外部声明:
      TEXTURE3D(_VolumeTex);
      SAMPLER(sampler_VolumeTex);
    
    参数:
        boundsMin      世界空间 AABB 最小值
        boundsMax      世界空间 AABB 最大值
        worldPos       表面世界坐标 (depth 重建)
        viewDir        归一化视线方向 (worldPos - _WorldSpaceCameraPos)
        lightColor     光颜色 (用于散射染色)
        lightAtten     光衰减 (distanceAttenuation)
        density        基础密度
        extinction     消光系数
        texScale       3D纹理 UVW 缩放
        texSpeed       纹理偏移速度 (动画)
    
    返回:
        .rgb = 散射光(累加到 radiance)
        .a   = 透过率
*/
// ray marching count
#define STEP_COUNT 3
half4 BoxVolumeScattering_3DTex(
    float3 boundsMin, float3 boundsMax,
    float3 worldPos, float3 viewDir,
    half3 lightColor, half lightAtten,
    half density, half extinction,
    half texScale, half texSpeed)
{
    //========== 1. 射线-AABB 相交 ==========
    float3 invViewDir = rcp(viewDir);
    float2 boxDst = rayBoxDst(boundsMin, boundsMax, _WorldSpaceCameraPos, invViewDir);
    
    float tEntry = max(0, boxDst.x);
    float tInside = boxDst.y;
    float tExit = boxDst.x + tInside;

    // 未命中
    if(tInside <= 0 || tExit <= 0)
        return half4(0, 0, 0, 0);

    // 裁剪到实际表面距离
    float surfaceDist = distance(worldPos, _WorldSpaceCameraPos);
    float tHit = min(tExit, surfaceDist);
    float volumeThickness = max(HALF_MIN, tHit - tEntry);

    //========== 2. 沿视线 3 次采样 ==========
    float3 entryPos = _WorldSpaceCameraPos + viewDir * tEntry;
    float3 stepWS   = viewDir * (volumeThickness * (1.0/STEP_COUNT));
    float3 timeOff  = _Time.y * texSpeed;

    half dust = 0;

    UNITY_UNROLLX(STEP_COUNT)
    for(int i=0;i<STEP_COUNT;i++)
    {
        entryPos += stepWS * i;
        dust += SAMPLE_TEXTURE3D(_VolumeTex, sampler_VolumeTex,entryPos * texScale + timeOff).r; 
    }
    dust /= STEP_COUNT;


    //========== 3. Beer-Lambert ==========
    half opticalDepth = density * dust * volumeThickness * extinction;
    half transmittance = exp(-opticalDepth);
    half inScattering = 1 - transmittance;

    //========== 4. 输出 ==========
    half3 scattered = lightColor * lightAtten * inScattering;
    return half4(scattered, transmittance);
}


//=====================================================================
//  B) 解析噪声版 —— 纯数学，无纹理依赖 (备选)
//=====================================================================

#if defined(_BOX_VOLUME_ANALYTICAL)
/**
    盒体体积散射 (解析噪声版——备选)
    
    使用 GradientNoise 替代 3D 纹理，零纹理开销。
    适用于不支持 3D 纹理的旧设备或不想用 3D 纹理的场景。
    
    参数同 BoxVolumeScattering_3DTex，但 texScale → noiseScale, texSpeed → noiseSpeed
*/
half4 BoxVolumeScattering_Analytical(
    float3 boundsMin, float3 boundsMax,
    float3 worldPos, float3 viewDir,
    half3 lightColor, half lightAtten,
    half density, half extinction,
    half noiseScale, half noiseSpeed)
{
    float3 invViewDir = rcp(viewDir);
    float2 boxDst = rayBoxDst(boundsMin, boundsMax, _WorldSpaceCameraPos, invViewDir);
    
    float tEntry = max(0, boxDst.x);
    float tInside = boxDst.y;
    float tExit = boxDst.x + tInside;

    if(tInside <= 0 || tExit <= 0)
        return half4(0, 0, 0, 0);

    float surfaceDist = distance(worldPos, _WorldSpaceCameraPos);
    float tHit = min(tExit, surfaceDist);
    float volumeThickness = max(HALF_MIN, tHit - tEntry);

    // 3x noise samples along the ray (same as 3D tex but analytical)
    float3 entryPos = _WorldSpaceCameraPos + viewDir * tEntry;
    float3 stepWS   = viewDir * (volumeThickness * (1.0/3.0));

    half dust = 0;
    dust += GradientNoise(entryPos * noiseScale + _Time.y * noiseSpeed);
    dust += GradientNoise((entryPos + stepWS) * noiseScale + _Time.y * noiseSpeed);
    dust += GradientNoise((entryPos + stepWS * 2) * noiseScale + _Time.y * noiseSpeed);
    dust = dust * 0.5 + 0.5; // [-0.5,0.5] -> [0,1]
    dust /= 3;

    half opticalDepth = density * dust * volumeThickness * extinction;
    half transmittance = exp(-opticalDepth);
    half inScattering = 1 - transmittance;

    half3 scattered = lightColor * lightAtten * inScattering;
    return half4(scattered, transmittance);
}
#endif // _BOX_VOLUME_ANALYTICAL

#endif // BOX_VOLUME_LIB_HLSL
