import sys,math,json
from pathlib import Path
from PIL import Image,ImageOps,ImageDraw
folder=Path(sys.argv[1]); out=folder/'renders'
if (out/'closeups.png').exists():
    Image.open(out/'closeups.png').convert('RGB').save(out/'closeups.jpg',quality=95)
for channel in ['color','normal','roughness']:
    maps=sorted((folder/'parts').glob('*-'+channel+'.png'),key=lambda p:int(p.name.split('-')[0]))
    if not maps: continue
    sheet=Image.new('RGB',(2048,math.ceil(len(maps)/4)*550),'white'); d=ImageDraw.Draw(sheet)
    for k,p in enumerate(maps):
        x=(k%4)*512; y=(k//4)*550
        sheet.paste(ImageOps.contain(Image.open(p).convert('RGB'),(512,512)),(x,y+38))
        d.text((x+8,y+10),p.name,fill='black')
    sheet.save(out/('textures.png' if channel=='color' else 'textures-'+channel+'.png'))
print('Contact sheets:',folder.name)
hole=out/'hole-rays.json'
if hole.exists():
    import numpy as np
    from scipy import ndimage
    data=json.loads(hole.read_text())
    if 'grid' in data:
        a=np.asarray(data['grid'],bool)
        labels,n=ndimage.label(a)
        selected=labels[a.shape[0]//2,a.shape[1]//2]
        if selected:
            region=labels==selected; distance=ndimage.distance_transform_edt(region)
            iz,ix=np.unravel_index(distance.argmax(),distance.shape)
            spacing=data['sample_spacing']; midpoint=(a.shape[0]-1)/2
            data['largest_clear_circle_diameter']=round(float(distance[iz,ix]*spacing*2),2)
            data['clear_circle_center']=[round(data['center'][0]+(ix-midpoint)*spacing,2),
                round(data['center'][1]+(iz-midpoint)*spacing,2)]
            data['opening_area_studs2']=round(float(region.sum()*spacing**2),2)
        data.pop('grid')
        hole.write_text(json.dumps(data,indent=2)+'\n')
