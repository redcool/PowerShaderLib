#if !defined(BSDF_HLSL)
#define BSDF_HLSL

#undef Pow5
#define Pow5(a) a*a*a*a*a

float F_Schlick(float f0,float f90,float t){
    float x = 1-t;
    float x2 = x*x;
    float x5 = x*x2*x2;
    return (f90-f0) * x5+f0;
}

float FastSSS(float3 l,float3 v){
    return saturate(dot(l,v));
}

float DisneyDiffuse(float nv,float nl,float lh,float roughness){
    float fd90 = 0.5 + 2*roughness*lh*lh;
    float lightScatter = 1 - (fd90 - 1) * Pow5(1 - nl);
    float viewScatter = 1 - (fd90 - 1 ) * Pow5(1 - nv);
    return lightScatter * viewScatter;
}
float RoughnessToSpecPower(float a){
    float a2 = a * a;
    float sq = max(1e-4f,a2 * a2);
    float n = 2.0/sq - 2;
    n = max(n,1e-4f);
    return n;
}
float3 FresnelTerm(float3 F0,float lh){
    return F0 + (1-F0) * Pow5(1 - lh);
}
float3 FresnelLerp(float3 f0,float3 f90,float lh){
    float t = Pow5(1-lh);
    return lerp(f0,f90,t);
}
float3 FresnelLerpFast(float3 F0,float3 F90,float lh){
    float t = Pow4(1 - lh);
    return lerp(F0,F90,t);
}

float SmithJointGGXTerm(float nl,float nv,float a2){
    float v = nv * (nv * (1-a2)+a2);
    float l = nl * (nl * (1-a2)+a2);
    return 0.5f/(v + l + 1e-5f);
}

float NDFBlinnPhongTerm(float nh,float a){
    float normTerm = (a + 2)* 0.5/PI;
    float specularTerm = pow(nh,a);
    return normTerm * specularTerm;
}

float D_GGXTerm(float nh,float a2){
    float d = (nh*a2-nh)*nh + 1;
    return a2 / (d*d + 1e-7f);
}


float D_GGXAnisoNoPI(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
    float a2 = roughnessT * roughnessB;
    float3 v = float3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    float  s = dot(v, v);

    // If roughness is 0, returns (NdotH == 1 ? 1 : 0).
    // That is, it returns 1 for perfect mirror reflection, and 0 otherwise.
    return (a2*a2*a2)/max(s*s,0.00001);
}

float D_GGXAniso(float TdotH, float BdotH, float NdotH, float roughnessT, float roughnessB)
{
    return INV_PI * D_GGXAnisoNoPI(TdotH, BdotH, NdotH, roughnessT, roughnessB);
}

float D_WardAniso(float nl,float nv,float nh,float th,float bh,float roughT,float roughB){
    float roughTH = th/roughT;
    float roughBH = bh/roughB;
    return sqrt(max(0,nl/nv)) * exp(-2 * (roughTH*roughTH+roughBH*roughBH)/(1+nh));
}

float BankBRDF(float3 l,float3 v,float3 t,float ks,float power){
    float lt = dot(l,t);
    float vt = dot(v,t);
    float lt2 = lt*lt;
    float vt2 = vt*vt;
    return ks * pow(sqrt(1-lt2)*sqrt(1-vt2) - lt*vt,power);
}

float GetSmithJointGGXAnisoPartLambdaV(float TdotV, float BdotV, float NdotV, float roughnessT, float roughnessB)
{
    return length(float3(roughnessT * TdotV, roughnessB * BdotV, NdotV));
}

// Note: V = G / (4 * NdotL * NdotV)
// Ref: https://cedec.cesa.or.jp/2015/session/ENG/14698.html The Rendering Materials of Far Cry 4
float V_SmithJointGGXAniso(float TdotV, float BdotV, float NdotV, float TdotL, float BdotL, float NdotL, float roughnessT, float roughnessB, float partLambdaV)
{
    float lambdaV = NdotL * partLambdaV;
    float lambdaL = NdotV * length(float3(roughnessT * TdotL, roughnessB * BdotL, NdotL));

    return 0.5 / (lambdaV + lambdaL);
}

