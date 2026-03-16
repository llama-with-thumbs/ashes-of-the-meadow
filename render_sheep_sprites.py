"""Blender script: open sheep .blend, color it, render from multiple angles as PNGs."""
import bpy
import math
import os

OUTPUT_DIR = os.path.join(os.path.dirname(bpy.data.filepath) if bpy.data.filepath else
    r"C:\Users\laman\Documents\git\ashes-of-the-meadow", "assets", "sprites")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# --- Clean up default objects ---
for obj in list(bpy.data.objects):
    if obj.type in ('CAMERA', 'LIGHT') and obj.name not in ('Camera',):
        pass  # keep

# --- Find mesh objects (the sheep) ---
mesh_objects = [o for o in bpy.data.objects if o.type == 'MESH']
print(f"Found {len(mesh_objects)} mesh objects: {[o.name for o in mesh_objects]}")

if not mesh_objects:
    print("ERROR: No mesh objects found!")
    bpy.ops.wm.quit_blender()

# --- Helper: create a simple colored material ---
def make_mat(mat_name, color, roughness=0.6, metallic=0.0, subsurface=0.0):
    m = bpy.data.materials.new(name=mat_name)
    m.use_nodes = True
    ns = m.node_tree.nodes
    ls = m.node_tree.links
    for n in ns:
        ns.remove(n)
    b = ns.new('ShaderNodeBsdfPrincipled')
    b.location = (0, 0)
    b.inputs['Base Color'].default_value = color
    b.inputs['Roughness'].default_value = roughness
    b.inputs['Metallic'].default_value = metallic
    if subsurface > 0:
        b.inputs['Subsurface Weight'].default_value = subsurface
    o = ns.new('ShaderNodeOutputMaterial')
    o.location = (300, 0)
    ls.new(b.outputs['BSDF'], o.inputs['Surface'])
    return m

# --- Whimsical cartoon colors (NO grey!) ---

# Wool/body — soft lavender-pink (fluffy cotton candy)
mat_wool = make_mat("SheepWool", (0.85, 0.65, 0.90, 1.0), roughness=0.7, subsurface=0.2)

# Face/head — warm peachy-orange (cute cartoon face)
mat_face = make_mat("SheepFace", (1.0, 0.6, 0.4, 1.0), roughness=0.5, subsurface=0.15)

# Ears — bright coral pink
mat_ears = make_mat("SheepEars", (1.0, 0.45, 0.55, 1.0), roughness=0.5, subsurface=0.1)

# Eyes — big bright sky blue
mat_eyes = make_mat("SheepEyes", (0.4, 0.75, 1.0, 1.0), roughness=0.15)

# Glasses — candy purple, shiny
mat_glasses = make_mat("SheepGlasses", (0.55, 0.2, 0.85, 1.0), roughness=0.15, metallic=0.7)

# Legs/bottom/cloth — mint green
mat_legs = make_mat("SheepLegs", (0.4, 0.9, 0.7, 1.0), roughness=0.5)

# Horns/curves — warm sunshine yellow
mat_horns = make_mat("SheepHorns", (1.0, 0.85, 0.3, 1.0), roughness=0.4)

# --- Assign materials by part name ---
glasses_parts = {'Glasses', 'Glasses.001', 'Glasses.002', 'Glasses.003'}
leg_parts = {'Bottom', 'Cylinder.003', 'Cylinder.004', 'Cylinder.005', 'Cylinder.010'}
horn_parts = {'BezierCurve', 'BezierCurve.001', 'BezierCurve.002', 'BezierCurve.003', 'SurfPatch', 'SurfPatch.002'}
cloth_parts = {'Cloth', 'Cloth.001', 'Cloth.002', 'Cloth.004'}

for obj in mesh_objects:
    obj.data.materials.clear()
    name = obj.name
    if name in ('eye', 'eye.001'):
        obj.data.materials.append(mat_eyes)
    elif name == 'head':
        obj.data.materials.append(mat_face)
    elif name == 'ears':
        obj.data.materials.append(mat_ears)
    elif name in glasses_parts:
        obj.data.materials.append(mat_glasses)
    elif name in leg_parts:
        obj.data.materials.append(mat_legs)
    elif name in horn_parts:
        obj.data.materials.append(mat_horns)
    elif name in cloth_parts:
        obj.data.materials.append(mat_legs)  # Mint green cloth too
    else:
        # Body/wool — lavender pink
        obj.data.materials.append(mat_wool)

