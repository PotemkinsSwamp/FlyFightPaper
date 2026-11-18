"""Short, scuffed impressions left along the race plane's path."""
import math
import random

import bpy
import numpy as np


def rubber_material():
    # Lengthwise grooves, uneven pressure and ragged edges in the deposited rubber.
    rng = np.random.default_rng(713)
    width, length = 192, 512
    x = np.linspace(-1, 1, width)[None, :]
    y = np.linspace(0, 1, length)[:, None]
    drift = 0.034 * np.sin(y*8) + 0.018 * np.sin(y*29)
    across = x + drift
    edge = np.clip((1-np.abs(across))*8 + 0.30*np.sin(45*y), 0, 1)
    grooves = np.interp(across, np.linspace(-1.1, 1.1, 138), rng.uniform(0.09, 1, 138))
    pressure = np.clip((y - 0.12*across**2)*9, 0, 1) * np.clip((1-y-0.10*across**2)*7, 0, 1)
    grain = rng.uniform(0.4, 1.0, (length,width))
    ink = edge * pressure * np.clip(1.7*grooves + 0.55*grain - 0.52, 0, 1)
    pixels = np.ones((length,width,4), dtype=np.float32)
    pixels[:,:,3] = ink
    image = bpy.data.images.new("Rubber scuff opacity", width, length, alpha=True)
    image.pixels.foreach_set(pixels.ravel())
    image.update()
    material = bpy.data.materials.new("Dry tire rubber")
    material.use_nodes = True
    nodes, links = material.node_tree.nodes, material.node_tree.links
    rubber = nodes["Principled BSDF"]
    rubber.inputs["Base Color"].default_value = (0.022, 0.021, 0.024, 1)
    rubber.inputs["Roughness"].default_value = 1
    texture = nodes.new("ShaderNodeTexImage")
    texture.image = image
    fade = nodes.new("ShaderNodeMath")
    fade.operation = "MULTIPLY"
    links.new(texture.outputs["Alpha"], fade.inputs[0])
    links.new(nodes.new("ShaderNodeObjectInfo").outputs["Alpha"], fade.inputs[1])
    links.new(fade.outputs[0], rubber.inputs["Alpha"])
    return material


class SkidMarks:
    sections = 32
    linger = 0.83

    def __init__(self, scene):
        self.scene = scene
        self.rng = random.Random(47)
        self.next_mark = -1.15
        self.events = []
        self.pool = []
        self.rubber = rubber_material()

    def emit(self, t):
        if t < self.next_mark:
            return
        r = self.rng
        self.next_mark = t + r.uniform(0.81, 1.32)
        duration = r.uniform(0.16, 0.28)
        bend = r.uniform(-1.25, 1.25)
        side = r.choice((-1, 1))
        self.events.append((t, duration, side, bend, r.uniform(0.84, 1.06)))
        if r.random() < 0.78:
            self.events.append((t+r.uniform(0.01, 0.06), duration*r.uniform(0.66, 1.1),
                                -side, bend, r.uniform(0.66, 0.95)))

    def strip(self):
        mesh = bpy.data.meshes.new("Skid impression")
        mesh.from_pydata([(0,0,0)] * (2*self.sections), [],
                         [(i,i+1,i+3,i+2) for i in range(0, 2*self.sections-2, 2)])
        mesh.uv_layers.new()
        mesh.materials.append(self.rubber)
        obj = bpy.data.objects.new("Scuffed rubber", mesh)
        self.scene.collection.objects.link(obj)
        return obj

    def pose(self, t, past):
        self.events = [event for event in self.events if t < event[0]+event[1]+self.linger]
        active = [event for event in self.events if t > event[0]]
        while len(self.pool) < len(active):
            self.pool.append(self.strip())
        for index, obj in enumerate(self.pool):
            obj.hide_render = index >= len(active)
            if obj.hide_render:
                continue
            born, duration, side, bend, width = active[index]
            extent = min(1, (t-born)/duration)
            coords = []
            for j in range(self.sections):
                u = extent*j/(self.sections-1)
                stamp = born + u*duration
                _, tail, right, up, _ = past(stamp)
                bow = math.sin(math.pi*u)
                center = tail + right*(side*1.85 + bow*bend) - up*(1.08 + (t-stamp)*0.6)
                across = (right + up*(0.58*side + 0.25*bow)).normalized()
                edge = across*width*(0.72 + 0.28*bow)
                coords.extend(center-edge)
                coords.extend(center+edge)
            mesh = obj.data
            mesh.vertices.foreach_set("co", coords)
            uv = mesh.uv_layers.active.data
            for face in mesh.polygons:
                for loop, vertex in zip(face.loop_indices, face.vertices):
                    uv[loop].uv = (vertex%2, extent*(vertex//2)/(self.sections-1))
            fade = min(1, max(0, (born+duration+self.linger-t)/0.42))
            obj.color = (1, 1, 1, fade*0.94)
            mesh.update()
