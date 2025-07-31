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

/**
    repeat uv in uvRange,used for Sprite in atlas
*/
float2 UVRepeat(float2 uv,float2 uvRange,float2 uvStart){
    uv %= uvRange;
    uv += sign(uv) < 0 ? uvRange : 0;
    uv += uvStart;
    return uv;
}
/**
    get uv from {uv0,uv1,uv2,uv}.
    uvId : (0,1,2,3)
*/
float2 GetUV(float4 uv_01,float4 uv_23,uint uvId){
    // uint groupId = uvId / 2;
    uint itemId = uvId % 2 * 2; //[0,1]*2
    float4 uv = uvId>=2?uv_23:uv_01;
    return float2(uv[itemId],uv[itemId+1]);
}

float2 GetUV1(float2 uv1,float2 lightmapUV,bool is_UV1TransformToLightmapUV){
    return is_UV1TransformToLightmapUV ? lightmapUV : uv1;
}

#endif //UV_MAPPING_HLSL            