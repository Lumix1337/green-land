"""
Procedural Blender 4.x Builder for the GreenLand Smart Greenhouse 3D Digital Twin.

Builds Erlan's 800 m2 commercial tomato greenhouse (stylized low-poly) with
named interactive actuator parts for Three.js animation, then exports:
  - simulator/viewer_3d/assets/greenhouse.glb
  - simulator/viewer_3d/assets/greenhouse.blend
  - simulator/viewer_3d/assets/preview.png (quick EEVEE preview render)

Run via Blender CLI:
  blender --background --python simulator/blender/build_greenhouse.py
"""

import math
import os
import random
import bpy
from mathutils import Vector

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.normpath(
    os.path.join(SCRIPT_DIR, "..", "viewer_3d", "assets")
)
os.makedirs(ASSETS_DIR, exist_ok=True)

GLB_PATH = os.path.join(ASSETS_DIR, "greenhouse.glb")
BLEND_PATH = os.path.join(ASSETS_DIR, "greenhouse.blend")
PREVIEW_PATH = os.path.join(ASSETS_DIR, "preview.png")

# Clear default objects without resetting addons
for obj in list(bpy.data.objects):
    bpy.data.objects.remove(obj, do_unlink=True)
for mesh in list(bpy.data.meshes):
    bpy.data.meshes.remove(mesh)
for mat in list(bpy.data.materials):
    bpy.data.materials.remove(mat)

random.seed(42)


def make_mat(
    name,
    base_color,
    roughness=0.5,
    metallic=0.0,
    alpha=1.0,
    emission=None,
    emission_strength=0.0,
):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*base_color, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if alpha < 1.0:
        bsdf.inputs["Alpha"].default_value = alpha
        if hasattr(mat, "blend_method"):
            mat.blend_method = "BLEND"
    if emission is not None and "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat


# --- GreenLand Material Palette ---
mat_grass = make_mat("Mat_Grass", (0.18, 0.34, 0.14), roughness=0.92)
mat_concrete = make_mat("Mat_Concrete", (0.60, 0.62, 0.60), roughness=0.85)
mat_walkway = make_mat("Mat_Walkway", (0.72, 0.74, 0.71), roughness=0.80)
mat_wood = make_mat("Mat_PlanterWood", (0.28, 0.18, 0.10), roughness=0.85)
mat_soil = make_mat("Mat_Soil", (0.22, 0.14, 0.09), roughness=0.95)
mat_frame = make_mat("Mat_FrameMetal", (0.10, 0.27, 0.14), roughness=0.35, metallic=0.72)
mat_alu = make_mat("Mat_Aluminum", (0.74, 0.77, 0.79), roughness=0.28, metallic=0.85)
mat_glass = make_mat("Mat_Glass", (0.76, 0.92, 0.86), roughness=0.08, metallic=0.05, alpha=0.20)
mat_vent_glass = make_mat("Mat_VentGlass", (0.68, 0.88, 0.94), roughness=0.08, metallic=0.05, alpha=0.32)
mat_leaf = make_mat("Mat_TomatoLeaf", (0.11, 0.42, 0.13), roughness=0.65)
mat_tomato = make_mat("Mat_TomatoFruit", (0.86, 0.10, 0.08), roughness=0.25)
mat_stake = make_mat("Mat_Stake", (0.48, 0.35, 0.20), roughness=0.88)
mat_pipe = make_mat("Mat_DripPipe", (0.07, 0.08, 0.09), roughness=0.45, metallic=0.15)
mat_tank = make_mat("Mat_WaterTank", (0.09, 0.42, 0.66), roughness=0.32, metallic=0.10)
mat_grow_emitter = make_mat(
    "Mat_GrowLight_Emitter",
    (0.85, 0.60, 0.95),
    roughness=0.2,
    emission=(0.75, 0.18, 0.95),
    emission_strength=0.35,
)
mat_heater_body = make_mat("Mat_HeaterBody", (0.20, 0.22, 0.24), roughness=0.4, metallic=0.65)
mat_heater_coil = make_mat(
    "Mat_HeaterCoil",
    (0.32, 0.14, 0.10),
    roughness=0.35,
    metallic=0.5,
    emission=(1.0, 0.28, 0.04),
    emission_strength=0.15,
)
mat_fan_blade = make_mat("Mat_FanBlade", (0.84, 0.87, 0.88), roughness=0.28, metallic=0.65)
mat_sensor = make_mat("Mat_SensorWhite", (0.94, 0.96, 0.94), roughness=0.30)
mat_solar = make_mat("Mat_SolarPanel", (0.05, 0.10, 0.26), roughness=0.18, metallic=0.6)


