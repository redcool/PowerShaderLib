/**
    cmd.BlitTriangle
*/
Shader "Hidden/Utils/CopyColor"
{
    Properties
    {
        [Group(AntiAlias)]
        [GroupToggle(AntiAlias)] _OffsetHalfPixelOn("_OffsetHalfPixelOn",float) = 0
        [GroupToggle(AntiAlias,_LUMA_AA_ON,Apply AA on edge)] _LumaAAOn("_LumaAAOn",float) = 0
        [DisableGroup(_LumaAAOn)]
        [GroupItem(AntiAlias)]_EdgeThreshold("_EdgeThreshold",range(0,1)) = 0.5
        //======================== ColorGrading
        [Group(ColorGrading)]
        [GroupToggle(ColorGrading,_APPLY_COLOR_GRADING)] _ApplyColorGrading("_ApplyColorGrading",float) = 0

        [DisableGroup(_ApplyColorGrading)]
        [GroupItem(ColorGrading)] _ColorGradingLUT ("_ColorGradingLUT", 2D) = "white" {}

        [DisableGroup(_ApplyColorGrading)]
        [GroupToggle(ColorGrading)]_UseLogC("_UseLogC",float) = 0
        //======================== color tint
        [Group(ColorTint)]
        [GroupToggle(ColorTint,_COLOR_TINT_ON)] _ColorTintOn("_ColorTintOn",float) = 0
        [DisableGroup(_ColorTintOn)]
        [GroupItem(ColorTint)] _Saturate("_Saturate",float) = 1

        [DisableGroup(_ColorTintOn)]
        [GroupItem(ColorTint)] _Brighness("_Brighness",range(0,3)) = 1

        [DisableGroup(_ColorTintOn)]
        [GroupItem(ColorTint)] _Contrast("_Contrast",range(0,3)) = 1
        //======================== ChannelMixer
        [Group(ChannelMixer)]
		[GroupToggle(ChannelMixer,_CHANNEL_MIXER_ON)]_ChannelMixerOn("_ChannelMixerOn",float) = 0
		[DisableGroup(_ChannelMixerOn)]
		[GroupItem(ChannelMixer)][HDR]_ColorX("Color_X",Color) = (1,0,0,1)

		[DisableGroup(_ChannelMixerOn)]
		[GroupItem(ChannelMixer)][HDR]_ColorY("Color_Y",Color) = (0,1,0,1)

		[DisableGroup(_ChannelMixerOn)]
		[GroupItem(ChannelMixer)][HDR]_ColorZ("Color_Z",Color) = (0,0,1,1)
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "../../Lib/BlitLib.hlsl"
    #include "../../Lib/Colors.hlsl"
    #include "../../Lib/ColorSpace.hlsl"
    
    #include "../../Lib/AALib.hlsl"

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
    half4 _ColorX,_ColorY,_ColorZ;
    half _EdgeThreshold;
    CBUFFER_END
    
    v2f vert (uint vid:SV_VERTEXID)
    {
        v2f o;
        FullScreenTriangleVert(vid,o.vertex/**/,o.uv/**/);

        return o;
    }

    float4 frag (v2f i) : SV_Target
    {
        half isEdge = 1;
        #if defined(_LUMA_AA_ON)
            isEdge = CalcEdgeLuma(_SourceTex,linear_clamp_sampler, i.uv,_SourceTex_TexelSize,_EdgeThreshold);
        #endif

        float2 uv = i.uv;
        uv += 0.5*_OffsetHalfPixelOn*_SourceTex_TexelSize.xy * isEdge;
        float4 col = SAMPLE_TEXTURE2D(_SourceTex,linear_clamp_sampler, uv);
        
        //1 apply grading lut
        #if defined(_APPLY_COLOR_GRADING)
            col.xyz = ApplyColorGradingLUT(col.xyz,_UseLogC,half3(_ColorGradingLUT_TexelSize.xy,_ColorGradingLUT_TexelSize.w-1));
        #endif

        //2 apply colorTint
        #if defined(_COLOR_TINT_ON)
            col = lerp(dot(col,half3(.2,.7,.1)),col,_Saturate);
            col = lerp(0,col,_Brighness);
            col = lerp(.5,col,_Contrast);
        #endif

        //3 apply channelMixer
        #if defined(_CHANNEL_MIXER_ON)
            col.xyz = col.x * _ColorX.xyz + col.y * _ColorY.xyz + col.z * _ColorZ.xyz;
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
            #pragma shader_feature _CHANNEL_MIXER_ON
            #pragma shader_feature _COLOR_TINT_ON
            #pragma shader_feature _LUMA_AA_ON
            ENDHLSL
        }
    }
}
