#if !defined(MATERIAL_LIB_HLSL)
#define MATERIAL_LIB_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "Colors.hlsl"
#include "TangentLib.hlsl"

#undef HALF_MIN
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats
#undef HALF_MIN_SQRT
#define HALF_MIN_SQRT 0.0078125  // 2^-7 == sqrt(HALF_MIN), useful for ensuring HALF_MIN after x^2

/**
    float4 pbrMask = SAMPLE_TEXTURE2D(_MetallicMaskMap,sampler_MetallicMaskMap,uv);
    SplitPbrMaskTexture(
        data.metallic,//out
        data.smoothness, //out
        data.occlusion, //out
        pbrMask, // pbrMask texture
        int3(_MetallicChannel,_SmoothnessChannel,_OcclusionChannel), // int3(0,1,2)
        float3(_Metallic,_Smoothness,_Occlusion), // pbrMask sliders
        _InvertSmoothnessOn // use roughness
    );
*/
void SplitPbrMaskTexture(out half m,out half s,out half o,half4 pbrMaskTex,int3 pbrMaskChannels,half3 pbrMaskRatios,bool isSmoothnessReversed=false){
    m = pbrMaskTex[pbrMaskChannels.x] * pbrMaskRatios.x;
    s = pbrMaskTex[pbrMaskChannels.y] * pbrMaskRatios.y;
    s = isSmoothnessReversed? 1-s : s;
    
    o = lerp(1,pbrMaskTex[pbrMaskChannels.z],pbrMaskRatios.z);
}

/**
    planeMode , 0 : xz,1 : xy, 2 : yz
*/
float2 CalcWorldUV(float3 worldPos,half planeMode,half4 texST){
    float2 uvs[3] = {worldPos.xz,worldPos.xy,worldPos.yz};
    return uvs[planeMode] * texST.xy + texST.zw;
}

void ApplyDetailPbrMask(inout half metallic,inout half smoothness,inout half occlusion,half4 detailPbrMaskTex,half3 detailPbrMaskScale,half3 detailPbrMaskApplyRate){
    SplitPbrMaskTexture(detailPbrMaskTex.x/**/,detailPbrMaskTex.y/**/,detailPbrMaskTex.z/**/,detailPbrMaskTex,int3(0,1,2),detailPbrMaskScale);
    // remove high light flickers
    detailPbrMaskTex.z = saturate(detailPbrMaskTex.z);

    half3 lerpValue = lerp(half3(metallic,smoothness,occlusion),detailPbrMaskTex.xyz,detailPbrMaskApplyRate);
    metallic = lerpValue.x;
    smoothness = lerpValue.y;
    occlusion = lerpValue.z;
}


void CalcRoughness(inout float rough,inout float a,inout float a2,float smoothness){
    rough = 1 - smoothness;
    a = max(rough * rough , HALF_MIN_SQRT);
    a2 = max(a*a,HALF_MIN);
}

void CalcDiffuseSpecularColor(out float3 diffColor,out float3 specColor,float4 albedo,float metallic){
    diffColor = albedo.xyz * (1- metallic);
    specColor = lerp(0.04,albedo.xyz,metallic);
}

void CalcTriplanarUV(out float2 uv0,out float2 uv1,out float2 uv2,out float3 weights,float3 worldPos,float3 normal,float4 tilingOffset=float4(1,1,0,0)){
    weights = abs(normal)/dot(normal,1);
    
    uv0 = float2(worldPos.yz * tilingOffset.xy + tilingOffset.zw);
    uv1 = float2(worldPos.xz * tilingOffset.xy + tilingOffset.zw);
    uv2 = float2(worldPos.xy * tilingOffset.xy + tilingOffset.zw);
}

float4 TriplanarSample(TEXTURE2D_PARAM(tex,sampler_tex),float3 worldPos,float3 normal,float4 tilingOffset=float4(1,1,0,0)){
    float2 uv0,uv1,uv2;
    float3 weights;
    CalcTriplanarUV(uv0/**/,uv1/**/,uv2/**/,weights/**/,worldPos,normal,tilingOffset);

    float4 c = SAMPLE_TEXTURE2D(tex,sampler_tex,uv0) * weights.x;
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv1) * weights.y;
    c += SAMPLE_TEXTURE2D(tex,sampler_tex,uv2) * weights.z;
    return c;
}

void ApplyAlphaPremultiply(inout float3 albedo,inout float alpha,float metallic){
    albedo *= alpha;
    alpha = lerp(alpha + 0.04,1,metallic);
}

/**
    calc albedo,
    alpha,
    alphaTest(ALPHA_TEST),
    isAlphaPremultiply

    ALPHA_TEST
*/
void CalcSurfaceColor(out half3 albedo,out half alpha,half4 mainTex,half4 color,half cutoff,float metallic,bool isAlphaPremultiply,half alphaChanel=3){
    mainTex *= color;
    albedo = mainTex.xyz;
    alpha = mainTex[alphaChanel];
    #if defined(ALPHA_TEST)
        clip(alpha - cutoff);
    #endif
    if(isAlphaPremultiply){
        ApplyAlphaPremultiply(albedo/**/,alpha/**/,metallic);
    }
}

/**
    CalcEmission(emission,_EmissionColor,_EmissionColor.w);
*/
half3 CalcEmission(half4 tex,half3 color,half mask){
    return tex.xyz * tex.w * color * mask;
}