def add_box(name, size, loc, rot=(0, 0, 0), mat=None):
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
    obj = bpy.context.active_object
    obj.name = name
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if mat:
        obj.data.materials.append(mat)
    return obj


def add_cyl(name, radius, depth, loc, rot=(0, 0, 0), mat=None, verts=12):
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=verts, radius=radius, depth=depth, location=loc, rotation=rot
    )
    obj = bpy.context.active_object
    obj.name = name
    if mat:
        obj.data.materials.append(mat)
    return obj


def join_group(objs, name, mat):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    bpy.ops.object.join()
    res = bpy.context.active_object
    res.name = name
    res.data.materials.clear()
    res.data.materials.append(mat)
    return res


# --- 1. Ground, Foundation & Central Walkway ---
add_box("Ground_Outside", (26.0, 28.0, 0.20), (0, 0, -0.18), mat=mat_grass)
add_box("Foundation_Slab", (9.6, 14.6, 0.16), (0, 0, -0.02), mat=mat_concrete)
add_box("Walkway", (1.7, 14.2, 0.05), (0, 0, 0.07), mat=mat_walkway)

# --- 2. Four Raised Soil Beds & Drip Irrigation Pipes ---
bed_configs = [
    ("1", -2.65, -3.3),
    ("2", -2.65, 3.3),
    ("3", 2.65, -3.3),
    ("4", 2.65, 3.3),
]
for idx, bx, by in bed_configs:
    add_box(f"PlanterBox_{idx}", (2.4, 5.6, 0.38), (bx, by, 0.25), mat=mat_wood)
    add_box(f"SoilBed_{idx}", (2.22, 5.42, 0.12), (bx, by, 0.41), mat=mat_soil)
    add_cyl(
        f"DripPipe_{idx}",
        0.035,
        5.3,
        (bx, by, 0.50),
        rot=(math.pi / 2, 0, 0),
        mat=mat_pipe,
        verts=8,
    )
    for dx in (-0.55, 0.55):
        add_cyl(
            f"DripLine_{idx}_{'L' if dx < 0 else 'R'}",
            0.018,
            5.2,
            (bx + dx, by, 0.48),
            rot=(math.pi / 2, 0, 0),
            mat=mat_pipe,
            verts=6,
        )

# External Water Storage Tank + Supply Pipe
add_cyl("WaterTank_Body", 0.95, 2.2, (-5.8, 5.2, 1.12), mat=mat_tank, verts=20)
add_cyl("WaterTank_Cap", 0.28, 0.15, (-5.8, 5.2, 2.28), mat=mat_pipe, verts=12)
add_cyl(
    "WaterTank_SupplyPipe",
    0.055,
    1.8,
    (-4.9, 5.2, 0.48),
    rot=(0, math.pi / 2, 0),
    mat=mat_pipe,
    verts=8,
)

