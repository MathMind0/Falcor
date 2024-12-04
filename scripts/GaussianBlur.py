from pathlib import WindowsPath, PosixPath
from falcor import *

def render_graph_DefaultRenderGraph():
    g = RenderGraph('DefaultRenderGraph')
    g.create_pass('ImageLoader', 'ImageLoader', {'outputSize': 'Default', 'filename': 'E:\\packman-repo\\chk\\falcor_media\\7acdf8b0\\test_images\\Chess.png', 'mips': False, 'srgb': True, 'arrayIndex': 0, 'mipLevel': 0})
    g.create_pass('GaussianBlur', 'GaussianBlur', {'kernelWidth': 5, 'sigma': 2.0})
    g.add_edge('ImageLoader.dst', 'GaussianBlur.src')
    g.add_edge('ImageLoader', 'GaussianBlur')
    g.mark_output('GaussianBlur.dst')
    return g

DefaultRenderGraph = render_graph_DefaultRenderGraph()
try: m.addGraph(DefaultRenderGraph)
except NameError: None
