#if !defined(UV_MAPPING_HLSL)
#define UV_MAPPING_HLSL

/**
    Remap uv to rect uv

    sheet[x:number of row,y:number of column]

    Testcase:
        float2 uv = i.uv;
        uv = RectUV(_Id * _Time.y,uv,_Sheet,true);
        half4 col = tex2D(_MainTex, uv);
*/
float2 RectUV(float id,float2 uv,half2 sheet,bool invertY){
    id %= (sheet.x*sheet.y);

    int x = (id % sheet.x);
    int y = (id / sheet.x);
    y= invertY ? (sheet.y-y-1) : y;

    half2 size = 1.0/sheet;
    half4 rect = half4(half2(x,y),half2(x+1,y+1)) * size.xyxy;
    return lerp(rect.xy,rect.zw,uv);
}

#endif //UV_MAPPING_HLSL            