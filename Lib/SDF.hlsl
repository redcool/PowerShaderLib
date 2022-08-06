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
    return abs(y - x);
}

#endif //SDF_LIB_HLSL