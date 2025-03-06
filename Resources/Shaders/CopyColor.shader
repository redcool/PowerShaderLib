/**
    cmd.BlitTriangle
*/
Shader "Hidden/Utils/CopyColor"
{
    Properties
    {
        // _SourceTex ("Texture", 2D) = "white" {}
        [GroupToggle()] _OffsetHalfPixelOn("_OffsetHalfPixelOn",float) = 0
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../../Lib/BlitLib.hlsl"
    #include "../../Lib/Colors.hlsl"
    #include "../../Lib/ColorSpace.hlsl"    

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    sampler2D _SourceTex;
    float4 _SourceTex_TexelSize;
    bool _ApplyColorGrading;

    CBUFFER_START(UnityPerMaterial)
    half _OffsetHalfPixelOn;
    CBUFFER_END
    

    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);

        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        float2 uv = i.uv;
        // #if defined(SHADER_API_D3D11)
            uv += 0.5*_OffsetHalfPixelOn*_SourceTex_TexelSize.xy;
        // #endif

        float4 col = tex2D(_SourceTex, uv);
        if(_ApplyColorGrading)
            col.xyz = ApplyColorGradingLUT(col.xyz);

        // change color space
        LinearGammaAutoChange(col,false);

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
