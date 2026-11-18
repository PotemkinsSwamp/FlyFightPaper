"""Bake the classroom chests' hinged opening from their original illustrated prints.

Project an open-bottom barrel lid about its rear edge. The outside samples the
closed illustration at the same point on the shell. Inside is printed cardboard.
The box and its latch are composited last and never move relative to each other.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2] / "assets/ui/hangarshelf/chests"
# Left rear hinge, left front corner, right front corner, roof height, lid depth.
# Coordinates are measured on each 512px closed print.
CASES = {
    "paper": ((34,225), (139,263), (482,236), 151, 186,
              [(263,255),(266,232),(271,228),(355,224),(361,228),(365,249)]),
    "sticker": ((17,223), (116,262), (471,238), 149, 183,
                [(246,253),(247,240),(253,235),(330,233),(337,237),(342,249)]),
    "blue_ribbon": ((29,198), (143,237), (486,209), 152, 184,
                    [(228,233),(231,223),(249,183),(264,177),(285,157),(326,156),
                     (348,162),(367,167),(386,183),(399,197),(408,215)]),
    "golden_star": ((16,197), (126,232), (474,208), 146, 182,
                    [(222,226),(230,221),(273,212),(301,173),(306,167),
                     (311,167),(316,176),(337,215),(343,217)]),
}
ANGLES = [0,7,16,26,38,50,63,76,89,100,109,115,117,115,112,111]
# Sheet cells cover this square in source coordinates, including the lid's swept arc.
LEFT, TOP, SPAN, CELL = -108, -143, 640, 512
Y, X = np.mgrid[:CELL,:CELL]
X = LEFT + (X + .5) * SPAN / CELL
Y = TOP + (Y + .5) * SPAN / CELL


def sample(im,x,y):
    return im[np.clip(np.rint(y).astype(int),0,511),np.clip(np.rint(x).astype(int),0,511)]


def bake(im, lining, case, angle):
    rear, front, right, height, depth, clasp = case
    dx,dy = np.subtract(front,rear)
    wx,wy = np.subtract(right,front)
    if not angle:
        closed = sample(im,X,Y).copy()
        closed[(X<0)|(X>=512)|(Y<0)|(Y>=512)]=0
        return closed
    # Along a view ray t increases toward the player. z is height above the rear hinge.
    u0=(X-rear[0])/wx
    du=-dx/wx
    z0=rear[1]+wy*u0-Y
    dz=dy+wy*du
    c,s=np.cos(np.radians(angle)),np.sin(np.radians(angle))
    v0,dv=z0*s/depth,c+dz*s/depth
    h0,dh=z0*c,-depth*s+dz*c
    a=4*dv**2+(dh/height)**2
    b=4*(2*v0-1)*dv+2*h0*dh/height**2
    disc=b*b-4*a*((2*v0-1)**2+(h0/height)**2-1)
    root=np.sqrt(np.maximum(0,disc))
    far,near=(-b-root)/(2*a),(-b+root)/(2*a)
    output=np.zeros((CELL,CELL,4),np.uint8)
    best=np.full(X.shape,-np.inf)

    def surface(t,valid,inside):
        u,v,h=u0+du*t,v0+dv*t,h0+dh*t
        take=valid & (t>best) & (u>=-.001)&(u<=1.001)&(v>=-.002)&(v<=1.002)&(h>=-.1)
        if not take.any(): return
        uu,vv,hh=u[take],v[take],h[take]
        sx,sy=rear[0]+wx*uu+dx*vv,rear[1]+wy*uu+dy*vv-hh
        exterior=sample(im,sx,sy).copy()
        # The clasp occludes a small patch of the closed roof. Continue its underlying
        # paper sideways here so the complete clasp appears only on the stationary front.
        edge=np.interp(sx,[p[0] for p in clasp],[p[1] for p in clasp])
        hidden=(sx>=clasp[0][0]-2)&(sx<=clasp[-1][0]+2)&(sy>=edge-2)
        exterior[hidden]=sample(im,clasp[0][0]-16-(sx[hidden]%11),sy[hidden]-2)
        rgb=exterior[:,:3].astype(float)
        if inside:
            # The inner curve is lined in kraft paper with a folded lip and two ribs.
            grain=lining[(np.rint(115*vv+hh*.34).astype(int)%lining.shape[0]),
                         (np.rint(380*uu+64*vv).astype(int)%lining.shape[1])]
            light=.58+.22*vv+.16*(1-np.sin(np.pi*vv))+.08*np.sin(np.pi*uu)
            rib=(np.abs(uu-.105)<.012)|(np.abs(uu-.90)<.012)
            light+=.13*rib+.16*(hh<5)
            rgb=grain*np.clip(light,.5,1.12)[:,None]
            # The turned edge carries the original trim around the opening.
            rim=(hh<6)|(uu<.014)|(uu>.986)
            trim=sample(im,front[0]+26+16*uu,front[1]+9)[:,:3]
            rgb[rim]=trim[rim]*(.88+.10*vv[rim,None])
        else:
            # Receding edge pixels in the source can contain the transparent background.
            blank=exterior[:,3]<110
            rgb[blank]=sample(im,front[0]+24+uu[blank]*20,front[1]-34)[:,:3]
        output[take,:3]=np.clip(rgb,0,255).astype(np.uint8)
        output[take,3]=255
        best[take]=t[take]

    # Far skin of the dome is seen through the open underside. The near skin is outside.
    surface(far,disc>=0,True)
    surface(near,disc>=0,False)
    for end in (0,1):
        t=(end-u0)/du
        vv,hh=v0+dv*t,h0+dh*t
        surface(t,(2*vv-1)**2+(hh/height)**2<=1,end==1)

    # The static mouth is a recessed paper-lined box between the four original rim corners.
    t=(Y-rear[1]-wy*u0)/dz
    u=u0+du*t
    mouth=(t>=0)&(t<=1)&(u>=0)&(u<=1)
    # Only the portion in front of the open lid's surface occludes that surface.
    take=mouth&(t>best)
    lining_rgb=lining[(np.floor(Y).astype(int)%lining.shape[0]),(np.floor(X).astype(int)%lining.shape[1])]
    light=np.clip(.44+.43*t,.34,.94)
    light+=.18*((t<.06)|(u<.018)|(u>.98))
    output[take,:3]=(lining_rgb[take]*light[take,None]).clip(0,255).astype(np.uint8)
    output[take,3]=255
    # Two brass hinge barrels straddle the rear rail. The closed shell hides them.
    if angle>=26:
        for along in (.18,.81):
            hx,hy=rear[0]+wx*along,rear[1]+wy*along
            ax=X-hx
            ay=Y-(hy+wy/wx*ax)
            barrel=(abs(ax)<14)&(abs(ay)<3.5)&(best<.035)
            grooves=(abs(ax-5)<.85)|(abs(ax+5)<.85)
            shine=(.63+.50*np.exp(-((ay+.8)/1.35)**2)-.23*grooves)
            output[barrel,:3]=(np.array([188,154,95])*shine[barrel,None]).clip(0,255)
            output[barrel,3]=255
    xx=np.arange(512)
    baseline=np.interp(xx,[rear[0],front[0],right[0]],[rear[1],front[1],right[1]])
    mask=Image.new("L",(512,512))
    draw=ImageDraw.Draw(mask)
    draw.polygon([(x,round(y)) for x,y in enumerate(baseline)]+[(511,511),(0,511)],fill=255)
    draw.polygon(clasp+[(clasp[-1][0],310),(clasp[0][0],310)],fill=255)
    front_pixels=sample(im,X,Y)
    keep=(sample(np.asarray(mask),X,Y)>0)&(front_pixels[:,:,3]>0)&(X>=0)&(X<512)&(Y>=0)&(Y<512)
    output[keep]=front_pixels[keep]
    return output


def main():
    paper=Image.open(ROOT/'classroom-chests.png').convert('RGBA')
    # Unprinted cardboard fibres from the cream Paper chest's side.
    grain=np.array(paper.crop((181,274,258,298)))[:,:,:3].astype(float).mean(axis=2)
    grain-=np.median(grain)
    lining=np.array([215.,183.,143.])+np.clip(grain,-18,15)[:,:,None]*.65
    for family,source in [('skin',paper),('trail',Image.open(ROOT/'trail-chests.png').convert('RGBA'))]:
        for i,(tier,case) in enumerate(CASES.items()):
            x,y=i%2*512,i//2*512
            im=np.array(source.crop((x,y,x+512,y+512)))
            sheet=Image.new('RGBA',(CELL*4,CELL*4))
            for j,angle in enumerate(ANGLES):
                frame=Image.fromarray(bake(im,lining,case,angle))
                sheet.paste(frame,(j%4*CELL,j//4*CELL))
            sheet.save(ROOT/f'{family}-{tier}-hinge.png')


if __name__=='__main__':
    main()
