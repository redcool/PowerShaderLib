/**
    Project's  Macros predefine
*/

//========================
//SphereFog
//========================
// ------- Sphere Fog, in SphereFogLib.hlsl
// #define MAX_SPHERE_FOG_LAYERS 4

// ------- force use structedBuffer
// #define USE_STRUCTURED_BUFFER

//========================
// URP Light
//========================

// ------- urp light count, defined in URP_Input.hlsl
// #define MAX_VISIBLE_LIGHTS 16

// ------- define max mainlight shadow cascade
// #define MAX_SHADOW_CASCADES 4

// project shader lod level recommends
#define MAX_LOD 600
#define MIDDLE_LOD 300
#define LOW_LOD 100

#include "../Macros.hlsl"
