extends Spatial

onready var vol = preload("Volume.gd")
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	var size = vol.Vector3i.new(9, 9, 9)
	var volume = vol.Volume.new(gen_data(size), size, Vector3(0.6, 0.6, 0.6), Vector3(0.2, 0.2, 0.2))
	var deformation = Vector3(1, 1, 3)
	var deformation_index = vol.Vector3i.new(7, 7, 8)
	volume.deform(deformation_index, deformation)
	
	var positions = []
	for i in range(size.x):
		for j in range(size.y):
			for k in range(size.z):
				positions.append(volume.get_position(vol.Vector3i.new(i, j, k)))

	for chainLink in positions:
		var mesh := MeshInstance.new()
		mesh.mesh = CubeMesh.new()
		mesh.mesh.size = Vector3(1, 1, 1)
		mesh.translate(chainLink)
		add_child(mesh)

func gen_data(size) -> Array:
	var data = []
	for x in range(size.x):
		data.append([])
		for y in range(size.y):
			data[x].append([])
			for z in range(size.z):
				data[x][y].append(Vector3(rng.randf_range(0, 1), rng.randf_range(0, 1), rng.randf_range(0, 1)))
	return data

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

