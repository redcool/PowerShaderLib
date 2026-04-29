/**
    * This file contains the declarations for the UITK shaders.

    can override macros: 
    UpdateSurfaceFunc
*/
#if !defined(UITK_DECLARES_HLSL)
#define UITK_DECLARES_HLSL
// --------------------------------------------------

// Keywords
#pragma multi_compile_local _ _UIE_FORCE_GAMMA
// #pragma multi_compile_local _ _UIE_TEXTURE_SLOT_COUNT_4 _UIE_TEXTURE_SLOT_COUNT_2 _UIE_TEXTURE_SLOT_COUNT_1
// #pragma multi_compile_local _ _UIE_RENDER_TYPE_SOLID _UIE_RENDER_TYPE_TEXTURE _UIE_RENDER_TYPE_TEXT _UIE_RENDER_TYPE_GRADIENT
// GraphKeywords: <None>

#define UITK_SHADERGRAPH

// Defines
#define _SURFACE_TYPE_TRANSPARENT 1
#define ATTRIBUTES_NEED_TEXCOORD0
#define ATTRIBUTES_NEED_TEXCOORD1
#define ATTRIBUTES_NEED_TEXCOORD2
#define ATTRIBUTES_NEED_TEXCOORD3
#define ATTRIBUTES_NEED_COLOR
#define VARYINGS_NEED_TEXCOORD0
#define VARYINGS_NEED_TEXCOORD1
#define VARYINGS_NEED_TEXCOORD3
#define VARYINGS_NEED_COLOR
#define FEATURES_GRAPH_VERTEX

#define REQUIRE_DEPTH_TEXTURE
#define REQUIRE_NORMAL_TEXTURE

#define SHADERPASS SHADERPASS_CUSTOM_UI

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
// #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/DebugMipmapStreamingMacros.hlsl"
#include "DebugMipmapStreamingMacros.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
// #include "Packages/com.unity.shadergraph/Editor/Generation/Targets/BuiltIn/ShaderLibrary/Shim/UIShim.hlsl"
#include "UIShim.hlsl"
// --------------------------------------------------
// Structs and Packing


struct Attributes
{
    float3 positionOS : POSITION;
    float4 color : COLOR;
    float4 uv0 : TEXCOORD0;
    float4 uv1 : TEXCOORD1;
    float4 uv2 : TEXCOORD2;
    float4 uv3 : TEXCOORD3;
    float4 uv4 : TEXCOORD4;
    float4 uv5 : TEXCOORD5;
    float4 uv6 : TEXCOORD6;
    float4 uv7 : TEXCOORD7;
    #if UNITY_ANY_INSTANCING_ENABLED || defined(ATTRIBUTES_NEED_INSTANCEID)
    uint instanceID : INSTANCEID_SEMANTIC;
    #endif
};
struct SurfaceDescriptionInputs
{
    float4 color;
    float4 typeTexSettings;
    float2 textCoreLoc;
    float4 circle;
    float4 uvClip;
    float2 layoutUV;
};
struct Varyings
{
    float4 positionCS : SV_POSITION;
    float4 texCoord0;
    float4 texCoord1;
    float4 texCoord3;
    float4 texCoord4;
    float4 color;
    #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
    uint instanceID : CUSTOM_INSTANCE_ID;
    #endif
    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
    #endif
    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
    #endif
};
struct VertexDescriptionInputs
{
    float4 vertexPosition;
    float4 vertexColor;
    float4 uv;
    float4 xformClipPages;
    float4 ids;
    float4 flags;
    float4 opacityColorPages;
    float4 settingIndex;
    float4 circle;
};
struct PackedVaryings
{
    float4 positionCS : SV_POSITION;
    float4 texCoord0 : INTERP0;
    float4 texCoord1 : INTERP1;
    float4 texCoord3 : INTERP2;
    float4 texCoord4 : INTERP3;
    float4 color : INTERP4;
    #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
    uint instanceID : CUSTOM_INSTANCE_ID;
    #endif
    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
    uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
    #endif
    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
    uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
    #endif
};

PackedVaryings PackVaryings (Varyings input)
{
    PackedVaryings output;
    ZERO_INITIALIZE(PackedVaryings, output);
    output.positionCS = input.positionCS;
    output.texCoord0.xyzw = input.texCoord0;
    output.texCoord1.xyzw = input.texCoord1;
    output.texCoord3.xyzw = input.texCoord3;
    output.texCoord4.xyzw = input.texCoord4;
    output.color.xyzw = input.color;
    #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
    output.instanceID = input.instanceID;
    #endif
    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
    #endif
    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
    #endif
    return output;
}

