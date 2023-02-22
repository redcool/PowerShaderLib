#if !defined(NOISE_LIB_HLSL)
#define NOISE_LIB_HLSL

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"

//================= 
// white noise macros
//================= 
#define AMPLIFY 143758.5453
#define DELTA1_1 3.9812
#define DELTA1_2 7.1536
#define DELTA1_3 5.7241

#define DELTA2_1 float2(12.9898,78.233)
#define DELTA2_2 float2(39.346, 11.135)
#define DELTA2_3 float2(73.156, 52.235)

#define DELTA3_1 float3(12.9898, 78.233, 37.719)
#define DELTA3_2 float3(39.346, 11.135, 83.155)
#define DELTA3_3 float3(73.156, 52.235, 09.151)

//================= 
// white noise (1d,2d,3d)
//================= 
// N dim to 1d
#define Nx1(v,delta) frac(sin(dot((v),delta)) * AMPLIFY)
// float Nx1(float v,float delta){
//     return frac(sin(dot(v,delta)) * AMPLIFY);
// }

#define N11(v) Nx1((v).x,0.546)
#define N12(v) float2(Nx1((v).x,DELTA1_1),Nx1((v).x,DELTA1_2))
#define N13(v) float3(Nx1((v).x,DELTA1_1),Nx1((v).x,DELTA1_2),Nx1((v).x,DELTA1_3))

#define N21(v) Nx1((v).xy,DELTA2_1)
#define N22(v) float2(Nx1((v).xy,DELTA2_1),Nx1((v).xy,DELTA2_2))
#define N23(v) float3(Nx1((v).xy,DELTA2_1),Nx1((v).xy,DELTA2_2),Nx1((v).xy,DELTA2_3))

#define N31(v) Nx1((v).xyz,DELTA3_1)
#define N32(v) float2(Nx1((v).xyz,DELTA3_1),Nx1((v).xyz,DELTA3_2))
#define N33(v) float3(Nx1((v).xyz,DELTA3_1),Nx1((v).xyz,DELTA3_2),Nx1((v).xyz,DELTA3_3))

//================= 
// Easing macros
//================= 

#define EaseIn(v) v*v
#define EaseOut(v) 1-EaseIn(1-v)
#define EaseInOut(v) lerp(EaseIn(v),EaseOut(v),v)

//================= 
// value noise 2d
//================= 
float ValueNoise(float2 uv){
    float2 i = floor(uv);
    float2 p = frac(uv);
    p = p*p*(3-2*p);

    float a = N21(i);
    float b = N21(i+float2(1,0));
    float c = N21(i+float2(0,1));
    float d = N21(i+float2(1,1));
    return lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
}

float SmoothValueNoise(float2 uv){
    return 
        (ValueNoise(uv * 4) + 
        ValueNoise(uv * 8) * 0.5 +
        ValueNoise(uv * 16) * 0.25 + 
        ValueNoise(uv * 32) * 0.0625)*0.5;
}


#define ValueNoise2(uv,n_out) \
    float2 id = floor(uv);\
    float2 p = frac(uv);\
    p = p*p*(3-2*p);\
    n_out = lerp(lerp(N21(id),N21(id+float2(1,0)),p.x),lerp(N21(id+float2(0,1)),N21(id+float2(1,1)),p.x),p.y)


//================= 
// ValueNoise Macros
//================= 
#define floatN(n) float##n
#define N3x(x) N3##x
#define ValueNoise3x(v,num,noise_out) \
    float3 id = floor(v);\
    float3 p = frac(v);\
    p = p*p*(3-2*p);\
    floatN(num) result[2];\
    [unroll]for(int z=0;z<2;z++)\
        result[z] = lerp(lerp(N3x(num)(id+float3(0,0,z)),N3x(num)(id+float3(1,0,z)),p.x),lerp(N3x(num)(id+float3(0,1,z)),N3x(num)(id+float3(1,1,z)),p.x),p.y);\
    noise_out = lerp(result[0],result[1],p.z)

//================= 
// ValueNoise functions
//================= 
float ValueNoise31(float3 v){
    float n=0;
    ValueNoise3x(v,1,n);
    return n;
}
float2 ValueNoise32(float3 v){
    float2 n=0;
    ValueNoise3x(v,2,n);
    return n;
}
float3 ValueNoise33(float3 v){
    float3 n=0;
    ValueNoise3x(v,3,n);
    return n;
}