float V_SmithJointGGXAniso(float TdotV, float BdotV, float NdotV, float TdotL, float BdotL, float NdotL, float roughnessT, float roughnessB)
{
    float partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
    return V_SmithJointGGXAniso(TdotV, BdotV, NdotV, TdotL, BdotL, NdotL, roughnessT, roughnessB, partLambdaV);
}
// Inline D_GGXAniso() * V_SmithJointGGXAniso() together for better code generation.
float DV_SmithJointGGXAniso(float TdotH, float BdotH, float NdotH, float NdotV,
                           float TdotL, float BdotL, float NdotL,
                           float roughnessT, float roughnessB, float partLambdaV)
{
    float a2 = roughnessT * roughnessB;
    float3 v = float3(roughnessB * TdotH, roughnessT * BdotH, a2 * NdotH);
    float  s = dot(v, v);

    float lambdaV = NdotL * partLambdaV;
    float lambdaL = NdotV * length(float3(roughnessT * TdotL, roughnessB * BdotL, NdotL));

    float2 D = float2(a2 * a2 * a2, s * s);  // Fraction without the multiplier (1/Pi)
    float2 G = float2(1, lambdaV + lambdaL); // Fraction without the multiplier (1/2)

    // This function is only used for direct lighting.
    // If roughness is 0, the probability of hitting a punctual or directional light is also 0.
    // Therefore, we return 0. The most efficient way to do it is with a max().
    return (INV_PI * 0.5) * (D.x * G.x) / max(D.y * G.y, FLT_MIN);
}

float DV_SmithJointGGXAniso(float TdotH, float BdotH, float NdotH,
                           float TdotV, float BdotV, float NdotV,
                           float TdotL, float BdotL, float NdotL,
                           float roughnessT, float roughnessB)
{
    float partLambdaV = GetSmithJointGGXAnisoPartLambdaV(TdotV, BdotV, NdotV, roughnessT, roughnessB);
    return DV_SmithJointGGXAniso(TdotH, BdotH, NdotH, NdotV,
                                 TdotL, BdotL, NdotL,
                                 roughnessT, roughnessB, partLambdaV);
}

float CharlieD(float roughness, float ndoth)
{
    float invR = 1. / roughness;
    float cos2h = ndoth * ndoth;
    float sin2h = max(1. - cos2h,0.0078125);
    return (2. + invR) * pow(sin2h, invR * .5) / (2. * PI);
}

float AshikhminV(float ndotv, float ndotl)
{
    return 1. / (4. * (ndotl + ndotv - ndotl * ndotv));
}

float D_Ashikhmin(float roughness, float NoH) {
    // Ashikhmin 2007, "Distribution-based BRDFs"
	float a2 = roughness * roughness;
	float cos2h = NoH * NoH;
	float sin2h = max(1.0 - cos2h, 0.0078125); // 2^(-14/2), so sin2h^2 > 0 in fp16
	float sin4h = sin2h * sin2h;
	float cot2 = -cos2h / (a2 * sin2h);
	return 1.0 / (PI * (4.0 * a2 + 1.0) * sin4h) * (4.0 * exp(cot2) + sin4h);
}

float MinimalistCookTorrance(float nh,float lh,float rough,float rough2){
    float d = nh * nh * (rough2-1) + 1.00001f;
    float lh2 = lh * lh;
    float spec = rough2/((d*d) * max(0.1,lh2) * (rough*4+2)); // approach sqrt(rough2)
    
    #if defined (SHADER_API_MOBILE) || defined (SHADER_API_SWITCH)
        spec = clamp(spec,0,100);
    #endif
    return spec;
}

half3 PreScattering(sampler2D scatterMap,half3 normal,half3 lightDir,half3 lightColor,half nl,half4 mainTex,half3 worldPos,half curveScale,half scatterIntensity,bool preScatterMaskUseMainTexA){
    half wnl = saturate( dot(normal,(lightDir)) * 0.5 + 0.5);
    half atten = 1-wnl;//smoothstep(0.,0.5,nl);
    half3 scattering = tex2D(scatterMap,half2(wnl,curveScale )).xyz;
    half scatterMask = lerp(1,mainTex.w,preScatterMaskUseMainTexA);
    return scattering * lightColor * mainTex.xyz * atten * scatterIntensity * scatterMask;
}

/**
    物体表面的光泽层亮度
    diffColor *= SheenLayer(nh,wrappedNV,0.8,1,1);
*/
half SheenLayer(float snh,float wnv,half2 range,half minLuminance=0.5,half scale=1){
    return  max(minLuminance,smoothstep(range.x,range.y,wnv) + snh) * scale;
}

/*
    Calc step siffuse color 
*/
float DiffuseStep(float diffMin,float diffMax,float stepCount,inout float nl){
    float nlId = floor(nl * stepCount);
    float nlRate = frac(nl * stepCount);
    float rate = smoothstep(diffMin,diffMax,nlRate);
    nl = lerp(nlId,nlId+1,rate)/ stepCount;
}

#endif //BSDF_HLSL