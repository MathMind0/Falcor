/***************************************************************************
 # Copyright (c) 2015-23, NVIDIA CORPORATION. All rights reserved.
 #
 # Redistribution and use in source and binary forms, with or without
 # modification, are permitted provided that the following conditions
 # are met:
 #  * Redistributions of source code must retain the above copyright
 #    notice, this list of conditions and the following disclaimer.
 #  * Redistributions in binary form must reproduce the above copyright
 #    notice, this list of conditions and the following disclaimer in the
 #    documentation and/or other materials provided with the distribution.
 #  * Neither the name of NVIDIA CORPORATION nor the names of its
 #    contributors may be used to endorse or promote products derived
 #    from this software without specific prior written permission.
 #
 # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS "AS IS" AND ANY
 # EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 # IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 # PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 # CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 # PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 # PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 # OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 # (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 # OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **************************************************************************/
cbuffer BlitParamsCB
{
    float2 gOffset;
    float2 gScale;
    float4 gCompTransformR;
    float4 gCompTransformG;
    float4 gCompTransformB;
    float4 gCompTransformA;
}

#ifndef CUBEMAP
#define CUBEMAP 0
#endif

//[TJJ MOD] Support blit for cubemap
#if CUBEMAP
    #if SAMPLE_COUNT <= 1
        TextureCube<float4> gTex;
    #else // SAMPLE_COUNT > 1
        #error Cubemap blit not supported for multisample format
    #endif // SAMPLE_COUNT
#else // !CUBEMAP
    #if SAMPLE_COUNT <= 1
        Texture2D<float4> gTex;
    #else // SAMPLE_COUNT > 1
        Texture2DMS<float4> gTex;
    #endif // SAMPLE_COUNT
#endif // CUBEMAP

SamplerState gSampler;
SamplerState gSamplerR;
SamplerState gSamplerG;
SamplerState gSamplerB;
SamplerState gSamplerA;

struct VsOut
{
    float2 texC : TEXCOORD;
    float4 posH : SV_POSITION;
};

VsOut vsMain(float4 posS: POSITION, float2 texC: TEXCOORD)
{
    VsOut vOut;
    vOut.texC = texC * gScale + gOffset;
    vOut.posH = posS;
    return vOut;
}

//[TJJ MOD] Support blit for cubemap
#if CUBEMAP
    void psMain(float2 texC: TEXCOORD,
        out float4 face0 : SV_TARGET0,
        out float4 face1 : SV_TARGET1,
        out float4 face2 : SV_TARGET2,
        out float4 face3 : SV_TARGET3,
        out float4 face4 : SV_TARGET4,
        out float4 face5 : SV_TARGET5)
#else // !CUBEMAP
    #if DST_INT
        uint4 psMain(float2 texC: TEXCOORD) : SV_TARGET
    #else // !DST_INT
        float4 psMain(float2 texC: TEXCOORD) : SV_TARGET
    #endif // DST_INT
#endif // CUBEMAP
{
//[TJJ MOD] Support blit for cubemap
#if CUBEMAP
    #if SAMPLE_COUNT <= 1
        #if COMPLEX_BLIT
            #error Complex blit not supported for cubemap
        #else // !COMPLEX_BLIT
            #if SRC_INT
                #error Cubemap blit not supported for integer format
            #else
                float u = texC.x * 2.0f - 1.0f;
                float v = texC.y * 2.0f - 1.0f;
                face0 = gTex.SampleLevel(gSampler, float3(1.f, -v, -u), 0.f);
                face1 = gTex.SampleLevel(gSampler, float3(-1.f, -v, u), 0.f);
                face2 = gTex.SampleLevel(gSampler, float3(u, 1.f, v), 0.f);
                face3 = gTex.SampleLevel(gSampler, float3(u, -1.f, -v), 0.f);
                face4 = gTex.SampleLevel(gSampler, float3(u, -v, 1.f), 0.f);
                face5 = gTex.SampleLevel(gSampler, float3(u, v, -1.f), 0.f);
            #endif
        #endif
    #else // SAMPLE_COUNT > 1
        #error Cubemap blit not supported for multisample format
    #endif
#else // !CUBEMAP
    #if SAMPLE_COUNT <= 1
        #if COMPLEX_BLIT
        #if SRC_INT
        #error Complex blit not supported for integer source format
        #else
            float4 srcR = gTex.Sample(gSamplerR, texC);
            float4 srcG = gTex.Sample(gSamplerG, texC);
            float4 srcB = gTex.Sample(gSamplerB, texC);
            float4 srcA = gTex.Sample(gSamplerA, texC);

            float4 res;
            res.r = dot(gCompTransformR, srcR);
            res.g = dot(gCompTransformG, srcG);
            res.b = dot(gCompTransformB, srcB);
            res.a = dot(gCompTransformA, srcA);

            return res;
        #endif
        #else // !COMPLEX_BLIT
        #if SRC_INT
            uint4 res = asuint(gTex.SampleLevel(gSampler, texC, 0.f));
        #else
            float4 res = gTex.SampleLevel(gSampler, texC, 0.f);
        #endif
            return res;
        #endif
    #else // SAMPLE_COUNT > 1
        #if COMPLEX_BLIT
            #error Complex blit not supported for sample count > 1
        #else // !COMPLEX_BLIT
            #if SRC_INT
                #error Blit for sample count > 1 not supported for integer source format
            #else // !SRC_INT
                uint3 dims;
                gTex.GetDimensions(dims.x, dims.y, dims.z);
                uint2 crd = (uint2)(float2(dims.xy) * texC);
                float4 c = float4(0, 0, 0, 0);

                [unroll]
                for (uint i = 0; i < SAMPLE_COUNT; i++)
                {
                    c += gTex.Load(crd, i);
                }

                c /= SAMPLE_COUNT;
                return c;
            #endif // SRC_INT
        #endif // COMPLEX_BLIT
    #endif // SAMPLE_COUNT
#endif // CUBEMAP
}
