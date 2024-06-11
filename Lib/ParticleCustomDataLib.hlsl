#if !defined(PARTICLE_CUSTOM_DATA_LIB)
#define PARTICLE_CUSTOM_DATA_LIB
/**
    uv.xy : main uv or(particle's uv)
    uv.zw : (particle's customData Custom1.xy)

*/
// float4 uv : TEXCOORD0; 
/** 
    uv1.xy (particle's customData Custom1.zw)
    uv1.zw (particle's customData Custom2.xy)

*/
// float4 uv1:TEXCOORD1;
/**
    uv2.xy (particle's customData Custom2.zw)
    uv2.zw:(particle uv2)

*/        
// float4 uv2:TEXCOORD2;

/**
    vertex input
*/
#define CUSTOM_DATA_APPDATA \
float4 uv : TEXCOORD0;\ 
float4 uv1 : TEXCOORD1;\
float4 uv2 : TEXCOORD2

#define CUSTOM_DATA_V2F(id1,id2)\
float4 customData1:TEXCOORD##id1;\
float4 customData2:TEXCOORD##id2

/**
    vs
// particle custom data (Custom1.zw)(Custom2.xy)
// particle custom data (Custom2.xy)
*/

#define CUSTOM_DATA_VERTEX(v,o) \
o.customData1 = float4(v.uv.zw,v.uv1.xy);\
o.customData2 = float4(v.uv1.zw,v.uv2.xy);\
float customDatas[8] = {o.customData1,o.customData2}

// /**
//     ps
// */
// #define CUSTOM_DATA_FRAGMENT(v2f i)\
//     float customDatas[8] = {i.customData1,i.customData2}

#endif //PARTICLE_CUSTOM_DATA_LIB