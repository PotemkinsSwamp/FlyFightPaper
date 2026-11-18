"""Camera-projected refraction on swept-wing air pockets. Sample the clean view from this exact frame."""
import math
import bpy


def air_pocket(bm):
    edge=bm.verts.layers.float.new("cloak_perimeter")
    outline=((0,0.61),(0.52,-0.29),(0.36,-0.27),(0.23,-0.37),(0.10,-0.26),
             (0,-0.34),(-0.10,-0.26),(-0.23,-0.37),(-0.36,-0.27),(-0.52,-0.29))
    outer=[bm.verts.new((x,y,0.015)) for x,y in outline]
    for v in outer: v[edge]=1.0
    for side in (1,-1):
        rings=[outer]
        for radius,z in ((0.90,0.014),(0.73,0.063),(0.40,0.11)):
            ring=[]
            for x,y in outline:
                v=bm.verts.new((x*radius,y*radius,z*side + 0.016*radius*math.cos(5*x)))
                v[edge]=0
                ring.append(v)
            rings.append(ring)
        for a,b in zip(rings,rings[1:]):
            for j in range(len(outline)):
                n=(j+1)%len(outline)
                bm.faces.new((a[j],a[n],b[n],b[j])).smooth=True
        tip=bm.verts.new((0,0.025,0.11*side))
        for j in range(len(outline)):
            bm.faces.new((rings[-1][j],rings[-1][(j+1)%len(outline)],tip)).smooth=True


class Cloak:
    def __init__(self,scene):
        self.collection=bpy.data.collections.new("Refracting pockets")
        scene.collection.children.link(self.collection)
        self.screens=[]
        self.image=None

    def finish(self,material,stream=False):
        nodes,links=material.node_tree.nodes,material.node_tree.links
        coord=nodes.new("ShaderNodeTexCoord")
        camera=nodes.new("ShaderNodeCameraData")
        info=nodes.new("ShaderNodeObjectInfo")
        normal=nodes.new("ShaderNodeVectorTransform")
        normal.vector_type="NORMAL"
        normal.convert_from,normal.convert_to="WORLD","CAMERA"
        links.new(nodes.new("ShaderNodeNewGeometry").outputs["Normal"],normal.inputs[0])

        def math_node(op,a,b):
            node=nodes.new("ShaderNodeMath")
            node.operation=op
            for i,value in enumerate((a,b)):
                if isinstance(value,(float,int)): node.inputs[i].default_value=value
                else: links.new(value,node.inputs[i])
            return node.outputs[0]

        # Close pockets bend a few dozen pixels. Distant pockets displace only a few.
        depth=math_node("MAXIMUM",camera.outputs["View Z Depth"],3.4)
        strength=math_node("MINIMUM",0.085,math_node("DIVIDE",0.54,depth))
        envelope = None
        if stream:
            fade = nodes.new("ShaderNodeAttribute")
            fade.attribute_name = "wake_strength"
            geometry = nodes.new("ShaderNodeNewGeometry")
            angle = nodes.new("ShaderNodeVectorMath")
            angle.operation = "DOT_PRODUCT"
            links.new(geometry.outputs["Incoming"], angle.inputs[0])
            links.new(geometry.outputs["Normal"], angle.inputs[1])
            soft_edge = math_node("MINIMUM", 1, math_node("MULTIPLY", 4,
                                  math_node("ABSOLUTE", angle.outputs["Value"], 0)))
            envelope = math_node("MULTIPLY", fade.outputs["Fac"], soft_edge)
            strength = math_node("MULTIPLY", strength, math_node("MULTIPLY", 1.6, envelope))
        offset=nodes.new("ShaderNodeVectorMath");offset.operation="MULTIPLY"
        links.new(normal.outputs[0],offset.inputs[0]);offset.inputs[1].default_value=(0.67,1,0)
        scale=nodes.new("ShaderNodeVectorMath");scale.operation="SCALE"
        links.new(offset.outputs[0],scale.inputs[0]);links.new(strength,scale.inputs["Scale"])
        sample_at=nodes.new("ShaderNodeVectorMath");sample_at.operation="ADD"
        links.new(coord.outputs["Window"],sample_at.inputs[0]); links.new(scale.outputs[0],sample_at.inputs[1])
        screen=nodes.new("ShaderNodeTexImage");screen.extension="EXTEND"
        links.new(sample_at.outputs[0],screen.inputs["Vector"]);self.screens.append(screen)
        rim=nodes.new("ShaderNodeAttribute");rim.attribute_name="cloak_perimeter"
        # A violet reflection travels around only the facing portion of the perimeter.
        facing=nodes.new("ShaderNodeVectorMath");facing.operation="DOT_PRODUCT"
        links.new(normal.outputs[0],facing.inputs[0]);facing.inputs[1].default_value=(-0.62,0.73,0.28)
        factor=math_node("MINIMUM",1,math_node("ADD",0.31,math_node("MAXIMUM",0,facing.outputs["Value"])))
        factor=math_node("MULTIPLY",math_node("POWER",rim.outputs["Fac"],0.56),factor)
        film=nodes.new("ShaderNodeMixRGB")
        sheen=math_node("MULTIPLY",math_node("ABSOLUTE",facing.outputs["Value"],0),0.19)
        links.new(sheen,film.inputs[0]);links.new(screen.outputs["Color"],film.inputs[1])
        film.inputs[2].default_value=(0.19,0.12,0.33,1)
        tint=nodes.new("ShaderNodeMixRGB")
        links.new(factor,tint.inputs[0]);links.new(film.outputs[0],tint.inputs[1]);tint.inputs[2].default_value=(0.65,0.16,1.65,1)
        emit=nodes.new("ShaderNodeEmission");links.new(tint.outputs[0],emit.inputs[0])
        mix=nodes.new("ShaderNodeMixShader");links.new(envelope if stream else info.outputs["Alpha"],mix.inputs[0])
        links.new(nodes.new("ShaderNodeBsdfTransparent").outputs[0],mix.inputs[1]);links.new(emit.outputs[0],mix.inputs[2])
        links.new(mix.outputs[0],nodes["Material Output"].inputs["Surface"])

    def capture(self,scene,path,foreground=()):
        self.collection.hide_render=True
        scene.render.filepath=str(path)
        visibility = [(obj, obj.hide_render) for obj in foreground]
        try:
            for obj, _ in visibility:
                obj.hide_render = True
            bpy.ops.render.render(write_still=True)
        finally:
            for obj, hidden in visibility:
                obj.hide_render = hidden
            self.collection.hide_render=False
        if self.image is None:
            self.image=bpy.data.images.load(str(path))
            for texture in self.screens: texture.image=self.image
        else:
            self.image.reload()


