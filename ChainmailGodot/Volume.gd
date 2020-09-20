class Vector3i:
	var x: int
	var y: int
	var z: int
	
	func _init(x: int, y: int, z: int):
		self.x = x
		self.y = y
		self.z = z

	func _hash():
		return hash("(" + str(self.x) + ", " + str(self.y) + ", " + str(self.z) + ")")


class Deformation:
	var index: Vector3i
	var deformation: Vector3
	
	func _init(index: Vector3i, deformation: Vector3):
		self.index = index
		self.deformation = deformation

class Volume:
	"""Deformable volume object"""
	var data: Array
	var size: Vector3i
	var deformation_range: Vector3 = Vector3(0.2, 0.2, 0.2)  # x, y and z range of deformation
	var min_deformation: Vector3 = Vector3(0.04, 0.04, 0.04)  # point at which deformation is ignored
	var spacing: Vector3 = Vector3(1, 1, 1)  # the spacing between the voxels
	var x: Array
	var y: Array
	var z: Array

	func _init(data: Array, size: Vector3i, deformation_range: Vector3, spaceing: Vector3):
		"""initial (x, y, z) positions of the items of the volume"""
		self.data = data
		self.size = size
		self.deformation_range = deformation_range
		self.spacing = spaceing
		
		var check = self.spacing.x > 1 or self.spacing.y > 1 or self.spacing.z > 1
		var spacingCorrectionX = self.spacing.x if check else 1.0
		var spacingCorrectionY = self.spacing.y if check else 1.0
		var spacingCorrectionZ = self.spacing.z if check else 1.0

		self.x = []
		for x in range(self.size.z):
			self.x.append([])
			for y in range(self.size.y):
				self.x[x].append([])
				for z in range(self.size.x):
					self.x[x][y].append(x * spacingCorrectionX)

		self.y = []
		for x in range(self.size.z):
			self.y.append([])
			for y in range(self.size.y):
				self.y[x].append([])
				for z in range(self.size.x):
					self.y[x][y].append(y * spacingCorrectionY)

		self.z = []
		for x in range(self.size.z):
			self.z.append([])
			for y in range(self.size.y):
				self.z[x].append([])
				for z in range(self.size.x):
					self.z[x][y].append(z * spacingCorrectionZ)

	func deform(index: Vector3i, initialDeformation: Vector3):
		"""deform positions by deformation vector starting at index"""
		self._deform_position(index, initialDeformation)
		var sponsors = [Deformation.new(index, initialDeformation)]
		var sponsor_hist = [index._hash()]

		while len(sponsors) > 0:
			var de: Deformation = sponsors.pop_front()
			var sponsor = de.index
			var deformation = de.deformation

			# keep the sign for negative values
			var vecSign = Vector3(sign(deformation.x), sign(deformation.y), sign(deformation.z))
			deformation = Vector3(abs(deformation.x) - self.deformation_range.x, abs(deformation.y) - self.deformation_range.y, abs(deformation.z) - self.deformation_range.z)
			deformation = Vector3(max(0, deformation.x), max(0, deformation.y), max(0, deformation.z))
			if deformation.x < self.min_deformation.x and deformation.y < self.min_deformation.y and deformation.z < self.min_deformation.z:
				continue
			deformation = Vector3(vecSign.x * deformation.x, vecSign.y * deformation.y, vecSign.z * deformation.z)

			# get and deform neighbors
			var neighbors = self._get_neighbors(sponsor, sponsor_hist)
			if len(neighbors) > 0:
				self._deform_positions(neighbors, deformation)
				for i in neighbors:
					sponsors.append(Deformation.new(i, deformation))
					sponsor_hist.append(i._hash())

	func get_position(index: Vector3i) -> Vector3:
		"""return the position of the index"""
		return Vector3(self.x[index.x][index.y][index.z], self.y[index.x][index.y][index.z], self.z[index.x][index.y][index.z])

	func _deform_position(index: Vector3i, deformation: Vector3):
		"""deform the position of the provided index"""
		self.x[index.x][index.y][index.z] += deformation.x
		self.y[index.x][index.y][index.z] += deformation.y
		self.z[index.x][index.y][index.z] += deformation.z

	func _deform_positions(indices: Array, deformation: Vector3):
		"""deform the positions of the provided indices"""
		for vec in indices:
			self._deform_position(vec, deformation)

	func _get_neighbors(index: Vector3i, sponsor_hist: Array = []) -> Array:
		"""return the possible 6 neighbors of the """
		var neighbors = []

		if index.x > 0:
			var item = Vector3i.new(index.x - 1, index.y, index.z)
			if not item._hash() in sponsor_hist:
				neighbors.append(item)
		if index.x < self.size.x - 1:
			var item = Vector3i.new(index.x + 1, index.y, index.z)
			if not item._hash() in sponsor_hist:
				neighbors.append(item)

		if index.y > 0:
			var item = Vector3i.new(index.x, index.y - 1, index.z)
			if not item._hash() in sponsor_hist:
				neighbors.append(item)
		if index.y < self.size.y - 1:
			var item = Vector3i.new(index.x, index.y + 1, index.z)
			if not item._hash() in sponsor_hist:
				neighbors.append(item)

		if index.z > 0:
			var item = Vector3i.new(index.x, index.y, index.z - 1)
			if not item._hash() in sponsor_hist:
				neighbors.append(item)
		if index.z < self.size.z - 1:
			var item = Vector3i.new(index.x, index.y, index.z + 1)
			if not item._hash() in sponsor_hist:
				neighbors.append(item)

		return neighbors
