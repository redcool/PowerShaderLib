Shader "Hidden/Utils/CopyDepth"
{
    Properties
    {
        
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../../Lib/BlitLib.hlsl"

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    TEXTURE2D(_SourceTex); SAMPLER(sampler_SourceTex);

    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);
        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        float depth = SAMPLE_TEXTURE2D(_SourceTex,sampler_SourceTex,i.uv).x;
        return depth;
    }
    ENDHLSL

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull off
        zwrite off
        ztest always
        Pass
        {

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            
            ENDHLSL
        }
    }
}
