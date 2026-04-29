#ifndef UNITY_UIE_INCLUDED
#define UNITY_UIE_INCLUDED

#if defined(_UIE_TEXTURE_SLOT_COUNT_1)
    #define _UIE_TEXTURE_SLOT_COUNT 1
#elif defined(_UIE_TEXTURE_SLOT_COUNT_2)
    #define _UIE_TEXTURE_SLOT_COUNT 2
#elif defined(_UIE_TEXTURE_SLOT_COUNT_4)
    #define _UIE_TEXTURE_SLOT_COUNT 4
#else
    #define _UIE_TEXTURE_SLOT_COUNT 8
#endif

#if defined(_UIE_RENDER_TYPE_SOLID)
    #undef _UIE_RENDER_TYPE_SOLID
    #define _UIE_RENDER_TYPE_SOLID 1
    #define _UIE_RENDER_TYPE_TEXTURE 0
    #define _UIE_RENDER_TYPE_TEXT 0
    #define _UIE_RENDER_TYPE_GRADIENT 0
    #define _UIE_RENDER_TYPE_ANY 0
#elif defined(_UIE_RENDER_TYPE_TEXTURE)
    #define _UIE_RENDER_TYPE_SOLID 0
    #undef _UIE_RENDER_TYPE_TEXTURE
    #define _UIE_RENDER_TYPE_TEXTURE 1
    #define _UIE_RENDER_TYPE_TEXT 0
    #define _UIE_RENDER_TYPE_GRADIENT 0
    #define _UIE_RENDER_TYPE_ANY 0
#elif defined(_UIE_RENDER_TYPE_TEXT)
    #define _UIE_RENDER_TYPE_SOLID 0
    #define _UIE_RENDER_TYPE_TEXTURE 0
    #undef _UIE_RENDER_TYPE_TEXT
    #define _UIE_RENDER_TYPE_TEXT 1
    #define _UIE_RENDER_TYPE_GRADIENT 0
    #define _UIE_RENDER_TYPE_ANY 0
#elif defined(_UIE_RENDER_TYPE_GRADIENT)
    #define _UIE_RENDER_TYPE_SOLID 0
    #define _UIE_RENDER_TYPE_TEXTURE 0
    #define _UIE_RENDER_TYPE_TEXT 0
    #undef _UIE_RENDER_TYPE_GRADIENT
    #define _UIE_RENDER_TYPE_GRADIENT 1
    #define _UIE_RENDER_TYPE_ANY 0
#else
    #define _UIE_RENDER_TYPE_SOLID 0
    #define _UIE_RENDER_TYPE_TEXTURE 0
    #define _UIE_RENDER_TYPE_TEXT 0
    #define _UIE_RENDER_TYPE_GRADIENT 0
    #define _UIE_RENDER_TYPE_ANY 1
#endif

#ifdef _UIE_FORCE_GAMMA
    #undef _UIE_FORCE_GAMMA
    #define _UIE_FORCE_GAMMA 1
#else
    #define _UIE_FORCE_GAMMA 0
#endif

#define UIE_TEXTURE_SLOT_SIZE 2

#ifndef UIE_COLORSPACE_GAMMA
    // Note: When the editor shader is compiled, UNITY_COLORSPACE_GAMMA is ALWAYS set because it is the color space
    // of the editor resources project.
    #if defined(UNITY_COLORSPACE_GAMMA) || _UIE_FORCE_GAMMA
        #define UIE_COLORSPACE_GAMMA 1
    #else
        #define UIE_COLORSPACE_GAMMA 0
    #endif // UNITY_COLORSPACE_GAMMA
#endif // UIE_COLORSPACE_GAMMA

#ifndef UIE_FRAG_T
    #if UIE_COLORSPACE_GAMMA
        #define UIE_FRAG_T fixed4
    #else
        #define UIE_FRAG_T half4
    #endif // UIE_COLORSPACE_GAMMA
#endif // UIE_FRAG_T

#ifndef UIE_V2F_COLOR_T
    #if UIE_COLORSPACE_GAMMA
        #define UIE_V2F_COLOR_T fixed4
    #else
        #define UIE_V2F_COLOR_T half4
    #endif // UIE_COLORSPACE_GAMMA
#endif // UIE_V2F_COLOR_T

#ifndef UIE_NOINTERPOLATION
    #ifdef UNITY_PLATFORM_WEBGL
        // UUM-57628 Safari leaks when using nointerpolation (resulting in flat in glsl)
        #define UIE_NOINTERPOLATION
    #else
        #define UIE_NOINTERPOLATION nointerpolation
    #endif
#endif

#if defined(UITK_SHADERGRAPH) || defined(SHADERGRAPH_PREVIEW)

