from pathlib import WindowsPath, PosixPath
from falcor import *

def render_graph_DefaultRenderGraph():
    g = RenderGraph('DefaultRenderGraph')
    g.create_pass('WireframePass', 'WireframePass', {})
    g.mark_output('WireframePass.output')
    return g

DefaultRenderGraph = render_graph_DefaultRenderGraph()
try: m.addGraph(DefaultRenderGraph)
except NameError: None
