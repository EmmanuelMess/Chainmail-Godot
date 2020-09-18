extends Spatial



# Called when the node enters the scene tree for the first time.
func _ready():
	var chainList = [Vector3(1, 1, 1), Vector3(1, -1, 1)]
	
	for chainLink in chainList:
		var mesh = MeshInstance.new()
		mesh.mesh = CubeMesh.new()
		mesh.translate(chainLink)
		add_child(mesh)



# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
