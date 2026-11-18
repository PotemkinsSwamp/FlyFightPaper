"""Build the shared Legendary trail colour and alpha atlas. UVs use finish strips,
so tiny spinning pieces can keep their original mesh and share a single texture.
"""
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / "assets/models/trails/legendary-atlas.png"
SIZE = 256
NAMES = ("steel", "rim", "flame", "flame_hot", "wave", "gum", "gum_inner", "enamel",
         "root", "palate", "rubber", "tread", "white")
def make():
    import numpy as np
    from PIL import Image
    from scipy.ndimage import gaussian_filter

    rng = np.random.default_rng(16)
    y,x = np.mgrid[0:SIZE,0:SIZE] / (SIZE-1)
    def grain(sigma):
        a = gaussian_filter(rng.normal(size=x.shape),sigma,mode="wrap")
        return a/max(a.std(),.0001)
    def mix(a,b,f):
        f = np.clip(f,0,1)[...,None]
        return np.asarray(a)*(1-f) + np.asarray(b)*f
    tiles = {}
    brushed = grain((0.55,10)) * 9 + grain((2,33))*4
    tiles["steel"] = np.array([65,75,90])+brushed[...,None]
    tiles["rim"] = np.array([217,226,237])+0.55*brushed[...,None]
    curl = 0.08*np.sin(y*14)+0.065*grain((10,12))
    inside = np.clip(1-np.abs(2*x-1+curl),0,1)
    alpha = (inside**1.48 * np.minimum.reduce([np.ones_like(x),y*6,(1-y)*3]))
    for name,hot in (("flame",[255,173,42]),("flame_hot",[255,226,83])):
        rgb = mix(mix([162,40,12],[255,108,15],inside),hot,inside**3)
        tiles[name] = np.dstack([rgb,alpha*255])
    noise = grain(7)
    # Cellular foam follows the wave's measured crest; row zero is the clean trough.
    dy=0.018*grain(8); dx=0.018*grain(8)
    seed=rng.random((75,2))
    distances=np.stack([np.hypot((x+dx-a+0.5)%1-0.5,(y+dy-b+0.5)%1-0.5) for a,b in seed])
    nearest=np.partition(distances,1,axis=0)
    lace=np.exp(-90*(nearest[1]-nearest[0]))
    foam=np.clip((y*0.7+0.51+noise*.19-.87)*2.65,0,1)
    white=np.maximum(foam,y*lace*.82)
    water=mix([18,122,167],[43,173,204],.5+noise*.2)
    tiles["wave"] = np.dstack((mix(water,[234,251,250],white),255*(.40+.35*white)))
    for name,color in (("gum",[35,87,101]),("gum_inner",[174,106,105]),("root",[202,174,130]),
                       ("palate",[53,55,68]),("rubber",[37,34,36]),("tread",[104,99,94])):
        tiles[name] = np.array(color)+grain(.65)[...,None]*4
    tiles["enamel"] = mix([190,161,110],[255,249,219],y**.55)+grain((8,1))[...,None]*3
    tiles["white"]=np.full((*x.shape,3),255)
    page=Image.new("RGBA",(4*SIZE,4*SIZE),"white")
    for i,name in enumerate(NAMES):
        tile=Image.fromarray(np.clip(tiles[name],0,255).astype("uint8")).convert("RGBA")
        page.paste(tile,(i%4*SIZE,i//4*SIZE))
    page.save(OUT)

if __name__ == "__main__":
    make()