// Needed since we do not include UnityCG.cginc
// Tranforms position from object to homogenous space
inline float4 UnityObjectToClipPos(in float3 pos)
{
#if defined(STEREO_CUBEMAP_RENDER_ON)
    return UnityObjectToClipPosODS(pos);
#else
    // More efficient than computing M*VP matrix product
    return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(pos, 1.0)));
#endif
}

#else
// Shader Graph has its own equivalent include that collides with this one
#include "UnityCG.cginc"
#endif

// This file is technally not ok to use with URP and HDRP. However there is no common macros between BiRP, URP and HDRP
// and we don't want to duplicate our code. Also see UIShims.hlsl for more details.
#include "HLSLSupport.cginc"

UNITY_DECLARE_TEX2D(_GradientSettingsTex);
UNITY_DECLARE_TEX2D_NOSAMPLER_FLOAT(_ShaderInfoTex);
float4 _TextureInfo[_UIE_TEXTURE_SLOT_COUNT * UIE_TEXTURE_SLOT_SIZE];
UNITY_DECLARE_TEX2D(_Texture0);
UNITY_DECLARE_TEX2D(_Texture1);
UNITY_DECLARE_TEX2D(_Texture2);
UNITY_DECLARE_TEX2D(_Texture3);
UNITY_DECLARE_TEX2D(_Texture4);
UNITY_DECLARE_TEX2D(_Texture5);
UNITY_DECLARE_TEX2D(_Texture6);
UNITY_DECLARE_TEX2D(_Texture7);

// This piecewise approximation has a precision better than 0.5 / 255 in gamma space over the [0..255] range
// i.e. abs(l2g_exact(g2l_approx(value)) - value) < 0.5 / 255
// It is much more precise than GammaToLinearSpace but remains relatively cheap
half3 uie_gamma_to_linear(half3 value)
{
    half3 low = 0.0849710 * value - 0.000163029;
    half3 high = value * (value * (value * 0.265885 + 0.736584) - 0.00980184) + 0.00319697;

    // We should be 0.5 away from any actual gamma value stored in an 8 bit channel
    const half3 split = (half3)0.0725490; // Equals 18.5 / 255
    return (value < split) ? low : high;
}

// This piecewise approximation has a very precision veryclose to that of LinearToGammaSpaceExact but explicitly
// avoids branching
half3 uie_linear_to_gamma(half3 value)
{
    half3 low = 12.92F * value;
    half3 high =  1.055F * pow(value, 0.4166667F) - 0.055F;

    const half3 split = (half3)0.0031308;
    return (value < split) ? low : high;
}

