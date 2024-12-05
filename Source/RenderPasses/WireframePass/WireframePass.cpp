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
#include "WireframePass.h"

extern "C" FALCOR_API_EXPORT void registerPlugin(Falcor::PluginRegistry& registry)
{
    registry.registerClass<RenderPass, WireframePass>();
}

WireframePass::WireframePass(ref<Device> pDevice, const Properties& props) : RenderPass(pDevice)
{
    mpProgram = Program::createGraphics(pDevice,
        "RenderPasses/WireframePass/WireframePass.3d.slang",
        "vsMain", "psMain");

    RasterizerState::Desc wireframeDesc;
    wireframeDesc.setFillMode(RasterizerState::FillMode::Wireframe);
    wireframeDesc.setCullMode(RasterizerState::CullMode::None);
    mpRasterState = RasterizerState::create(wireframeDesc);

    mpGraphicsState = GraphicsState::create(pDevice);
    mpGraphicsState->setProgram(mpProgram);
    mpGraphicsState->setRasterizerState(mpRasterState);
}

Properties WireframePass::getProperties() const
{
    return {};
}

RenderPassReflection WireframePass::reflect(const CompileData& compileData)
{
    // Define the required resources here
    RenderPassReflection reflector;
    reflector.addOutput("output", "output");
    // reflector.addInput("src");
    return reflector;
}

void WireframePass::setScene(RenderContext* pRenderContext, const ref<Scene>& pScene)
{
    mpScene = pScene;
    if (mpScene)
    {
        mpProgram->setDefines(mpScene->getSceneDefines());
    }

    mpVars = ProgramVars::create(pRenderContext->getDevice(), mpProgram->getReflector());
}

void WireframePass::execute(RenderContext* pRenderContext, const RenderData& renderData)
{
    // renderData holds the requested resources
    auto pFbo = Fbo::create(pRenderContext->getDevice(),
        {renderData.getTexture("output")});
    const float4 color {0.f, 0.f, 0.f, 1.f};
    pRenderContext->clearFbo(pFbo.get(), color, 1.f, 0);
    mpGraphicsState->setFbo(pFbo);

    if (mpScene)
    {
        auto var = mpVars->getRootVar();
        var["PerFrameCB"]["WireColor"] = float4(1.f, 1.f, 0.f, 0.f);

        mpScene->rasterize(pRenderContext, mpGraphicsState.get(), mpVars.get(),
            mpRasterState, mpRasterState);
    }
}

void WireframePass::renderUI(Gui::Widgets& widget) {}
