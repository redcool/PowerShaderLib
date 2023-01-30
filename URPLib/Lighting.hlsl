#if !defined(LIGHTING_HLSL)
#define LIGHTING_HLSL

    #include "URP_GI.hlsl"
    #include "URP_Lighting.hlsl"
    
    float3 CalcLight(Light light,float3 diffColor,float3 specColor,float3 n,float3 v,float a,float a2){
        // if(!light.distanceAttenuation)
        //     return 0;
            
        float3 l = light.direction;
        float3 h = normalize(l+v);
        float nl = saturate(dot(n,l));

        float nh = saturate(dot(n,h));
        float lh = saturate(dot(l,h));

        float d = nh*nh*(a2 - 1) +1;
        float specTerm = a2/(d*d * max(0.001,lh*lh) * (4*a+2));
        float radiance = nl * light.shadowAttenuation * light.distanceAttenuation;
        return (diffColor + specColor * specTerm) * light.color * radiance;
    }

    float3 CalcAdditionalLights(float3 worldPos,float3 diffColor,float3 specColor,float3 n,float3 v,float a,float a2,float4 shadowMask,float softScale=1 ){
        uint count = GetAdditionalLightsCount();
		float3 c = 0;
        for(uint i=0;i<count;i++){
			Light l = GetAdditionalLight(i,worldPos,shadowMask,softScale);
			c += CalcLight(l,diffColor,specColor,n,v,a,a2);
        }
		return c;
    }

	float3 CalcGIDiff(float3 n,float3 diffColor){
        float3 sh = SampleSH(n);
        float3 giDiff = sh * diffColor;
		return giDiff;
	}

	float3 CalcGISpec(TEXTURECUBE_PARAM(_ReflectionCubemap,sampler_ReflectionCubemap),float4 cubeMapHdr,float3 specColor,float3 n,float3 v,
		float3 reflectDirOffset,float reflectIntensity,float nv,float roughness,float a2,
		float smoothness,float metallic)
	{

        float mip = roughness * (1.7 - roughness * 0.7) * 6;
        float3 reflectDir = reflect(-v,n);
        float4 envColor = 0;
        // envColor.xyz = GlossyEnvironmentReflection(reflectDir,worldPos,roughness,1);
// ibl as reflection
        reflectDir += reflectDirOffset;

        // _GlossyEnvironmentCubeMap
        envColor = SAMPLE_TEXTURECUBE_LOD(_ReflectionCubemap,sampler_ReflectionCubemap,reflectDir,mip);
        envColor.xyz = DecodeHDREnvironment(envColor,cubeMapHdr) * reflectIntensity;

        float surfaceReduction = 1/(a2+1);
        float grazingTerm = saturate(smoothness + metallic);
        float fresnelTerm = Pow4(1-nv);
        float3 giSpec = surfaceReduction * envColor.xyz * lerp(specColor,grazingTerm,fresnelTerm);
		return giSpec;
	}
#endif //LIGHTING_HLSL