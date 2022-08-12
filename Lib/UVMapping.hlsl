#if !defined(UV_MAPPING_HLSL)
#define UV_MAPPING_HLSL

/**
    Remap uv to rect uv

    id : 1d serial num
    uv : [0,1]
    sheet : [x:number of row,y:number of column]
    invertY : top to down
    playOnce : stop at end

    Testcase:
        float2 uv = i.uv;
        uv = RectUV(_Id * _Time.y,uv,_Sheet,true);
        half4 col = tex2D(_MainTex, uv);
*/
float2 RectUV(float id,float2 uv,half2 sheet,bool invertY,bool playOnce){
    int count = sheet.x*sheet.y;
    id = id % (count); // play loop
    /*
        id = min(count-0.1,id) // play once
    */
    // id = playOnce ? min(count-0.1,id) : id % (count); // play mode

    int x = (id % sheet.x);
    int y = (id / sheet.x);
    y= invertY ? (sheet.y-y-1) : y;

    half2 size = 1.0/sheet;
    half4 rect = half4(half2(x,y),half2(x+1,y+1)) * size.xyxy;
    return lerp(rect.xy,rect.zw,uv);
}

#endif //UV_MAPPING_HLSL            