# --- 3. Stylized Tomato Plants ---
stake_objs, leaf_objs, fruit_objs = [], [], []
for idx, bx, by in bed_configs:
    for row_x in (bx - 0.55, bx + 0.55):
        for p in range(5):
            py = by - 2.1 + p * 1.05
            px = row_x + random.uniform(-0.05, 0.05)
            h = random.uniform(1.15, 1.45)

            bpy.ops.mesh.primitive_cylinder_add(
                vertices=6, radius=0.02, depth=h + 0.15, location=(px, py, 0.46 + h / 2)
            )
            stake_objs.append(bpy.context.active_object)

            for k in range(3):
                fz = 0.74 + k * 0.34 + random.uniform(-0.03, 0.03)
                r = 0.24 - k * 0.03 + random.uniform(-0.02, 0.02)
                bpy.ops.mesh.primitive_ico_sphere_add(
                    subdivisions=1,
                    radius=r,
                    location=(
                        px + random.uniform(-0.06, 0.06),
                        py + random.uniform(-0.06, 0.06),
                        fz,
                    ),
                )
                leaf_objs.append(bpy.context.active_object)

            for t in range(3):
                ang = random.uniform(0, math.tau)
                tz = 0.76 + t * 0.28
                tr = 0.20
                bpy.ops.mesh.primitive_ico_sphere_add(
                    subdivisions=1,
                    radius=0.055,
                    location=(px + math.cos(ang) * tr, py + math.sin(ang) * tr, tz),
                )
                fruit_objs.append(bpy.context.active_object)

join_group(stake_objs, "Tomato_Stakes", mat_stake)
join_group(leaf_objs, "Tomato_Foliage", mat_leaf)
join_group(fruit_objs, "Tomato_Fruits", mat_tomato)

# --- 4. Greenhouse Structural Steel Frame ---
W = 4.5       # Half-width (total 9.0m)
L = 7.0       # Half-length (total 14.0m)
H_WALL = 3.0  # Eave height
H_RIDGE = 4.6 # Ridge height
ROOF_DX = W
ROOF_DZ = H_RIDGE - H_WALL
ROOF_LEN = math.hypot(ROOF_DX, ROOF_DZ)
ROOF_ANGLE = math.atan2(ROOF_DZ, ROOF_DX)  # ~19.57 deg

frame_objs = []
bay_ys = [-7.0, -4.66, -2.33, 0.0, 2.33, 4.66, 7.0]

for y in bay_ys:
    # Left & right vertical columns
    frame_objs.append(add_box("Col_L", (0.12, 0.12, H_WALL), (-W, y, H_WALL / 2 + 0.06)))
    frame_objs.append(add_box("Col_R", (0.12, 0.12, H_WALL), (W, y, H_WALL / 2 + 0.06)))
    # Roof rafters
    frame_objs.append(
        add_box(
            "Rafter_L",
            (ROOF_LEN, 0.10, 0.10),
            (-W / 2, y, H_WALL + ROOF_DZ / 2 + 0.06),
            rot=(0, -ROOF_ANGLE, 0),
        )
    )
    frame_objs.append(
        add_box(
            "Rafter_R",
            (ROOF_LEN, 0.10, 0.10),
            (W / 2, y, H_WALL + ROOF_DZ / 2 + 0.06),
            rot=(0, ROOF_ANGLE, 0),
        )
    )
    # Horizontal tie beam
    frame_objs.append(add_box("TieBeam", (W * 2, 0.08, 0.08), (0, y, H_WALL + 0.04)))

# Longitudinal beams: base rails, eave beams, ridge beam
for sx in (-W, W):
    frame_objs.append(add_box("BaseRail", (0.12, L * 2, 0.12), (sx, 0, 0.12)))
    frame_objs.append(add_box("EaveBeam", (0.12, L * 2, 0.12), (sx, 0, H_WALL + 0.06)))
frame_objs.append(add_box("RidgeBeam", (0.14, L * 2 + 0.1, 0.14), (0, 0, H_RIDGE + 0.06)))

# Front door frame (y = -L)
frame_objs.append(add_box("DoorPost_L", (0.10, 0.10, 2.3), (-0.95, -L, 1.21)))
frame_objs.append(add_box("DoorPost_R", (0.10, 0.10, 2.3), (0.95, -L, 1.21)))
frame_objs.append(add_box("DoorHeader", (2.0, 0.10, 0.10), (0, -L, 2.36)))

join_group(frame_objs, "Greenhouse_Frame", mat_frame)