# --- Calculate bounding box center and size (from vertices) ---
import mathutils

all_coords = []
for obj in mesh_objects:
    mesh = obj.data
    for v in mesh.vertices:
        all_coords.append(obj.matrix_world @ v.co)

min_co = mathutils.Vector((min(c.x for c in all_coords), min(c.y for c in all_coords), min(c.z for c in all_coords)))
max_co = mathutils.Vector((max(c.x for c in all_coords), max(c.y for c in all_coords), max(c.z for c in all_coords)))
center = (min_co + max_co) / 2
dims = max_co - min_co
size = max(dims.x, dims.y, dims.z)

print(f"Model center: {center}, dims: {dims}, size: {size}")

# --- Setup camera ---
cam_data = bpy.data.cameras.new("RenderCam")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = size * 0.7
cam_obj = bpy.data.objects.new("RenderCam", cam_data)
bpy.context.scene.collection.objects.link(cam_obj)
bpy.context.scene.camera = cam_obj

# --- Setup lighting ---
# Key light
key_data = bpy.data.lights.new("KeyLight", 'SUN')
key_data.energy = 8.0
key_data.color = (1.0, 0.97, 0.95)
key_obj = bpy.data.objects.new("KeyLight", key_data)
key_obj.rotation_euler = (math.radians(-45), math.radians(30), 0)
bpy.context.scene.collection.objects.link(key_obj)

# Fill light
fill_data = bpy.data.lights.new("FillLight", 'SUN')
fill_data.energy = 5.0
fill_data.color = (0.9, 0.85, 1.0)
fill_obj = bpy.data.objects.new("FillLight", fill_data)
fill_obj.rotation_euler = (math.radians(20), math.radians(-120), 0)
bpy.context.scene.collection.objects.link(fill_obj)

# Rim light
rim_data = bpy.data.lights.new("RimLight", 'SUN')
rim_data.energy = 5.0
rim_data.color = (1.0, 0.9, 1.0)
rim_obj = bpy.data.objects.new("RimLight", rim_data)
rim_obj.rotation_euler = (math.radians(-10), math.radians(180), 0)
bpy.context.scene.collection.objects.link(rim_obj)

# --- Render settings ---
scene = bpy.context.scene
scene.render.resolution_x = 256
scene.render.resolution_y = 256
scene.render.film_transparent = True
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA'
scene.render.engine = 'BLENDER_EEVEE'

# Remove default objects if present
for name in ('Cube', 'Light', 'Camera'):
    obj = bpy.data.objects.get(name)
    if obj and obj != cam_obj:
        bpy.data.objects.remove(obj, do_unlink=True)

# --- Render from multiple angles ---
angles = [
    ("front", 0, 15),
    ("front_left", -35, 15),
    ("front_right", 35, 15),
    ("side_left", -90, 10),
    ("side_right", 90, 10),
    ("back", 180, 15),
    ("back_left", -145, 15),
    ("back_right", 145, 15),
]

cam_dist = size * 2.0

# Use visual center — shift down since head/horns extend upward
visual_center = mathutils.Vector((center.x, center.y, center.z - dims.z * 0.15))

# Create empty at visual center for camera tracking
empty = bpy.data.objects.new("CamTarget", None)
empty.location = visual_center
bpy.context.scene.collection.objects.link(empty)

# Add track-to constraint
track = cam_obj.constraints.new(type='TRACK_TO')
track.target = empty
track.track_axis = 'TRACK_NEGATIVE_Z'
track.up_axis = 'UP_Y'

for name, angle_y, angle_x in angles:
    rad_y = math.radians(angle_y)
    rad_x = math.radians(angle_x)
    cam_obj.location = (
        visual_center.x + math.sin(rad_y) * math.cos(rad_x) * cam_dist,
        visual_center.y - math.cos(rad_y) * math.cos(rad_x) * cam_dist,
        visual_center.z + math.sin(rad_x) * cam_dist
    )
    # Force update
    bpy.context.view_layer.update()

    # Render
    filepath = os.path.join(OUTPUT_DIR, f"sheep_{name}.png")
    scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {filepath}")

print("All sheep sprites rendered!")
bpy.ops.wm.quit_blender()
