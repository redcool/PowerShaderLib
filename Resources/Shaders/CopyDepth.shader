/**
    copy _SourceTex to DepthTarget
*/

Shader "Hidden/Utils/CopyDepth"
{
    Properties
    {
        
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../../Lib/BlitLib.hlsl"
    // #define _DEPTH_MSAA_4

    #if defined(_DEPTH_MSAA_2) || defined(_DEPTH_MSAA_4) || defined(_DEPTH_MSAA_8)
        #define USE_MSAA
    #endif

    #if defined(_DEPTH_MSAA_2)
        #define MSAA_SAMPLES 2
    #elif defined(_DEPTH_MSAA_4)
        #define MSAA_SAMPLES 4
    #elif defined(_DEPTH_MSAA_8)
        #define MSAA_SAMPLES 8
    #else
        #define MSAA_SAMPLES 1
    #endif // _DEPTH_MSAA

    #if defined(UNITY_REVERSED_Z)
        #define DEPTH_DEFAULT_VALUE 1
        #define DEPTH_OP min
    #else
        #define DEPTH_DEFAULT_VALUE 0
        #define DEPTH_OP max
    #endif

    /**
        not solve ar(multi view)
    */

    float SampleDepthMSAA(Texture2DMS<float,MSAA_SAMPLES> tex,float2 uv,float4 texelSize){
        int2 coord=int2(uv*texelSize.zw);
        float outputDepth = DEPTH_DEFAULT_VALUE;
        UNITY_UNROLL
        for(int i=0;i<MSAA_SAMPLES;i++)
            outputDepth = DEPTH_OP(LOAD_TEXTURE2D_MSAA(tex,coord,i),outputDepth);
        return outputDepth;
    }

    //#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
    #if defined(USE_MSAA)
        #define DEPTH_TEXTURE(name,samples) Texture2DMS<float,samples> name
        #define SAMPLE_DEPTH_TEXTURE(tex,texState,uv) SampleDepthMSAA(tex,uv,_SourceTex_TexelSize)
    #else
        #define DEPTH_TEXTURE(name,samples) TEXTURE2D(name)
        #define SAMPLE_DEPTH_TEXTURE(tex,texState,uv) SAMPLE_TEXTURE2D(tex,texState,uv)
    #endif  //USE_MSAA


    DEPTH_TEXTURE(_SourceTex,MSAA_SAMPLES);SAMPLER(sampler_SourceTex);
    float4 _SourceTex_TexelSize;

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    float SampleDepth(float2 uv){
        float depth = SAMPLE_DEPTH_TEXTURE(_SourceTex,sampler_SourceTex,uv);
        return depth;
    }

    // TEXTURE2D(_SourceTex); SAMPLER(sampler_SourceTex);

    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);
        return o;
    }

    float frag (v2f i) : SV_DEPTH
    {
        // return SAMPLE_TEXTURE2D(_SourceTex,sampler_SourceTex,i.uv).x;
        return SampleDepth(i.uv);
    }
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off
        // zwrite off
        colorMask r
        ztest always
        Pass
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _DEPTH_MSAA_2 _DEPTH_MSAA_4 _DEPTH_MSAA_8
            
            ENDHLSL
        }
    }
}
