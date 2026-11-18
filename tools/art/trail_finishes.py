"""Surface finishes for the five Legendary trail previews. All animation is on a local looping clock."""
CLOCKS = []


def finish(material, kind, accent=False):
    nodes, links = material.node_tree.nodes, material.node_tree.links
    shader = nodes["Principled BSDF"]
    coord = nodes.new("ShaderNodeTexCoord").outputs["Generated"]
    info = nodes.new("ShaderNodeObjectInfo")

    def wire(value, socket):
        if isinstance(value, (float, int, tuple)):
            socket.default_value = value
        else:
            links.new(value, socket)

    def calc(op, a, b=0):
        node = nodes.new("ShaderNodeMath")
        node.operation = op
        wire(a, node.inputs[0])
        wire(b, node.inputs[1])
        return node.outputs[0]

    def blend(factor, a, b):
        node = nodes.new("ShaderNodeMixRGB")
        wire(factor, node.inputs[0])
        wire(a, node.inputs[1])
        wire(b, node.inputs[2])
        return node.outputs[0]

    def channel(socket):
        return socket.links[0].from_socket if socket.is_linked else tuple(socket.default_value)

    def noise_at(stretch, frequency):
        scale = nodes.new("ShaderNodeVectorMath")
        scale.operation = "MULTIPLY"
        links.new(coord, scale.inputs[0])
        scale.inputs[1].default_value = stretch
        noise = nodes.new("ShaderNodeTexNoise")
        links.new(scale.outputs["Vector"], noise.inputs["Vector"])
        noise.inputs["Scale"].default_value = frequency
        noise.inputs["Detail"].default_value = 2
        return noise.outputs["Fac"]

    face = channel(shader.inputs["Base Color"])
    if kind in ("brushed", "edge_flash"):
        grain = noise_at((1, 21, 2), 14)
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Distance"].default_value = 0.004
        bump.inputs["Strength"].default_value = 0.18
        links.new(grain, bump.inputs["Height"])
        links.new(bump.outputs[0], shader.inputs["Normal"])
        shader.inputs["Roughness"].default_value = 0.18 if accent else 0.36
        value = nodes.new("ShaderNodeValue").outputs[0]
        CLOCKS.append(value)
        axes = nodes.new("ShaderNodeSeparateXYZ")
        links.new(coord, axes.inputs[0])
        diagonal = calc("ADD", axes.outputs["X"], calc("MULTIPLY", axes.outputs["Y"], 0.42))
        cycle = calc("FRACT", calc("ADD", calc("MULTIPLY", value, 1.24), info.outputs["Random"]))
        distance = calc("ABSOLUTE", calc("SUBTRACT", diagonal, calc("SUBTRACT", calc("MULTIPLY", cycle, 2.05), 0.30)))
        width = 0.18 if kind == "brushed" else 0.34
        flare = calc("MAXIMUM", 0, calc("SUBTRACT", 1, calc("DIVIDE", distance, width)))
        flare = calc("MULTIPLY", flare, 1 if accent or kind == "brushed" else 0.12)
        tint = blend(calc("MULTIPLY", grain, 0.17), face, (0.36, 0.42, 0.52, 1))
        links.new(blend(flare, tint, (1, 1, 1, 1)), shader.inputs["Base Color"])
        links.new(blend(flare, tint, (0.84, 0.94, 1, 1)), shader.inputs["Emission Color"])
        links.new(calc("ADD", 0.08, calc("MULTIPLY", flare, 3.5)), shader.inputs["Emission Strength"])
    elif kind == "folded":
        shader.inputs["Roughness"].default_value = 0.17 if accent else 0.35
        shader.inputs["Metallic"].default_value = 0.78
        # Both faces take the pulse colour. One remains dark even in the wave.
        tone = blend(0.16 if accent else 0.67, info.outputs["Color"], (0.024, 0.028, 0.043, 1))
        links.new(tone, shader.inputs["Base Color"])
        links.new(tone, shader.inputs["Emission Color"])
        shader.inputs["Emission Strength"].default_value = 1.15 if accent else 0.40
    elif kind in ("breaker", "jet"):
        crest = nodes.new("ShaderNodeAttribute")
        crest.attribute_name = "foam"
        grain = noise_at((1.5, 2.7, 1.4), 3.4)
        cells = nodes.new("ShaderNodeTexVoronoi")
        cells.feature = "DISTANCE_TO_EDGE"
        distortion=nodes.new("ShaderNodeTexNoise")
        links.new(coord,distortion.inputs["Vector"])
        distortion.inputs["Scale"].default_value=4.7
        distort=nodes.new("ShaderNodeVectorMath")
        distort.operation="SCALE"
        distort.inputs["Scale"].default_value=0.36
        links.new(distortion.outputs["Color"],distort.inputs[0])
        displaced=nodes.new("ShaderNodeVectorMath")
        displaced.operation="ADD"
        links.new(coord,displaced.inputs[0]); links.new(distort.outputs[0],displaced.inputs[1])
        cells.inputs["Scale"].default_value = 19
        links.new(displaced.outputs[0], cells.inputs["Vector"])
        lace = calc("MAXIMUM", 0, calc("SUBTRACT", 1, calc("MULTIPLY", cells.outputs["Distance"], 12)))
        cap = calc("ADD", calc("MULTIPLY", crest.outputs["Fac"], 0.60), calc("MULTIPLY", grain, 1.22))
        foam = calc("MINIMUM", 1, calc("MAXIMUM", 0, calc("MULTIPLY", calc("SUBTRACT", cap, 0.90), 2.65)))
        fringe = calc("MULTIPLY", lace, calc("MULTIPLY", crest.outputs["Fac"], 0.72))
        white = calc("MAXIMUM", foam, fringe)
        water = blend(calc("POWER",grain,1.35), face, (0.009, 0.47, 0.48, 1) if kind == "breaker" else (0.018, 0.35, 0.60, 1))
        paint = blend(white, water, (0.88, 0.98, 0.98, 1))
        links.new(paint, shader.inputs["Base Color"])
        links.new(paint, shader.inputs["Emission Color"])
        axes = nodes.new("ShaderNodeSeparateXYZ")
        links.new(coord, axes.inputs[0])
        along = axes.outputs["Y"]
        ends = calc("MINIMUM", along, calc("SUBTRACT",1,along))
        edge_fade = calc("MINIMUM",1,calc("MULTIPLY",ends,4.5))
        opacity = calc("ADD",0.40,calc("MULTIPLY",white,0.29))
        links.new(calc("MULTIPLY",info.outputs["Alpha"],calc("MULTIPLY",edge_fade,opacity)),shader.inputs["Alpha"])
        shader.inputs["Emission Strength"].default_value = 0.16
        shader.inputs["Roughness"].default_value = 0.22
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Distance"].default_value = 0.045
        bump.inputs["Strength"].default_value = 0.35
        links.new(calc("ADD",grain,calc("MULTIPLY",lace,0.11)), bump.inputs["Height"])
        links.new(bump.outputs[0], shader.inputs["Normal"])
    elif kind == "enamel":
        grain = noise_at((13, 10, 2), 13)
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Distance"].default_value = 0.006
        bump.inputs["Strength"].default_value = 0.32
        links.new(grain, bump.inputs["Height"])
        links.new(bump.outputs[0], shader.inputs["Normal"])
        tip=nodes.new("ShaderNodeAttribute"); tip.attribute_name="enamel_tip"
        ridge=nodes.new("ShaderNodeAttribute"); ridge.attribute_name="enamel_ridge"
        warm = blend(tip.outputs["Fac"],(0.47,0.33,0.15,1),face)
        tint = blend(calc("MULTIPLY",grain,calc("MULTIPLY",ridge.outputs["Fac"],0.45)),warm,(0.99,0.93,0.68,1))
        links.new(tint, shader.inputs["Base Color"])
        shader.inputs["Roughness"].default_value = 0.23
    elif kind == "rubber":
        texture = noise_at((2, 4, 1), 33)
        bump = nodes.new("ShaderNodeBump")
        bump.inputs["Distance"].default_value = 0.018
        links.new(texture, bump.inputs["Height"])
        links.new(bump.outputs[0], shader.inputs["Normal"])
        tint = blend(calc("MULTIPLY", texture, 0.16), face, (0.17, 0.16, 0.15, 1))
        links.new(tint, shader.inputs["Base Color"])
        shader.inputs["Roughness"].default_value = 0.86
    elif kind == "flame":
        def field(name):
            node = nodes.new("ShaderNodeAttribute")
            node.attribute_name = name
            return node.outputs["Fac"]
        grain = noise_at((1.1, 2.8, 3.3), 5)
        width, length = field("flame_width"), field("flame_length")
        wobble = calc("MULTIPLY", calc("SUBTRACT", grain, 0.5), 0.93)
        edge = calc("ABSOLUTE", calc("ADD", width, wobble))
        inside = calc("MAXIMUM", 0, calc("SUBTRACT", 1.0, edge))
        hot = calc("POWER", inside, 3.1)
        base = info.outputs["Color"]
        middle = blend(inside, (0.42, 0.015, 0.004, 1), base)
        luminous = channel(shader.inputs["Emission Color"]) if accent else (1, 0.40, 0.035, 1)
        links.new(blend(hot, middle, luminous), shader.inputs["Emission Color"])
        ends = calc("MINIMUM", calc("MULTIPLY", length, 6),
                    calc("MULTIPLY", calc("SUBTRACT", 1, length), 3))
        opacity = calc("MULTIPLY", calc("MINIMUM", ends, 1), calc("POWER", inside, 1.48))
        links.new(calc("MULTIPLY", opacity, info.outputs["Alpha"]), shader.inputs["Alpha"])
        shader.inputs["Base Color"].default_value = (0,0,0,1)
        shader.inputs["Emission Strength"].default_value = 1.36