struct appdata_t
{
    float4 vertex   : POSITION;
    float4 color    : COLOR;
    float4 uv       : TEXCOORD0;
    float4 xformClipPages : TEXCOORD1; // Top-left of xform and clip pages: XY,XY
    float4 ids      : TEXCOORD2; //XYZW (xform,clip,opacity,color/textcore)
    float4 flags    : TEXCOORD3; //X (flags) Y (textcore-dilate) Z (is-arc) W (is-dynamic-colored)
    float4 opacityColorPages : TEXCOORD4; //XY: Opacity page, ZW: color page/textcore setting
    float4 settingIndex : TEXCOORD5; // XY: SVG setting index
    float4 circle   : TEXCOORD6; // XY (outer) ZW (inner)
    float  textureId : TEXCOORD7; // X (textureId)
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

struct v2f
{
    float4 pos : SV_POSITION;
    UIE_V2F_COLOR_T color : COLOR;
    float4 uvClip  : TEXCOORD0; // UV and ZW contains the relative coords within the clipping rect
    UIE_NOINTERPOLATION half4 typeTexSettings : TEXCOORD1; // X: Render Type Y: Tex Index Z: SVG Gradient Index/Text Opacity W: Is Arc (textured + solid)
#ifdef UNITY_PLATFORM_WEBGL
    // UUM-90736 Safari-WebGL hangs when using uint2 in v2f struct
    UIE_NOINTERPOLATION float2 textCoreLoc : TEXCOORD3; // Location of the TextCore data in the shader info
#else
    UIE_NOINTERPOLATION uint2 textCoreLoc : TEXCOORD3; // Location of the TextCore data in the shader info
#endif
    float4 circle : TEXCOORD4; // XY (outer) ZW (inner) | X (Text Extra Dilate)
    UNITY_VERTEX_OUTPUT_STEREO
};

static const float kUIEMeshZ = 0.0f; // Keep in track with UIRUtility.k_MeshPosZ
static const float kUIEMaskZ = 1.0f; // Keep in track with UIRUtility.k_MaskPosZ

struct TextureInfo
{
    float textureId;
    float sdfScale;
    float2 texelSize;
    float2 textureSize;
    float sharpness;
    float isPremultiplied;
};

// index: integer between [0.._UIE_TEXTURE_SLOT_COUNT[
TextureInfo GetTextureInfo(half index)
{
    half offset = (index * UIE_TEXTURE_SLOT_SIZE) + 0.5f;
    float4 data0 = _TextureInfo[offset];
    float4 data1 = _TextureInfo[offset + 1];

    TextureInfo info;
    info.textureId = data0.x;
    info.texelSize = data0.yz;
    info.sdfScale = data0.w;
    info.textureSize = data1.xy;
    info.sharpness = data1.z;
    info.isPremultiplied = data1.w;

    return info;
}

// returns: Integer between 0 and _UIE_TEXTURE_SLOT_COUNT - 1
half FindTextureSlot(float textureId)
{
    [unroll] for (half i = 0 ; i < _UIE_TEXTURE_SLOT_COUNT - 1 ; ++i)
        if (GetTextureInfo(i).textureId == textureId)
            return i;
    return _UIE_TEXTURE_SLOT_COUNT - 1;
}

#define UIE_BRANCH(OP) \
    [branch] if (index < 3.5 || _UIE_TEXTURE_SLOT_COUNT <= 4) \
    { \
        [branch] if (index < 1.5 || _UIE_TEXTURE_SLOT_COUNT <= 2) \
        { \
            [branch] if (index < 0.5 || _UIE_TEXTURE_SLOT_COUNT <= 1) \
                {OP(0)} \
            else \
                {OP(1)} \
        } \
        else \
        { \
            [branch] if (index < 2.5) \
                {OP(2)} \
            else \
                {OP(3)} \
        } \
    } \
    else \
    { \
        [branch] if (index < 5.5) \
        { \
            [branch] if (index < 4.5) \
                {OP(4)} \
            else \
                {OP(5)} \
        } \
        else \
        { \
            [branch] if (index < 6.5) \
                {OP(6)} \
            else \
                {OP(7)} \
        } \
    }

#define UIE_SAMPLE1(index) \
    result = UNITY_SAMPLE_TEX2D(_Texture##index, uv);

// index: integer between [0.._UIE_TEXTURE_SLOT_COUNT[
float4 SampleTextureSlot(half index, float2 uv)
{
    float4 result;
    UIE_BRANCH(UIE_SAMPLE1)
    return result;
}

#define UIE_SAMPLE2(index) \
    result1 = UNITY_SAMPLE_TEX2D(_Texture##index, uv1); \
    result2 = UNITY_SAMPLE_TEX2D(_Texture##index, uv2);

// index: integer between [0.._UIE_TEXTURE_SLOT_COUNT[
void SampleTextureSlot2(half index, float2 uv1, float2 uv2, out float4 result1, out float4 result2)
{
    UIE_BRANCH(UIE_SAMPLE2)
}

float4 ReadShaderInfo(min16uint2 location)
{
    return _ShaderInfoTex.Load(min16uint3(location, 0));
}

// Notes on UIElements Spaces (Local, Bone, Group, World and Clip)
//
// Consider the following example:
//      *     <- Clip Space (GPU Clip Coordinates)
//    Proj
//      |     <- World Space
//   VEroot
//      |
//     VE1 (RenderHint = Group)
//      |     <- Group Space
//     VE2 (RenderHint = Bone)
//      |     <- Bone Space
//     VE3
//
// A VisualElement always emits vertices in local-space. They do not embed the transform of the emitting VisualElement.
// The renderer transforms the vertices on CPU from local-space to bone space (if available), or to the group space (if available),
// or ultimately to world-space if there is no ancestor with a bone transform or group transform.
//
// The world-to-clip transform is stored in UNITY_MATRIX_P
// The group-to-world transform is stored in UNITY_MATRIX_V
// The bone-to-group transform is stored in uie_toWorldMat.
//
// In this shader, we consider that vertices are always in bone-space, and we always apply the bone-to-group and the group-to-world
// transforms. It does not matter because in the event where there is no ancestor with a Group or Bone RenderHint, these transform
// will be identities.

static float4x4 uie_toWorldMat;

// Let min and max, the bottom-left and top-right corners of the clipping rect. We want to remap our position so that we
// get -1 at min and 1 at max. The rasterizer can linearly interpolate the value and the fragment shader will interpret
// |value| > 1 as being outside the clipping rect, meaning the fragment should be discarded.
//
// min      avg      max  pos
//  |--------|--------|----|
// -1        0        1
//
// avg = (min + max) / 2
// pos'= (pos - avg) / (max - avg)
//     = pos * [1 / (max - avg)] + [- avg / (max - avg)]
//     = pos * a + b
// a   = 1 / (max - avg)
//     = 1 / [max - (min + max) / 2]
//     = 2 / (max - min)
// b   = - avg / (max - avg)
//     = -[(min + max) / 2] / [max - ((min + max) / 2)]
//     = -[min + max] / [2 * max - (min + max)]
//     = (min + max) / (min - max)
//
// a    : see above
// b    : see above
// pos  : position, in group space
float2 ComputeRelativeClipRectCoords(float2 a, float2 b, float2 pos)
{
    return pos * a + b;
}

float uie_fragment_clip(float2 clipData)
{
    float2 dist = abs(clipData);
    return dist.x < 1.0001f & dist.y < 1.0001f;
}

min16uint2 uie_decode_shader_info_texel_pos(float2 encodedPage, float encodedId, min16uint yStride)
{
    const min16uint kShaderInfoPageWidth = 32; // If this ever changes, adjust the DynamicColor test accordingly
    const min16uint kShaderInfoPageHeight = 8;

    min16uint id = round(encodedId * 255.0f);
    min16uint2 pageXY = round(encodedPage * 255.0f); // From [0,1] to [0,255]
    min16uint idY = id / kShaderInfoPageWidth; // Must use uint division for better performance
    min16uint idX = id - idY * kShaderInfoPageWidth;

    return min16uint2(
        pageXY.x * kShaderInfoPageWidth + idX,
        pageXY.y * kShaderInfoPageHeight + idY * yStride);
}

void uie_vert_load_dynamic_transform(appdata_t v)
{
    min16uint2 xformTexel = uie_decode_shader_info_texel_pos(v.xformClipPages.xy, v.ids.x, 3);
    min16uint2 row0Loc = xformTexel + min16uint2(0, 0);
    min16uint2 row1Loc = xformTexel + min16uint2(0, 1);
    min16uint2 row2Loc = xformTexel + min16uint2(0, 2);

    uie_toWorldMat = float4x4(
        ReadShaderInfo(row0Loc),
        ReadShaderInfo(row1Loc),
        ReadShaderInfo(row2Loc),
        float4(0, 0, 0, 1));
}

float2 uie_unpack_float2(fixed4 c)
{
    return float2(c.r*255 + c.g, c.b*255 + c.a);
}

float2 uie_ray_unit_circle_first_hit(float2 rayStart, float2 rayDir)
{
    float tca = dot(-rayStart, rayDir);
    float d2 = dot(rayStart, rayStart) - tca * tca;
    float thc = sqrt(1.0f - d2);
    float t0 = tca - thc;
    float t1 = tca + thc;
    float t = min(t0, t1);
    if (t < 0.0f)
        t = max(t0, t1);
    return rayStart + rayDir * t;
}

float uie_radial_address(float2 uv, float2 focus)
{
    uv = (uv - float2(0.5f, 0.5f)) * 2.0f;
    float2 pointOnPerimeter = uie_ray_unit_circle_first_hit(focus, normalize(uv - focus));
    float2 diff = pointOnPerimeter - focus;
    if (abs(diff.x) > 0.0001f)
        return (uv.x - focus.x) / diff.x;
    if (abs(diff.y) > 0.0001f)
        return (uv.y - focus.y) / diff.y;
    return 0.0f;
}

struct GradientLocation
{
    float2 uv;
    float4 location;
};

GradientLocation uie_sample_gradient_location(min16uint settingIndex, float2 uv)
{
    // Gradient settings are stored in 3 consecutive texels:
    // - texel 0: (float4, 1 byte per float)
    //    x = gradient type (0 = tex/linear, 1 = radial)
    //    y = address mode (0 = wrap, 1 = clamp, 2 = mirror)
    //    z = radialFocus.x
    //    w = radialFocus.y
    // - texel 1: (float2, 2 bytes per float) atlas entry position
    //    xy = pos.x
    //    zw = pos.y
    // - texel 2: (float2, 2 bytes per float) atlas entry size
    //    xy = size.x
    //    zw = size.y

    min16uint2 settingLoc = min16uint2(0, settingIndex);
    fixed4 gradSettings = _GradientSettingsTex.Load(min16uint3(settingLoc, 0));
    if (gradSettings.x > 0.0f)
    {
        // Radial texture case
        float2 focus = (gradSettings.zw - float2(0.5f, 0.5f)) * 2.0f; // bring focus in the (-1,1) range
        uv = float2(uie_radial_address(uv, focus), 0.0);
    }

    min16uint addressing = round(gradSettings.y * 255);
    uv.x = (addressing == 0) ? fmod(uv.x,1.0f) : uv.x; // Wrap
    uv.x = (addressing == 1) ? max(min(uv.x,1.0f), 0.0f) : uv.x; // Clamp
    float w = fmod(uv.x,2.0f);
    uv.x = (addressing == 2) ? (w > 1.0f ? 1.0f-fmod(w,1.0f) : w) : uv.x; // Mirror

    GradientLocation grad;
    grad.uv = uv;

    // Adjust UV to atlas position
    min16uint2 nextUV = min16uint2(1, 0);
    grad.location.xy = uie_unpack_float2(_GradientSettingsTex.Load(min16uint3(settingLoc + nextUV, 0)) * 255) + float2(0.5f, 0.5f);
    grad.location.zw = uie_unpack_float2(_GradientSettingsTex.Load(min16uint3(settingLoc + nextUV * 2, 0)) * 255);

    return grad;
}

bool fpEqual(float a, float b)
{
#if SHADER_API_GLES || SHADER_API_GLES3
    return abs(a-b) < 0.0001;
#else
    return a == b;
#endif
}

// 1 layer : Face only
// sd           : Signed distance / sdfScale + 0.5
// sdfSizeRCP   : 1 / texture width
// sdfScale     : Signed Distance Field Scale
// isoPerimeter : Dilate / Contract the shape
float sd_to_coverage(float sd, float2 uv, float sdfSizeRCP, float sdfScale, float isoPerimeter)
{
    float ta = ddx(uv.x) * ddy(uv.y) - ddy(uv.x) * ddx(uv.y);   // Texel area covered by this pixel (parallelogram area)
    float ssr = rsqrt(abs(ta)) * sdfSizeRCP;                    // Texture to Screen Space Ratio (unit is Texel/Pixel)
    sd = (sd - 0.5) * sdfScale + isoPerimeter;                  // Signed Distance to edge (in texture space)
    return saturate(0.5 + 2.0 * sd * ssr);                      // Screen pixel coverage : center + (1 / sampling radius) * signed distance
}

// 3 Layers : Face, Outline, Underlay
// sd           : Signed distance / sdfScale + 0.5
// sdfSize      : texture height
// sdfScale     : Signed Distance Field Scale
// isoPerimeter : Dilate / Contract the shape
// softness     : softness of each outer edges
// sharpness    : sharpness of the text
float3 sd_to_coverage(float3 sd, float2 uv, float sdfSize, float sdfScale, float3 isoPerimeter, float3 softness, float sharpness)
{
    // Case 1349202: The underline stretches its middle quad, making parallelogram area evaluation invalid and resulting
    //               in visual artifacts. For that reason, we can only rely on uv.y for the length ratio leading in some
    //               error when a rotation/skew/non-uniform scaling takes place.
    float ps = abs(ddx(uv.y)) + abs(ddy(uv.y));                                 // Size of a pixel in texel space (approximation)
    float stsr = sdfSize * ps;                                                  // Screen to Texture Space Ratio (unit is Pixel/Texel)
    sd = (sd - 0.5) * sdfScale + isoPerimeter;                                  // Signed Distance to edge (in texture space)
    return saturate(0.5 + 2.0 * sd / (stsr / (sharpness + 1.0f) + softness));   // Screen pixel coverage : center + (1 / sampling radius) * signed distance
}

UIE_FRAG_T uie_textcore(float2 uv, half textureSlot, min16uint2 textCoreLoc, float4 vertexColor, float sdfScale, float sharpness, float extraDilate)
{
    min16uint2 row3Loc = textCoreLoc + min16uint2(0, 3);
    float4 settings = ReadShaderInfo(row3Loc);

    settings *= sdfScale - 1.5f;
    float2 underlayOffset = settings.xy;
    float underlaySoftness = settings.z;
    float outlineDilate = settings.w * 0.25f;
    float3 dilate = float3(-outlineDilate, outlineDilate, 0);
    float3 softness = float3(0, 0, underlaySoftness);

    // Distance to Alpha
    TextureInfo ti = GetTextureInfo(textureSlot);
    float texelWidth = ti.texelSize.x;
    float textureHeight = ti.textureSize.y;
    float4 tex1, tex2;
    SampleTextureSlot2(textureSlot, uv, uv + underlayOffset * texelWidth, tex1, tex2);
    float alpha1 = tex1.a;
    float alpha2 = tex2.a;
    float3 alpha = sd_to_coverage(float3(alpha1, alpha1, alpha2), uv, textureHeight, sdfScale, dilate + extraDilate, softness, sharpness);

    // Blending of the 3 ARGB layers
    float4 faceColor = vertexColor;
    UIE_FRAG_T color = faceColor * alpha.x;

    min16uint2 row1Loc = textCoreLoc + min16uint2(0, 1);
    float4 outlineColor = ReadShaderInfo(row1Loc);
    color += outlineColor * ((1 - alpha.x) * alpha.y);

    min16uint2 row2Loc = textCoreLoc + min16uint2(0, 2);
    float4 underlayColor = ReadShaderInfo(row2Loc);
    color += underlayColor * ((1 - alpha.x) * (1 - alpha.y) * alpha.z);

    color.rgb /= (color.a > 0.0f ? color.a : 1.0f);

    return color;
}

float pixelDist(float2 uv)
{
    float dist = length(uv) - 1.0f; // Bring from [0,...] to [-1,...] range
    float2 ddist = float2(ddx(dist), ddy(dist));
    return dist / length(ddist);
}

float ComputeCoverage(float2 outer, float2 inner)
{
    float coverage = 1;
    // Don't evaluate circles defined as kUnusedArc
    [branch] if (outer.x > -9999.0f)
    {
        float outerDist = pixelDist(outer);
        coverage *= saturate(0.5f-outerDist);
    }
    [branch] if (inner.x > -9999.0f)
    {
        float innerDist = pixelDist(inner);
        coverage *= 1.0f - saturate(0.5f-innerDist);
    }

    return coverage;
}

static const half k_VertTypeSolid = 0;
static const half k_VertTypeText = 1;
static const half k_VertTypeTexture = 2;
static const half k_VertTypeDynamicTexture = 3; // Dynamically Sized Texture (e.g. Dynamic Atlas - UVs must be patched)
static const half k_VertTypeSvgGradient = 4;

static const half k_FragTypeSolid = 0;
static const half k_FragTypeTexture = 1;
static const half k_FragTypeText = 2;
static const half k_FragTypeSvgGradient = 3;

bool TestType(half type, half constType) // Types are meant to be tested in ascending order
{
    return type < constType + 0.5f;
}

bool TestIsArc(half flag)
{
    return flag > 0.5f / 255;
}

bool TestIsDynamicColor(half flag)
{
    return flag > 0.5f / 255;
}

bool TestIsDynamicTextColor(half flag)
{
    return flag > 1.5f / 255;
}

v2f uie_std_vert(appdata_t v)
{
    v2f OUT;
    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

    // Position
    uie_vert_load_dynamic_transform(v);
    v.vertex.xyz = mul(uie_toWorldMat, v.vertex); // Apply Dynamic Transform
    OUT.pos = UnityObjectToClipPos(v.vertex); // Apply Group Transform + Projection

    // Dynamic Opacity
    min16uint2 opacityLoc = uie_decode_shader_info_texel_pos(v.opacityColorPages.xy, v.ids.z, 1);
    half opacity = ReadShaderInfo(opacityLoc).a;

    if (opacity < 0.001f)
        // This effectively disables rasterization of fully transparent triangles by moving them outside the clip space
        // and turning them into degenerate triangles. In the future we should skip the rendering entirely.
        OUT.pos = float4(-2, -2, -2, 1);

    // Color
    UIE_V2F_COLOR_T color = v.color;

    [branch] if (TestIsDynamicColor(v.flags.w))
    {
        // When flags.w is 2 instead of 1, the color is stored in text settings
        min16uint dynamicColorStride = TestIsDynamicTextColor(v.flags.w) ? 4 : 1;
        min16uint2 dynamicColorLoc = uie_decode_shader_info_texel_pos(v.opacityColorPages.zw, v.ids.w, dynamicColorStride);
        UIE_V2F_COLOR_T dynamicColor = ReadShaderInfo(dynamicColorLoc);
        color *= dynamicColor; // Dynamic color acts as a multiplier over vertex color
    }

#if !UIE_COLORSPACE_GAMMA
    // Keep this in the VS to ensure that interpolation is performed in the right color space
    color = UIE_V2F_COLOR_T(uie_gamma_to_linear(color.rgb), color.a);
#endif // UIE_COLORSPACE_GAMMA

    // Fragment Shader Discard Clipping Rect
    min16uint2 clipRectLoc = uie_decode_shader_info_texel_pos(v.xformClipPages.zw, v.ids.y, 1);
    float4 rectClippingData = ReadShaderInfo(clipRectLoc);
    OUT.uvClip.zw = ComputeRelativeClipRectCoords(rectClippingData.xy, rectClippingData.zw, v.vertex.xy);

    // Others
    OUT.uvClip.xy = v.uv.xy; // Dynamic texture overrides this value.
    OUT.circle = v.circle; // Arc-AA Data. Text overrides this value.
    OUT.textCoreLoc.xy = -1; // Mostly unused. Text overrides this value.

    const half vertType = v.flags.x * 255.0f;
    half fragType, yData, zData, wData;
    [branch] if (_UIE_RENDER_TYPE_SOLID || _UIE_RENDER_TYPE_ANY && TestType(vertType, k_VertTypeSolid))
    {
        color.a *= opacity;
        fragType = k_FragTypeSolid;
        yData = -1; // Unused
        zData = -1; // Unused
        wData = v.flags.z; // IsArc
    }
    else [branch] if (_UIE_RENDER_TYPE_TEXT || _UIE_RENDER_TYPE_ANY && TestType(vertType, k_VertTypeText))
    {
        fragType = k_FragTypeText;
        yData = FindTextureSlot(v.textureId);
        zData = opacity; // Case 1379601: Text needs to have the separate opacity as well (applied in FS)
        wData = -1; // Unused

        OUT.circle.x = v.flags.y; // Text Extra Dilate
        OUT.textCoreLoc.xy = uie_decode_shader_info_texel_pos(v.opacityColorPages.ba, v.ids.w, 4);

        // SDF color must be premultiplied
        TextureInfo info = GetTextureInfo(yData);
        half multiplier = info.sdfScale > 0.0f ? color.a : 1;
        color.rgb *= multiplier;
    }
    else [branch] if (TestType(vertType, k_VertTypeTexture))
    {
        color.a *= opacity;
        fragType = k_FragTypeTexture;
        yData = FindTextureSlot(v.textureId);
        zData = -1; // Unused
        wData = v.flags.z; // IsArc
    }
    else [branch] if (TestType(vertType, k_VertTypeDynamicTexture))
    {
        color.a *= opacity;
        fragType = k_FragTypeTexture;
        yData = FindTextureSlot(v.textureId);
        zData = -1; // Unused
        wData = v.flags.z; // IsArc

        // Patch UVs
        TextureInfo ti = GetTextureInfo(yData);
        OUT.uvClip.xy = v.uv.xy * ti.texelSize;
    }
    else // k_VertTypeSvgGradient
    {
        color.a *= opacity;
        fragType = k_FragTypeSvgGradient;
        yData = FindTextureSlot(v.textureId);
        zData = v.settingIndex.x * (255.0f*255.0f) + v.settingIndex.y * 255.0f;
        wData = v.flags.z; // IsArc
    }

    OUT.color = color;
    OUT.typeTexSettings = half4(fragType, yData, zData, wData);

    return OUT;
}

struct CommonFragOutput
{
    UIE_FRAG_T color;
    float coverage;
};

struct SolidFragInput
{
    UIE_V2F_COLOR_T tint;
    bool isArc;
    float2 outer;
    float2 inner;
};

CommonFragOutput uie_std_frag_solid(SolidFragInput input)
{
    CommonFragOutput output = (CommonFragOutput)0;

    output.color = input.tint;
    output.coverage = 1;
    [branch] if (input.isArc)
        output.coverage = ComputeCoverage(input.outer, input.inner);

    return output;
}

struct TextureFragInput
{
    UIE_V2F_COLOR_T tint;
    half textureSlot;
    float2 uv;
    bool isArc;
    float2 outer;
    float2 inner;
};

CommonFragOutput uie_std_frag_texture(TextureFragInput input)
{
    CommonFragOutput output = (CommonFragOutput)0;

    output.color = SampleTextureSlot(input.textureSlot, input.uv);

#if _UIE_FORCE_GAMMA
    output.color.rgb = uie_linear_to_gamma(output.color.rgb);
#endif

    TextureInfo ti = GetTextureInfo(input.textureSlot);
    if (ti.isPremultiplied && output.color.a > 0.001f)
        output.color.rgb /= output.color.a; // If the texture is premultiplied, demultiply.

    output.color *= input.tint; // Assume the tint is straight (not premultiplied)
    output.coverage = 1;
    [branch] if (input.isArc)
        output.coverage = ComputeCoverage(input.outer, input.inner);

    return output;
}

struct SdfTextFragInput
{
    UIE_V2F_COLOR_T tint;
    half textureSlot;
    float extraDilate;
    float2 uv;
    min16uint2 textCoreLoc;
    half opacity;
};

CommonFragOutput uie_std_frag_sdf_text(SdfTextFragInput input)
{
    CommonFragOutput output = (CommonFragOutput)0;

    float extraDilate = input.extraDilate;
    TextureInfo info = GetTextureInfo(input.textureSlot);
    output.color = uie_textcore(input.uv, input.textureSlot, input.textCoreLoc, input.tint, info.sdfScale, info.sharpness, input.extraDilate);
    output.color.a *= input.opacity;
    output.coverage = 1;

    return output;
}

struct BitmapTextFragInput
{
    UIE_V2F_COLOR_T tint;
    half textureSlot;
    float2 uv;
    half opacity;
};

CommonFragOutput uie_std_frag_bitmap_text(BitmapTextFragInput input)
{
    CommonFragOutput output = (CommonFragOutput)0;

    float textAlpha = SampleTextureSlot(input.textureSlot, input.uv).a;
    output.color = input.tint;
    output.color.a *= textAlpha;
    output.color.a *= input.opacity;
    output.coverage = 1;

    return output;
}

struct SvgGradientFragInput
{
    min16uint settingIndex;
    half textureSlot;
    float2 uv;
    bool isArc;
    float2 outer;
    float2 inner;
};

CommonFragOutput uie_std_frag_svg_gradient(SvgGradientFragInput input)
{
    CommonFragOutput output = (CommonFragOutput)0;

    min16uint settingIndex = input.settingIndex;
    float2 texelSize = GetTextureInfo(input.textureSlot).texelSize;
    GradientLocation grad = uie_sample_gradient_location(settingIndex, input.uv);
    grad.location *= texelSize.xyxy;
    grad.uv *= grad.location.zw;
    grad.uv += grad.location.xy;
    output.color = SampleTextureSlot(input.textureSlot, grad.uv);
#if _UIE_FORCE_GAMMA
    output.color.rgb = uie_linear_to_gamma(output.color.rgb);
#endif
    output.coverage = 1;
    [branch] if (input.isArc)
        output.coverage = ComputeCoverage(input.outer, input.inner);

    return output;
}

// This function is used by ShaderGraph where we test after the branches. This should not be used in the standard shader.
float uie_sg_compute_aa_coverage(half renderType, half isArc, float2 outer, float2 inner)
{
    float coverage = 1;
    if (_UIE_RENDER_TYPE_SOLID || _UIE_RENDER_TYPE_TEXTURE || _UIE_RENDER_TYPE_GRADIENT || _UIE_RENDER_TYPE_ANY && (renderType == k_FragTypeSolid || renderType == k_FragTypeTexture || renderType == k_FragTypeSvgGradient))
    {
        [branch] if (TestIsArc(isArc))
        {
            coverage = ComputeCoverage(outer, inner);
        }
    }

    return coverage;
}

UIE_FRAG_T uie_std_frag(v2f IN) : SV_Target
{
    float2 uv = IN.uvClip.xy;
    half renderType = IN.typeTexSettings.x;
    half textureSlot = IN.typeTexSettings.y;

    UIE_FRAG_T color;
    float coverage;
    [branch] if (_UIE_RENDER_TYPE_SOLID || _UIE_RENDER_TYPE_ANY && TestType(renderType, k_FragTypeSolid))
    {
        SolidFragInput input;
        input.tint = IN.color;
        input.isArc = TestIsArc(IN.typeTexSettings.w);
        input.outer = IN.circle.xy;
        input.inner = IN.circle.zw;

        CommonFragOutput output = uie_std_frag_solid(input);

        color = output.color;
        coverage = output.coverage;
    }
    else [branch] if (_UIE_RENDER_TYPE_TEXTURE || _UIE_RENDER_TYPE_ANY && TestType(renderType, k_FragTypeTexture))
    {
        TextureFragInput input;
        input.tint = IN.color;
        input.textureSlot = textureSlot;
        input.uv = uv;
        input.isArc = TestIsArc(IN.typeTexSettings.w);
        input.outer = IN.circle.xy;
        input.inner = IN.circle.zw;

        CommonFragOutput output = uie_std_frag_texture(input);

        color = output.color;
        coverage = output.coverage;
    }
    else [branch] if (_UIE_RENDER_TYPE_TEXT || _UIE_RENDER_TYPE_ANY && TestType(renderType, k_FragTypeText))
    {
        CommonFragOutput output = (CommonFragOutput)0;
        TextureInfo info = GetTextureInfo(textureSlot);
        [branch] if (info.sdfScale > 0.0f)
        {
            SdfTextFragInput input;
            input.tint = IN.color;
            input.textureSlot = textureSlot;
            input.extraDilate = IN.circle.x;
            input.uv = uv;
// UUM-132006: Fix WebGL shader precision issue.
#ifdef UNITY_PLATFORM_WEBGL
            input.textCoreLoc = round(IN.textCoreLoc);
#else
            input.textCoreLoc = IN.textCoreLoc;
#endif
            input.opacity = IN.typeTexSettings.z;
            output = uie_std_frag_sdf_text(input);
        }
        else
        {
            BitmapTextFragInput input;
            input.tint = IN.color;
            input.textureSlot = textureSlot;
            input.uv = uv;
            input.opacity = IN.typeTexSettings.z;
            output = uie_std_frag_bitmap_text(input);
        }
        color = output.color;
        coverage = output.coverage;
    }
    else // k_FragTypeSvgGradient
    {
        SvgGradientFragInput input;
        input.settingIndex = round(IN.typeTexSettings.z);
        input.textureSlot = textureSlot;
        input.uv = uv;
        input.isArc = TestIsArc(IN.typeTexSettings.w);
        input.outer = IN.circle.xy;
        input.inner = IN.circle.zw;

        CommonFragOutput output = uie_std_frag_svg_gradient(input);

        color = output.color * IN.color;
        coverage = output.coverage;
    }

    coverage *= uie_fragment_clip(IN.uvClip.zw);

    // Clip fragments when coverage is close to 0 (< 1/256 here).
    // This will write proper masks values in the stencil buffer.
    clip(coverage - 0.003f);

    color.a *= coverage;
    return color;
}

#endif // UNITY_UIE_INCLUDED