Varyings UnpackVaryings (PackedVaryings input)
{
    Varyings output;
    output.positionCS = input.positionCS;
    output.texCoord0 = input.texCoord0.xyzw;
    output.texCoord1 = input.texCoord1.xyzw;
    output.texCoord3 = input.texCoord3.xyzw;
    output.texCoord4 = input.texCoord4.xyzw;
    output.color = input.color.xyzw;
    #if UNITY_ANY_INSTANCING_ENABLED || defined(VARYINGS_NEED_INSTANCEID)
    output.instanceID = input.instanceID;
    #endif
    #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
    output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
    #endif
    #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
    output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
    #endif
    return output;
}


// -- Property used by ScenePickingPass
#ifdef SCENEPICKINGPASS
float4 _SelectionID;
#endif

// -- Properties used by SceneSelectionPass
#ifdef SCENESELECTIONPASS
int _ObjectId;
int _PassValue;
#endif

//UGUI has no keyword for when a renderer has "bloom", so its nessecary to hardcore it here, like all the base UI shaders.
half4 _TextureSampleAdd;

// --------------------------------------------------
// Graph

// Graph Properties
// CBUFFER_START(UnityPerMaterial)
// UNITY_TEXTURE_STREAMING_DEBUG_VARS;
// CBUFFER_END

// Object and Global properties

// Graph Includes
// GraphIncludes: <None>

// Graph Functions
// GraphFunctions: <None>

/* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreVertex' */

// Graph Vertex
struct VertexDescription
{
};

VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
{
VertexDescription description = (VertexDescription)0;
return description;
}

/* WARNING: $splice Could not find named fragment 'CustomInterpolatorPreSurface' */

// Graph Pixel
struct SurfaceDescription
{
float3 BaseColor;
float Alpha;
};


SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
{
    SurfaceDescription surface = (SurfaceDescription)0;
    float3 color = float3(1, 1, 1);
    float alpha = 1.0;
    [branch] if (_UIE_RENDER_TYPE_SOLID || _UIE_RENDER_TYPE_ANY && TestType(IN.typeTexSettings.x, k_FragTypeSolid))
    {
        SolidFragInput Unity_UIE_RenderTypeSwitchNode_Solid_Input;
        Unity_UIE_RenderTypeSwitchNode_Solid_Input.tint = IN.color;
        Unity_UIE_RenderTypeSwitchNode_Solid_Input.isArc = false;
        Unity_UIE_RenderTypeSwitchNode_Solid_Input.outer = float2(-10000, -10000);
        Unity_UIE_RenderTypeSwitchNode_Solid_Input.inner = float2(-10000, -10000);
        CommonFragOutput Unity_UIE_RenderTypeSwitchNode_Output = uie_std_frag_solid(Unity_UIE_RenderTypeSwitchNode_Solid_Input);
        color = Unity_UIE_RenderTypeSwitchNode_Output.color.rgb;
        alpha = Unity_UIE_RenderTypeSwitchNode_Output.color.a;
    }
    else [branch] if (_UIE_RENDER_TYPE_TEXTURE || _UIE_RENDER_TYPE_ANY && TestType(IN.typeTexSettings.x, k_FragTypeTexture))
    {
        TextureFragInput Unity_UIE_RenderTypeSwitchNode_Texture_Input;
        Unity_UIE_RenderTypeSwitchNode_Texture_Input.tint = IN.color;
        Unity_UIE_RenderTypeSwitchNode_Texture_Input.textureSlot = IN.typeTexSettings.y;
        Unity_UIE_RenderTypeSwitchNode_Texture_Input.uv = IN.uvClip.xy;
        Unity_UIE_RenderTypeSwitchNode_Texture_Input.isArc = false;
        Unity_UIE_RenderTypeSwitchNode_Texture_Input.outer = float2(-10000, -10000);
        Unity_UIE_RenderTypeSwitchNode_Texture_Input.inner = float2(-10000, -10000);
        CommonFragOutput Unity_UIE_RenderTypeSwitchNode_Output = uie_std_frag_texture(Unity_UIE_RenderTypeSwitchNode_Texture_Input);
        color = Unity_UIE_RenderTypeSwitchNode_Output.color.rgb;
        alpha = Unity_UIE_RenderTypeSwitchNode_Output.color.a;
    }
    else [branch] if (_UIE_RENDER_TYPE_TEXT || _UIE_RENDER_TYPE_ANY && TestType(IN.typeTexSettings.x, k_FragTypeText))
    {
        [branch] if (GetTextureInfo(IN.typeTexSettings.y).sdfScale > 0.0)
        {
            SdfTextFragInput Unity_UIE_RenderTypeSwitchNode_SdfText_Input;
            Unity_UIE_RenderTypeSwitchNode_SdfText_Input.tint = IN.color;
            Unity_UIE_RenderTypeSwitchNode_SdfText_Input.textureSlot = IN.typeTexSettings.y;
            Unity_UIE_RenderTypeSwitchNode_SdfText_Input.uv = IN.uvClip.xy;
            Unity_UIE_RenderTypeSwitchNode_SdfText_Input.extraDilate = IN.circle.x;
            Unity_UIE_RenderTypeSwitchNode_SdfText_Input.textCoreLoc = round(IN.textCoreLoc);
            Unity_UIE_RenderTypeSwitchNode_SdfText_Input.opacity = IN.typeTexSettings.z;
            CommonFragOutput Unity_UIE_RenderTypeSwitchNode_Output = uie_std_frag_sdf_text(Unity_UIE_RenderTypeSwitchNode_SdfText_Input);
            color = Unity_UIE_RenderTypeSwitchNode_Output.color.rgb;
            alpha = Unity_UIE_RenderTypeSwitchNode_Output.color.a;
        }
        else
        {
            BitmapTextFragInput Unity_UIE_RenderTypeSwitchNode_BitmapText_Input;
            Unity_UIE_RenderTypeSwitchNode_BitmapText_Input.tint = IN.color;
            Unity_UIE_RenderTypeSwitchNode_BitmapText_Input.textureSlot = IN.typeTexSettings.y;
            Unity_UIE_RenderTypeSwitchNode_BitmapText_Input.uv = IN.uvClip.xy;
            Unity_UIE_RenderTypeSwitchNode_BitmapText_Input.opacity = IN.typeTexSettings.z;
            CommonFragOutput Unity_UIE_RenderTypeSwitchNode_Output = uie_std_frag_bitmap_text(Unity_UIE_RenderTypeSwitchNode_BitmapText_Input);
            color = Unity_UIE_RenderTypeSwitchNode_Output.color.rgb;
            alpha = Unity_UIE_RenderTypeSwitchNode_Output.color.a;
        }
    }
    else
    {
        SvgGradientFragInput Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input;
        Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input.settingIndex = round(IN.typeTexSettings.z);
        Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input.textureSlot = round(IN.typeTexSettings.y);
        Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input.uv = IN.uvClip.xy;
        Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input.isArc = false;
        Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input.outer = float2(-10000, -10000);
        Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input.inner = float2(-10000, -10000);
        CommonFragOutput Unity_UIE_RenderTypeSwitchNode_Output = uie_std_frag_svg_gradient(Unity_UIE_RenderTypeSwitchNode_SvgGradient_Input);
        color = Unity_UIE_RenderTypeSwitchNode_Output.color.rgb * IN.color.rgb;
        alpha = Unity_UIE_RenderTypeSwitchNode_Output.color.a * IN.color.a;
    }
    surface.BaseColor = color;
    surface.Alpha = alpha;

    // UpdateSurface(surface, IN);
    return surface;
}

    // --------------------------------------------------
    // Build Graph Inputs

    VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
{
    VertexDescriptionInputs output;
    ZERO_INITIALIZE(VertexDescriptionInputs, output);

#if UNITY_ANY_INSTANCING_ENABLED
#else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
#endif

    return output;
}
SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
{
    SurfaceDescriptionInputs output;
    ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

    /* WARNING: $splice Could not find named fragment 'CustomInterpolatorCopyToSDI' */

    #if UNITY_UV_STARTS_AT_TOP
    #else
    #endif

#if defined(UNITY_UIE_INCLUDED)
#else
#endif
    

    output.color =                                      input.color;
    output.uvClip =                                     input.texCoord0;
    output.typeTexSettings =                            input.texCoord1;
    output.textCoreLoc =                                input.texCoord3.xy;
    output.layoutUV =                                   input.texCoord3.zw;
    
    output.circle =                                     input.texCoord4;
    
#if UNITY_ANY_INSTANCING_ENABLED
#else // TODO: XR support for procedural instancing because in this case UNITY_ANY_INSTANCING_ENABLED is not defined and instanceID is incorrect.
#endif
#if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN                output.FaceSign =                                   IS_FRONT_VFACE(input.cullFace, true, false);
#else
#define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
#endif
#undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

    return output;
}

/**
This function is defined like this to allow users to write custom code to modify the surface description in a separate file, 
without having to modify the generated code of SurfaceDescriptionFunction, 
which can be overwritten when modifying the graph.
*/
#define UpdateSurfaceFunc DefaultUpdateSurface

void DefaultUpdateSurface(inout SurfaceDescription surfaceDescription, SurfaceDescriptionInputs inputs)
{
    float2 uv = inputs.uvClip.xy;
    half4 color = half4(surfaceDescription.BaseColor, surfaceDescription.Alpha);
}

#endif // !defined(UITK_DECLARES_HLSL)