/**
    emissionHeight, [min,maxOffset]

    half upFaceAtten = 1 - saturate(dot(worldNormal,half3(0,1,0)));
    upFaceAtten = lerp(1,upFaceAtten,_EmissionHeightColorNormalAttenOn);

    ApplyHeightEmission(emission,worldPos,upFaceAtten);
*/
void ApplyHeightEmission(inout float3 emissionColor,float3 worldPos,float globalAtten,half2 emissionHeight,half4 emissionHeightColor){
    // get transformed y from M
    float maxHeight = length(half3(UNITY_MATRIX_M._12,UNITY_MATRIX_M._22,UNITY_MATRIX_M._32));
    maxHeight += emissionHeight.y; // apply height offset

    float rate = 1 - saturate((worldPos.y - emissionHeight.x)/ (maxHeight - emissionHeight.x +0.0001));
    rate *= globalAtten;
    // half4 heightEmission = emissionHeightColor * rate;
    half3 heightEmission = lerp(emissionColor.xyz,emissionHeightColor.xyz,rate);
    emissionColor = heightEmission ;
}

half WorldHeightTilingUV(float3 worldPos,float storeyHeight){
    return (worldPos.y/storeyHeight); // remove floor, flicker
}

float NoiseSwitchLight(float2 quantifyNum,float lightOffIntensity){
    float n = N21(quantifyNum);
    return frac(smoothstep(lightOffIntensity,1,n));
}

/**
    storeyWindowInfo : (WindowCountX WindowCountY LightOffPercent LightSwitchPercent)
    storeyLightOpaque : lightOn, alpha = 1
*/
void ApplyStoreyEmission(inout float3 emissionColor,inout float alpha,float3 worldPos,float2 uv,half storeyLightSwitchSpeed,half4 storeyWindowInfo,half storeyLightOpaque){
    // auto light swidth
    float tn = NoiseSwitchLight(round(_Time.x * storeyLightSwitchSpeed) , storeyWindowInfo.w);
    float n = NoiseSwitchLight(floor(uv.xy*storeyWindowInfo.xy) + tn,storeyWindowInfo.z);
    emissionColor *= n;

    branch_if(storeyLightOpaque)
        alpha = Luminance(emissionColor) > 0.1? 1 : alpha;
}

void ApplyStoreyLineEmission(inout float3 emissionColor,half4 lineNoise,float3 worldPos,float4 vertexColor,float nv,float3 storeyLineColor){
    // half lineNoise = InterleavedGradientNoise(screenUV);
    float invNV = 1-nv;
    half atten = vertexColor.x * lineNoise.x * (invNV * invNV);
    half3 lineColor = storeyLineColor.xyz * saturate(atten) ;

    emissionColor = lerp(emissionColor,lineColor,vertexColor.x>0.1);
}


/**
    blend vertex normal and tangent noraml(texture)
*/
float3 BlendVertexNormal(float3 tn,float3 worldPos,float3 t,float3 b,float3 n){
    float3 vn = cross(ddy(worldPos),ddx(worldPos));
    vn = float3(dot(t,vn),dot(b,vn),dot(n,vn));
    return BlendNormal(tn,vn);
}
/**
    blend tangent space normals
*/
float3 Blend2NormalsLOD(TEXTURE2D_PARAM(normalTex,samplerTex),float2 worldUV,float2 tiling,float2 speed,float normalScale,float lod){
    // calc normal uv then 2 normal blend
    float2 normalUV1 = worldUV * tiling + float2(1,0.2) * speed * _Time.x;
    float2 normalUV2 = worldUV * tiling + float2(-1,-0.2) * speed * _Time.x;

    float3 tn = UnpackNormalScale(SAMPLE_TEXTURE2D_LOD(normalTex,samplerTex,normalUV1,lod),normalScale);
    float3 tn2 = UnpackNormalScale(SAMPLE_TEXTURE2D_LOD(normalTex,samplerTex,normalUV2,lod),normalScale);
    return BlendNormal(tn,tn2);
}

/**
    blend tangent space normals
*/
float3 Blend2Normals(TEXTURE2D_PARAM(normalTex,samplerTex),float2 worldUV,float2 tiling,float2 speed,float normalScale){
    // calc normal uv then 2 normal blend
    float2 normalUV1 = worldUV * tiling + float2(1,0.2) * speed * _Time.x;
    float2 normalUV2 = worldUV * tiling + float2(-1,-0.2) * speed * _Time.x;

    float3 tn = UnpackNormalScale(SAMPLE_TEXTURE2D(normalTex,samplerTex,normalUV1),normalScale);
    float3 tn2 = UnpackNormalScale(SAMPLE_TEXTURE2D(normalTex,samplerTex,normalUV2),normalScale);
    return BlendNormal(tn,tn2);
}

/**
    blend tangent space normals to worldNormal
*/
float3 Blend2Normals(TEXTURE2D_PARAM(normalTex,samplerTex),float2 worldUV,float2 tiling,float2 speed,float normalScale,float3 tSpace0,float3 tSpace1,float3 tSpace2){
    float3 tn = Blend2Normals(TEXTURE2D_ARGS(normalTex,samplerTex),worldUV,tiling,speed,normalScale);

    // float3 n = normalize(float3(
    //     dot(tSpace0.xyz,tn),
    //     dot(tSpace1.xyz,tn),
    //     dot(tSpace2.xyz,tn)
    // ));
    return TangentToWorld(tn,tSpace0,tSpace1,tSpace2);
}
#endif //MATERIAL_LIB_HLSL