class Stream:
    """One continuous surface, swept down the jet's flight path."""
    rings = 78
    sides = 28

    def __init__(self, cloak, material):
        self.mesh = bpy.data.meshes.new("Cloaking wake")
        faces = []
        for i in range(self.rings - 1):
            for j in range(self.sides):
                k = (j + 1) % self.sides
                base = i * self.sides
                faces.append((base+j, base+k, base+k+self.sides, base+j+self.sides))
        self.mesh.from_pydata([(0,0,0)] * (self.rings * self.sides), [], faces)
        for face in self.mesh.polygons:
            face.use_smooth = True
        for name in ("cloak_perimeter", "wake_strength"):
            self.mesh.attributes.new(name, "FLOAT", "POINT")
        cloak.finish(material, stream=True)
        self.mesh.materials.append(material)
        cloak.collection.objects.link(bpy.data.objects.new("Refracting slipstream", self.mesh))

    def pose(self, t, past):
        coords, glints, strength = [], [], []
        for i in range(self.rings):
            k = i / (self.rings - 1)
            _, tail, right, up, growth = past(t - k * 0.80)
            phase = k * 22 - t * 3.9
            width = (0.48 + 2.25 * (1 - math.exp(-16*k))) * (1 - k**2.4) * growth
            height = width * (0.41 + 0.12 * math.sin(phase))
            center = tail + right * width * 0.17 * math.sin(phase * 0.74) + up * height * 0.31 * math.cos(phase)
            for j in range(self.sides):
                angle = math.tau * j / self.sides
                fold = 1 + 0.21 * math.cos(3*angle + phase) + 0.14 * math.sin(2*angle - phase*0.65)
                point = center + right * (math.cos(angle) * width * fold)
                point += up * height * (math.sin(angle)*fold + 0.35*math.cos(2*angle + phase))
                coords.extend(point)
                glints.append(0.15 * max(0, math.cos(2*angle + phase))**7)
                strength.append(min(1, (1-k)*3.1) * min(1, 0.45 + k*22))
        self.mesh.vertices.foreach_set("co", coords)
        self.mesh.attributes["cloak_perimeter"].data.foreach_set("value", glints)
        self.mesh.attributes["wake_strength"].data.foreach_set("value", strength)
        self.mesh.update()

def paper_floor(material):
    """Lines on the flight course give the lens a continuous reference during the chase shot."""
    nodes,links=material.node_tree.nodes,material.node_tree.links
    coords=nodes.new("ShaderNodeTexCoord")
    axes=nodes.new("ShaderNodeSeparateXYZ")
    links.new(coords.outputs["Object"],axes.inputs[0])
    def rule(axis,spacing,width):
        repeat=nodes.new("ShaderNodeMath");repeat.operation="PINGPONG"
        links.new(axes.outputs[axis],repeat.inputs[0]);repeat.inputs[1].default_value=spacing/2
        thin=nodes.new("ShaderNodeMath");thin.operation="LESS_THAN"
        links.new(repeat.outputs[0],thin.inputs[0]);thin.inputs[1].default_value=width/2
        return thin.outputs[0]
    ruled=nodes.new("ShaderNodeMixRGB")
    links.new(rule("Y",9.2,0.65),ruled.inputs[0])
    ruled.inputs[1].default_value=(0.46,0.45,0.38,1)
    ruled.inputs[2].default_value=(0.10,0.25,0.31,1)
    margin=nodes.new("ShaderNodeMixRGB")
    links.new(rule("X",79,0.9),margin.inputs[0])
    links.new(ruled.outputs[0],margin.inputs[1]);margin.inputs[2].default_value=(0.46,0.145,0.12,1)
    links.new(margin.outputs[0],nodes["Principled BSDF"].inputs["Base Color"])
