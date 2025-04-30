/**
    cmd.BlitTriangle
*/
Shader "Hidden/Utils/CopyColor"
{
    Properties
    {
        [GroupHeader(ColorGrading)]
        [GroupToggle(,_APPLY_COLOR_GRADING)]_ApplyColorGrading("_ApplyColorGrading",float) = 0
        _ColorGradingLUT ("_ColorGradingLUT", 2D) = "white" {}
        [GroupToggle()]_UseLogC("_UseLogC",float) = 0

        [GroupHeader(AntiAlias)]
        [GroupToggle()] _OffsetHalfPixelOn("_OffsetHalfPixelOn",float) = 0
        
        [GroupHeader(Color)]
        _Saturate("_Saturate",float) = 1
        _Brighness("_Brighness",range(0,3)) = 1
        _Contrast("_Contrast",range(0,3)) = 1
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../../Lib/BlitLib.hlsl"
    #include "../../Lib/Colors.hlsl"
    #include "../../Lib/ColorSpace.hlsl"    

SamplerState point_clamp_sampler;
SamplerState linear_clamp_sampler;

    struct v2f
    {
        float2 uv : TEXCOORD0;
        float4 vertex : SV_POSITION;
    };

    TEXTURE2D(_SourceTex);
    float4 _SourceTex_TexelSize;

    CBUFFER_START(UnityPerMaterial)
    // half _ApplyColorGrading;
    half _UseLogC;
    half _OffsetHalfPixelOn;
    half _Saturate,_Contrast,_Brighness;
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
        uv += 0.5*_OffsetHalfPixelOn*_SourceTex_TexelSize.xy;

        float4 col = SAMPLE_TEXTURE2D(_SourceTex,linear_clamp_sampler, uv);

        col = lerp(dot(col,half3(.2,.7,.1)),col,_Saturate);
        col = lerp(0,col,_Brighness);
        col = lerp(.5,col,_Contrast);

        #if defined(_APPLY_COLOR_GRADING)
        // if(_ApplyColorGrading)
            col.xyz = ApplyColorGradingLUT(col.xyz,_UseLogC,half3(_ColorGradingLUT_TexelSize.xy,_ColorGradingLUT_TexelSize.w-1));
        #endif

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
            #pragma shader_feature _APPLY_COLOR_GRADING
            ENDHLSL
        }
    }
}
