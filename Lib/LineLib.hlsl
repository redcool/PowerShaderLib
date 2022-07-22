#if !defined(LINE_LIB_HLSL)
#define LINE_LIB_HLSL
/**
    use case
    
    float v = sin((i.uv.x+_Time.x) * 3.14*2)*.5+0.5 ;
    v = smoothstep(0.1,0.9,i.uv.x);
    v = step(i.uv,0.5);
    v = pow(i.uv,4);
    
    return ShowLine(v,i.uv.y);
*/
#define ShowLine(v,pct) smoothstep(v-0.02,v,pct) - smoothstep(v,v+0.02,pct)


#endif //LINE_LIB_HLSL