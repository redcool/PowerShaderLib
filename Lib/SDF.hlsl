#if !defined(SDF_LIB_HLSL)
#define SDF_LIB_HLSL
/**
    x: curve
    y:percent

    use case
    
    float v = sin((i.uv.x+_Time.x) * 3.14*2)*.5+0.5 ;
    v = smoothstep(0.1,0.9,i.uv.x);
    v = step(i.uv,0.5);
    v = pow(i.uv,4);
    
    return ShowLine(v,i.uv.y);
*/
float ShowLine(float x,float y){
    return smoothstep(x-0.02,x,y) - smoothstep(x,x+0.02,y);
}

float Line(float x,float y){
    return smoothstep(.02,.01,abs(y - x));
}
float2 ScanLine(float2 uv,float tiling,float width){
    return (frac(uv*tiling + _Time.y)<width);
}

/**
    n : gradient Noise
*/
float HeightLine(float n){
    float delta = fwidth(n);
    float a= smoothstep(1-delta,1,n);
    float b= smoothstep(delta,0,n);
    return (a+b);
}

/**
    is x in range[a,b]
*/
float IsIn(float x,float a,float b){
    return x - clamp(x,a,b) != 0;
}

/**
    is in uv border ?
*/
float UVBorder(float2 uv,float2 uvRange){
    uv = frac(uv);
    float2 uvBorder = (uv - clamp(uv,uvRange.x,uvRange.y)) != 0;
    return 1-saturate(dot(uvBorder,1));
    // return uvBorder.x || uvBorder.y;
}

/**
    world space sdf
    
    distSign,for texture blend
    bandDist, for circle band blend
*/
float CalcWorldDistance(out float distSign,out float bandDist,float3 worldPos,float3 center,float radius,float2 distRange,float2 distSignRange=float2(-1,1)){
    float d = distance(worldPos,center) - radius;
    distSign = smoothstep(distSignRange.x,distSignRange.y,(d));
    d = abs(d);

    d = smoothstep(distRange.x,distRange.y,d);
    d = 1-d;
    bandDist = smoothstep(0,0.2,saturate(d)); // color blending
    return d;
}
#endif //SDF_LIB_HLSL