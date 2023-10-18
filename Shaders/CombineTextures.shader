/**
    cmd.BlitTriangle
*/
Shader "Hidden/Utils/CombineTextures"
{
    Properties
    {
        // _SourceTex ("Texture", 2D) = "white" {}
        _TexChannels("_TexChannels",vector) = (0,1,2,3)
        _Tex2Channels("_Tex2Channels",vector) = (0,1,2,3)
        [GroupVectorSlider(,r g b a,0_1 0_1 0_1 0_1)]_Ranges("_Ranges",vector) = (0,0,0,0)
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../Lib/BlitLib.hlsl"
    #include "../Lib/Colors.hlsl"

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    sampler2D _SourceTex;
    sampler2D _SourceTex2;
    // sampler2D _SourceTex3;
    // sampler2D _SourceTex4;
    float4 _TexChannels,_Tex2Channels;
    float4 _Ranges;

    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);

        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        float4 col = tex2D(_SourceTex, i.uv);
        float4 col2 = tex2D(_SourceTex2, i.uv);
        // float4 col3 = tex2D(_SourceTex3, i.uv);
        // float4 col4 = tex2D(_SourceTex4, i.uv);
        
        // col.a = col2.r;

        col = float4(
            lerp(col[_TexChannels[0]],col2[_Tex2Channels[0]],_Ranges[0]),
            lerp(col[_TexChannels[1]],col2[_Tex2Channels[1]],_Ranges[1]),
            lerp(col[_TexChannels[2]],col2[_Tex2Channels[2]],_Ranges[2]),
            lerp(col[_TexChannels[3]],col2[_Tex2Channels[3]],_Ranges[3])
        );

        // #if defined(_SRGB_TO_LINEAR_CONVERSION)
        // color.rgb = GammaToLinearSpace(color.rgb);
        // #endif

        // #if _LINEAR_TO_SRGB_CONVERSION
        // color.rgb = LinearToGammaSpace(color.rgb);
        // #endif

        return col;
    }
    ENDHLSL

    SubShader
    {
        Cull off
        zwrite off
        ztest always

        Pass
        {
            blend[_FinalSrcMode][_FinalDstMode]
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fragment _ _SRGB_TO_LINEAR_CONVERSION _LINEAR_TO_SRGB_CONVERSION
            ENDHLSL
        }
    }
}
