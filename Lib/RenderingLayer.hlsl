#if !defined(RENDERING_LAYER_HLSL)
#define RENDERING_LAYER_HLSL

uint _RenderingLayerMaxInt;
float _RenderingLayerRcpMaxInt;

uint GetMeshRenderingLayer()
{
    return asuint(unity_RenderingLayer.x);
}

float EncodeMeshRenderingLayer(uint renderingLayer)
{
    // Force any bits above max to be skipped
    renderingLayer &= _RenderingLayerMaxInt;

    // This is copy of "real PackInt(uint i, uint numBits)" from com.unity.render-pipelines.core\ShaderLibrary\Packing.hlsl
    // Differences of this copy:
    // - Pre-computed rcpMaxInt
    // - Returns float instead of real
    float rcpMaxInt = _RenderingLayerRcpMaxInt;
    return saturate(renderingLayer * rcpMaxInt);
}

uint DecodeMeshRenderingLayer(float renderingLayer)
{
    // This is copy of "uint UnpackInt(real f, uint numBits)" from com.unity.render-pipelines.core\ShaderLibrary\Packing.hlsl
    // Differences of this copy:
    // - Pre-computed maxInt
    // - Parameter f is float instead of real
    uint maxInt = _RenderingLayerMaxInt;
    return (uint)(renderingLayer * maxInt + 0.5); // Round instead of truncating
}

bool IsMatchRenderingLayer(uint lightLayer){
    return lightLayer & GetMeshRenderingLayer();
}

#endif //RENDERING_LAYER_HLSL