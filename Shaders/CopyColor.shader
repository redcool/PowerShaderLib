/**
    cmd.BlitTriangle
*/
Shader "Hidden/Utils/CopyColor"
{
    Properties
    {
        // _SourceTex ("Texture", 2D) = "white" {}
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

    bool _ApplyColorGrading;
    // bool _LinearToGamma;

    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);

        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        float4 col = tex2D(_SourceTex, i.uv);
        if(_ApplyColorGrading)
            col.xyz = ApplyColorGradingLUT(col.xyz);

        // if(_LinearToGamma)
        //     col.xyz = Gamma22ToLinear(col.xyz);

        #if defined(_SRGB_TO_LINEAR_CONVERSION)
        // return float4(1,0,0,1);
        col.rgb = Gamma20ToLinear(col.rgb);
        #endif

        #if _LINEAR_TO_SRGB_CONVERSION
        // return float4(0,1,0,1);
        col.rgb = LinearToGamma20(col.rgb);
        #endif

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