//================= 
// value noise 3d original version
//=================  
/**
float3 ValueNoise33(float3 v){
    float3 i = floor(v);
    float3 p = frac(v);
    p = p*p*(3-2*p);

    float3 n[2];

    [unroll]
    for(int z=0;z<2;z++){
        float3 a = N33(i + float3(0,0,z));
        float3 b = N33(i + float3(1,0,z));
        float3 c = N33(i + float3(0,1,z));
        float3 d = N33(i + float3(1,1,z));

        n[z] = lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
    }
    return lerp(n[0],n[1],p.z);
}
*/

//================= 
// perlin noise
//=================  

/**
    return [-.5,.5]
testcase:

    float p = GradientNoise(worldPos.x);
    float dist = abs(p - i.worldPos.y);
    return smoothstep(0.001,0.002,dist);

*/
float GradientNoise(float v){
    float p = frac(v);

    float a = N11(floor(v)) * 2-1;
    a *= p;

    float b = N11(ceil(v)) * 2-1;
    b *= (p-1);

    p = p*p*(3-2*p);
    return lerp(a,b,p);
}
/**
    return : [-.5,.5]
*/
float GradientNoise(float2 v){
    // cells noise ->[-1,1]
    float2 id = floor(v);
    float2 a = N21(id) * 2-1;
    float2 b = N21(id+float2(1,0)) * 2-1;
    float2 c = N21(id+float2(0,1))*2-1;
    float2 d = N21(id+float2(1,1))*2-1;

    float2 p = frac(v);
    
    a = dot(a,p);
    b = dot(b,p-float2(1,0));
    c = dot(c,p-float2(0,1));
    d = dot(d,p-float2(1,1));

    p = p*p*(3-2*p);
    return lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
}
/**
    float pn = GradientNoise(worldPos.xyz)+0.5;
    return frac(pn*3);
*/
float GradientNoise(float3 v){
    float3 id = floor(v);
    float2 n=0;
    float3 f = frac(v);
    float3 p = f*f*(3-2*f);

    [unroll]
    for(int z=0;z<2;z++){
        float3 id = floor(v);
        float3 a = N31(id+float3(0,0,z)) * 2-1;
        float3 b = N31(id+float3(1,0,z)) * 2-1;
        float3 c = N31(id+float3(0,1,z))*2-1;
        float3 d = N31(id+float3(1,1,z))*2-1;

        a = dot(a,f-float3(0,0,z));
        b = dot(b,f-float3(1,0,z));
        c = dot(c,f-float3(0,1,z));
        d = dot(d,f-float3(1,1,z));

        n[z]= lerp(lerp(a,b,p.x),lerp(c,d,p.x),p.y);
    }
    return lerp(n.x,n.y,p.z);
}

//================= 
// SmoothGradientNoise perlin noise
//=================  
#define SmoothGradirentNoiseX1(v,frequencyScale,factorScale,result)\
    float frequency = 1,factor = 1;\
    [unroll]for(int x=1;x<=4;x++){\
        result += GradientNoise(v * frequency +x*.456) * factor;\
        frequency *= frequencyScale;\
        factor *= factorScale;\
    }

float SmoothGradientNoise(float v,half frequencyScale=3,half factorScale=0.4){
    float n=0;
    SmoothGradirentNoiseX1(v,frequencyScale,factorScale,n/**/);
    return n;
}
float SmoothGradientNoise(float2 v,half frequencyScale=3,half factorScale=0.4){
    float n=0;
    SmoothGradirentNoiseX1(v,frequencyScale,factorScale,n/**/);
    return n;
}
float SmoothGradientNoise(float3 v,half frequencyScale=3,half factorScale=0.4){
    float n=0;
    SmoothGradirentNoiseX1(v,frequencyScale,factorScale,n/**/);
    return n;
}