# --- 5. Translucent Glass Walls & Roof ---
glass_objs = []
# Side walls
glass_objs.append(add_box("Glass_Wall_L", (0.04, L * 2 - 0.1, H_WALL - 0.12), (-W, 0, H_WALL / 2 + 0.06)))
glass_objs.append(add_box("Glass_Wall_R", (0.04, L * 2 - 0.1, H_WALL - 0.12), (W, 0, H_WALL / 2 + 0.06)))
# Back wall
glass_objs.append(add_box("Glass_Wall_Back", (W * 2 - 0.1, 0.04, H_WALL - 0.12), (0, L, H_WALL / 2 + 0.06)))
# Front wall panels beside doorway
glass_objs.append(add_box("Glass_Front_L", (W - 1.0, 0.04, H_WALL - 0.12), (-(W + 0.95) / 2, -L, H_WALL / 2 + 0.06)))
glass_objs.append(add_box("Glass_Front_R", (W - 1.0, 0.04, H_WALL - 0.12), ((W + 0.95) / 2, -L, H_WALL / 2 + 0.06)))
glass_objs.append(add_box("Glass_Front_Top", (1.9, 0.04, H_WALL - 2.38), (0, -L, 2.36 + (H_WALL - 2.38) / 2)))
# Lower roof glass slopes (leaving top strip near ridge for operable VentWindows)
lower_len = ROOF_LEN * 0.68
mid_frac = 0.34  # center of lower roof section from eave
glass_objs.append(
    add_box(
        "Glass_Roof_L",
        (lower_len, L * 2 - 0.1, 0.04),
        (-W + ROOF_DX * mid_frac, 0, H_WALL + ROOF_DZ * mid_frac + 0.10),
        rot=(0, -ROOF_ANGLE, 0),
    )
)
glass_objs.append(
    add_box(
        "Glass_Roof_R",
        (lower_len, L * 2 - 0.1, 0.04),
        (W - ROOF_DX * mid_frac, 0, H_WALL + ROOF_DZ * mid_frac + 0.10),
        rot=(0, ROOF_ANGLE, 0),
    )
)
join_group(glass_objs, "Greenhouse_Glass", mat_glass)

# --- 6. INTERACTIVE ACTUATOR 1: Hinged Roof Ventilation Windows ---
# Pivot placed exactly at the ridge edge so rotating around local Y opens them!
vent_width = ROOF_LEN * 0.30
vent_length = 4.2


def create_vent_window(name, side, center_y):
    """side = -1 for left roof slope, +1 for right roof slope."""
    # Create frame + glass panel around local origin (hinge at x=0, z=0)
    hinge_x = side * 0.08
    hinge_z = H_RIDGE + 0.09
    bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
    panel = bpy.context.active_object
    panel.name = name
    # Shift vertices so hinge is at local X=0
    for v in panel.data.vertices:
        v.co.x = (v.co.x + 0.5) * vent_width * side
        v.co.y = v.co.y * vent_length
        v.co.z = v.co.z * 0.06
    panel.data.update()
    panel.location = (hinge_x, center_y, hinge_z)
    panel.rotation_euler = (0, side * ROOF_ANGLE, 0)
    panel.data.materials.append(mat_vent_glass)
    return panel


create_vent_window("VentWindow_Left_1", -1, -3.5)
create_vent_window("VentWindow_Left_2", -1, 3.5)
create_vent_window("VentWindow_Right_1", 1, -3.5)
create_vent_window("VentWindow_Right_2", 1, 3.5)

# --- 7. INTERACTIVE ACTUATOR 2: Back-Wall Exhaust Fans ---
for idx, fx in (("1", -2.2), ("2", 2.2)):
    fz = 2.25
    fy = L + 0.06
    # Square aluminum housing
    add_box(f"ExhaustFan_Housing_{idx}", (0.95, 0.18, 0.95), (fx, fy, fz), mat=mat_alu)
    # Spinning fan blades group with origin at (fx, fy + 0.05, fz)
    blade_parts = []
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=12, radius=0.10, depth=0.14, location=(0, 0, 0), rotation=(math.pi / 2, 0, 0)
    )
    blade_parts.append(bpy.context.active_object)
    for b in range(4):
        ang = b * (math.pi / 2)
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0))
        bl = bpy.context.active_object
        bl.scale = (0.36, 0.03, 0.12)
        bpy.ops.object.transform_apply(scale=True)
        # Offset radially and rotate around Y
        for v in bl.data.vertices:
            x0 = v.co.x + 0.22
            z0 = v.co.z
            v.co.x = x0 * math.cos(ang) - z0 * math.sin(ang)
            v.co.z = x0 * math.sin(ang) + z0 * math.cos(ang)
        bl.data.update()
        blade_parts.append(bl)
    fan_blades = join_group(blade_parts, f"ExhaustFan_Blades_{idx}", mat_fan_blade)
    fan_blades.location = (fx, fy + 0.04, fz)

