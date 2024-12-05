import Scene.Raster;

cbuffer PerFrameCB
{
    float4 WireColor;
};

VSOut vsMain(VSIn in)
{
    return defaultVS(in);
}

float4 psMain() : SV_TARGET
{
    return WireColor;
}

