"""Metal scrape showers in a flight preview. Fragments inherit the parent's position and velocity when they split."""
from dataclasses import dataclass
import math
import random

import bpy
from mathutils import Matrix, Quaternion, Vector


def fleck(bm):
    # A faceted hot grain with a chipped face and a short taper. Its size and spin vary per particle.
    rings = []
    for x, ry, rz in ((-0.72,0.012,0.015),(-0.28,0.12,0.075),(0.05,0.25,0.17),
                      (0.29,0.19,0.15),(0.39,0.055,0.070)):
        rings.append([bm.verts.new((x,ry*math.cos(a),rz*math.sin(a)+0.025*x))
                      for a in (0.10,1.08,2.48,3.33,4.41,5.46)])
    for band,(left,right) in enumerate(zip(rings,rings[1:])):
        for j in range(6):
            k=(j+1)%6
            bm.faces.new((left[j],right[j],right[k],left[k])).material_index=int(band>=2 and j in (0,1,4))
    bm.faces.new(rings[0])
    bm.faces.new(rings[-1]).material_index=1


def heat_material(name, bright_face):
    mat=bpy.data.materials.new(name)
    mat.use_nodes=True
    nt=mat.node_tree
    shader=nt.nodes["Principled BSDF"]
    info=nt.nodes.new("ShaderNodeObjectInfo")
    nt.links.new(info.outputs["Color"],shader.inputs["Emission Color"])
    shader.inputs["Base Color"].default_value=(0.41,0.39,0.35,1) if bright_face else (0.14,0.105,0.082,1)
    shader.inputs["Metallic"].default_value=0.80
    shader.inputs["Roughness"].default_value=0.24 if bright_face else 0.47
    shader.inputs["Emission Strength"].default_value=16 if bright_face else 5
    return mat


def bloom(sc):
    tree=bpy.data.node_groups.new("Incandescent metal bloom","CompositorNodeTree")
    tree.interface.new_socket(name="Image",in_out="OUTPUT",socket_type="NodeSocketColor")
    layers=tree.nodes.new("CompositorNodeRLayers")
    glare=tree.nodes.new("CompositorNodeGlare")
    glare.inputs["Type"].default_value="Fog Glow"
    glare.inputs["Threshold"].default_value=1.8
    glare.inputs["Strength"].default_value=0.63
    glare.inputs["Size"].default_value=0.23
    out=tree.nodes.new("NodeGroupOutput")
    tree.links.new(layers.outputs["Image"],glare.inputs["Image"])
    tree.links.new(glare.outputs["Image"],out.inputs["Image"])
    sc.compositing_node_group=tree


def halo_geometry():
    mesh=bpy.data.meshes.new("Soft spark halo")
    mesh.from_pydata([(-0.5,-0.5,0),(0.5,-0.5,0),(0.5,0.5,0),(-0.5,0.5,0)],[],[(0,1,2,3)])
    mat=bpy.data.materials.new("Amber bloom");mat.use_nodes=True
    nodes,links=mat.node_tree.nodes,mat.node_tree.links
    pos=nodes.new("ShaderNodeTexCoord")
    radius=nodes.new("ShaderNodeVectorMath");radius.operation="DISTANCE"
    links.new(pos.outputs["Object"],radius.inputs[0]);radius.inputs[1].default_value=(0,0,0)
    ramp=nodes.new("ShaderNodeValToRGB")
    links.new(radius.outputs["Value"],ramp.inputs[0])
    cr=ramp.color_ramp
    cr.elements[0].color=(0.83,0.83,0.83,1)
    cr.elements[1].position=0.49;cr.elements[1].color=(0,0,0,1)
    cr.elements.new(0.18).color=(0.23,0.23,0.23,1)
    cr.interpolation="EASE"
    info=nodes.new("ShaderNodeObjectInfo")
    strength=nodes.new("ShaderNodeMath");strength.operation="MULTIPLY"
    links.new(info.outputs["Alpha"],strength.inputs[0]);links.new(ramp.outputs[0],strength.inputs[1])
    glow=nodes.new("ShaderNodeEmission");glow.inputs[0].default_value=(1.0,0.29,0.035,1)
    mix=nodes.new("ShaderNodeMixShader")
    links.new(strength.outputs[0],mix.inputs[0]);links.new(nodes.new("ShaderNodeBsdfTransparent").outputs[0],mix.inputs[1])
    links.new(glow.outputs[0],mix.inputs[2]);links.new(mix.outputs[0],nodes["Material Output"].inputs[0])
    mesh.materials.append(mat)
    return mesh