//================= 
// VoronoiNoise
//=================  
float VoronoiNoise21(float2 uv){
    float2 id = floor(uv);
    id += N22(id);
    return length(id - uv);
}
float2 VoronoiNoise22(float2 uv){
    float2 id = floor(uv);
    float minDist = 10;
    float2 closestId=0;

    [unroll]
    for(int x=-1;x<=1;x++){
        [unroll]
        for(int y=-1;y<=1;y++){
            float2 cellId = id + float2(x,y);
            float2 cellPos = cellId + N22(cellId);
            float dist = length(cellPos - uv);

            closestId = (dist<minDist) ? cellId : closestId;
            minDist = min(dist,minDist);
        }
    }

    return float2(minDist,N21(closestId));
}

float3 VoronoiNoise23(float2 uv){
    float2 id = floor(uv);
    float minDist = 10;
    float2 closestId=0;
    float2 toClosestCell=0;

    [unroll]
    for(int x=-1;x<=1;x++){
        [unroll]
        for(int y=-1;y<=1;y++){
            float2 cellId = id + float2(x,y);
            float2 cellPos = cellId + N22(cellId);
            float2 toCell = cellPos - uv;
            float dist = length(toCell);

            closestId = (dist<minDist) ? cellId : closestId;
            toClosestCell = (dist<minDist)?toCell : toClosestCell;
            minDist = min(dist,minDist);
        }
    }

    // 
    float minEdgeDist=10;
    [unroll]
    for(int x=-1;x<=1;x++){
        [unroll]
        for(int y=-1;y<=1;y++){
            float2 cellId = id + float2(x,y);
            float2 cellPos = cellId + N22(cellId);
            float2 toCell = (cellPos - uv);

            float2 diffToClosestCell = abs(closestId - cellId);
            bool isClosestCell = (diffToClosestCell.x + diffToClosestCell.y) < 0.1;
            if(!isClosestCell){
                float2 toCenter = (toClosestCell + toCell) * 0.5;
                float2 cellDiff = normalize(toCell - toClosestCell);
                float edgeDist = dot(toCenter,cellDiff);
                minEdgeDist = min(minEdgeDist,edgeDist);
            }
        }
    }
    return float3(minDist,N21(closestId),minEdgeDist);
}

float3 VoronoiNoise33(float3 uv){
    float3 id = floor(uv);
    float minDist = 10;
    float3 closestId=0;
    float3 toClosestCell=0;

    [unroll]for(int x=-1;x<=1;x++){
        [unroll]for(int y=-1;y<=1;y++){
            [unroll]for(int z=-1;z<=1;z++){
                float3 cellId = id + float3(x,y,z);
                float3 cellPos = cellId + N33(cellId);
                float3 toCell = cellPos - uv;
                float dist = length(toCell);

                closestId = (dist<minDist) ? cellId : closestId;
                toClosestCell = (dist<minDist)?toCell : toClosestCell;
                minDist = min(dist,minDist);
            }
        }
    }

    // 
    float minEdgeDist=10;
    [unroll]for(int x=-1;x<=1;x++){
        [unroll]for(int y=-1;y<=1;y++){
            [unroll]for(int z=-1;z<=1;z++){
                float3 cellId = id + float3(x,y,z);
                float3 cellPos = cellId + N33(cellId);
                float3 toCell = (cellPos - uv);

                float3 diffToClosestCell = abs(closestId - cellId);
                bool isClosestCell = (diffToClosestCell.x + diffToClosestCell.y + diffToClosestCell.z) < 0.1;
                if(!isClosestCell){
                    float3 toCenter = (toClosestCell + toCell) * 0.5;
                    float3 cellDiff = normalize(toCell - toClosestCell);
                    float edgeDist = dot(toCenter,cellDiff);
                    minEdgeDist = min(minEdgeDist,edgeDist);
                }
            }
        }
    }
    return float3(minDist,N31(closestId),minEdgeDist);
}

/**
    ScreenDoor1(i.vertex,0.1);
*/
float ScreenDoor1(float2 screenPos,float size=1){
    float2 uv = floor(screenPos.xy * 0.25*size) * .5;
    float n = frac(uv.x + uv.y);
    return n;
}

float ScreenDoor2(float2 screenPos,float size=1){
    const float4x4 thresholdMatrix =  
    {  
    1,   9,  3, 11,  
    13,  5, 15,  7,  
    4,  12,  2, 10,  
    16,  8, 14,  6  
    };
    float2 uv = screenPos.xy * (size*0.5);
    float a = thresholdMatrix[uv.x%4][uv.y%4]/17;
    return a;
}

#endif //NOISE_LIB_HLSL