# --- 8. INTERACTIVE ACTUATOR 3: Suspended LED Phytolighting Bars ---
for idx, bx, by in bed_configs:
    # Aluminum housing
    add_box(f"GrowLight_Fixture_{idx}", (0.38, 4.8, 0.08), (bx, by, 2.70), mat=mat_alu)
    # Suspension rods
    for dy in (-2.0, 2.0):
        add_cyl(f"GrowLight_Rod_{idx}_{dy}", 0.015, 0.45, (bx, by + dy, 2.94), mat=mat_alu, verts=6)
    # Emissive LED strip (animated in Three.js)
    add_box(f"GrowLight_Emitter_{idx}", (0.28, 4.65, 0.04), (bx, by, 2.64), mat=mat_grow_emitter)

# --- 9. INTERACTIVE ACTUATOR 4: Thermal Fan Heaters ---
for idx, hy in (("1", -5.8), ("2", 5.8)):
    hx = 0.0
    hz = 2.62
    add_box(f"Heater_Unit_{idx}", (0.90, 0.45, 0.52), (hx, hy, hz), mat=mat_heater_body)
    # Glowing heating coil face (faces inward toward center of greenhouse)
    coil_y = hy + (0.24 if hy < 0 else -0.24)
    add_box(f"Heater_Coil_{idx}", (0.72, 0.05, 0.34), (hx, coil_y, hz), mat=mat_heater_coil)

# --- 10. Central Smart Microclimate Sensor Station ---
add_cyl("Sensor_Pole", 0.035, 1.85, (0.0, 0.0, 1.0), mat=mat_alu, verts=10)
add_box("Sensor_Station", (0.26, 0.20, 0.34), (0.0, 0.0, 1.88), mat=mat_sensor)
add_box("Sensor_SolarPanel", (0.34, 0.24, 0.03), (0.0, 0.0, 2.12), rot=(0.35, 0, 0), mat=mat_solar)

# --- 11. Save .blend & Export .glb ---
bpy.ops.wm.save_as_mainfile(filepath=BLEND_PATH)
bpy.ops.export_scene.gltf(
    filepath=GLB_PATH,
    export_format="GLB",
    export_apply=False,
    export_materials="EXPORT",
    export_lights=False,
    export_cameras=False,
)

# --- 12. Quick Preview Render (for visual QA) ---
scene = bpy.context.scene
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items else "BLENDER_EEVEE"
scene.render.resolution_x = 960
scene.render.resolution_y = 600
scene.render.filepath = PREVIEW_PATH

# World sky
world = bpy.data.worlds.new("GreenLandWorld")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs[0].default_value = (0.76, 0.88, 0.96, 1.0)
    bg.inputs[1].default_value = 0.85

# Sun light
bpy.ops.object.light_add(type="SUN", location=(10, -10, 14))
sun = bpy.context.active_object
sun.data.energy = 3.2
sun.rotation_euler = (math.radians(48), math.radians(15), math.radians(38))

# Camera 3/4 view
bpy.ops.object.camera_add(location=(11.5, -13.5, 7.2))
cam = bpy.context.active_object
direction = Vector((0.0, 0.0, 1.6)) - cam.location
cam.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
scene.camera = cam

bpy.ops.render.render(write_still=True)

glb_kb = os.path.getsize(GLB_PATH) / 1024.0
print(f"SUCCESS: Exported {GLB_PATH} ({glb_kb:.1f} KB), {BLEND_PATH}, and {PREVIEW_PATH}")