@dataclass
class Grain:
    born: float
    life: float
    position: Vector
    velocity: Vector
    drag: float
    gravity: float
    size: float
    length: float
    heat: float
    spin: float
    phase: float

    def sample(self,age):
        drag=math.exp(-self.drag*age)
        fall=Vector((0,0,-self.gravity))
        return (self.position + self.velocity*((1-drag)/self.drag) + fall*(0.5*age**2),
                self.velocity*drag + fall*age)


class Shower:
    def __init__(self, scene, geometry, skipping):
        self.scene=scene
        self.geometry=geometry
        self.skipping=skipping
        self.rng=random.Random(81 if skipping else 28)
        self.next_burst=-1.2
        self.grains=[]
        self.pool=[]
        self.halo=halo_geometry()
        geometry.materials.append(heat_material("Cooling steel",False))
        geometry.materials.append(heat_material("Hot cut face",True))
        bloom(scene)

    def emit(self,t,tail,right,nose,up,speed):
        if t<self.next_burst:
            return
        r=self.rng
        self.next_burst=t+r.uniform(0.035,0.10)+(r.expovariate(9) if self.skipping else r.expovariate(15))
        side=r.choice((-1,1))
        angle=r.uniform(-0.46,1.17)
        spray=right*(side*math.cos(angle))+up*math.sin(angle)
        origin=tail+right*(side*r.uniform(0.98,1.56))-up*r.uniform(0.27,0.65)
        crowded=r.random() < (0.44 if self.skipping else 0.75)
        count=r.randint(9,22) if crowded else r.randint(1,5)
        for _ in range(count):
            born=t+r.uniform(0,0.06)
            kick=spray*r.uniform(5,32)+right*r.uniform(-11,11)+up*r.uniform(-11,18)
            velocity=kick+nose*speed*r.uniform(-0.08,0.31)
            at=origin+nose*speed*(born-t)+right*r.uniform(-0.28,0.28)+up*r.uniform(-0.16,0.16)
            grain=Grain(born,r.uniform(0.16,0.56),at,velocity,r.uniform(1.5,5),
                        r.uniform(18,58),r.triangular(0.095,0.51 if self.skipping else 0.41,0.19),
                        r.uniform(0.52,1.30),r.uniform(0.62,1.15),r.uniform(-22,22),r.uniform(0,math.tau))
            self.grains.append(grain)
            if r.random() < (0.46 if self.skipping else 0.13):
                split=r.uniform(0.048,0.15)
                point,inherited=grain.sample(split)
                grain.life=split
                for _ in range(r.randint(2,4)):
                    jump=inherited + right*r.uniform(-14,14)+up*r.uniform(-5,20)+nose*r.uniform(-7,5)
                    self.grains.append(Grain(born+split,r.uniform(0.09,0.34),point,jump,4.1,r.uniform(25,67),
                                             grain.size*r.uniform(0.34,0.68),r.uniform(0.6,1.4),r.uniform(0.5,0.96),
                                             r.uniform(-32,32),r.uniform(0,math.tau)))

    def pose(self,t,facing):
        self.grains=[g for g in self.grains if t<g.born+g.life]
        visible=[g for g in self.grains if g.born<=t]
        while len(self.pool)<len(visible):
            obj=bpy.data.objects.new("Steel grain",self.geometry)
            halo=bpy.data.objects.new("Grain glow",self.halo)
            self.scene.collection.objects.link(obj)
            self.scene.collection.objects.link(halo)
            self.pool.append((obj,halo))
        for i,(obj,halo) in enumerate(self.pool):
            obj.hide_render=halo.hide_render=i>=len(visible)
            if obj.hide_render: continue
            grain=visible[i]
            age=t-grain.born
            k=age/grain.life
            pos,velocity=grain.sample(age)
            turn=velocity.to_track_quat("X","Z") @ Quaternion((1,0,0),grain.phase+age*grain.spin)
            size=grain.size*min(1,(1-k)*6)
            stretch=grain.length*(0.72+min(0.95,velocity.length/49))
            obj.matrix_world=Matrix.Translation(pos) @ turn.to_matrix().to_4x4() @ Matrix.Diagonal((size*stretch,size,size,1))
            # The finest grains cool fastest. A glancing cut face briefly catches a second reflection.
            h=min(1,grain.heat*(1-k)**1.7)
            glint=0.75+0.25*max(0,math.cos(grain.phase+grain.spin*age))**7
            obj.color=(h**1.1*glint,h**3.3*0.80*glint,h**7*0.43,1)
            halo.matrix_world=Matrix.Translation(pos) @ facing.to_matrix().to_4x4() @ Matrix.Scale(size*(2.0+2.4*h),4)
            halo.color=(1,1,1,h**1.7*glint)
