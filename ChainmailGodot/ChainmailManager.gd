extends Spatial

const HOR_DIST = 0.8
const VER_DIST = 0.85

var points = []
var sticks = []
var bounce = 0.9
var gravity = -0.02
var friction = 0.999

class Point:
	var isStatic: bool
	var center: bool
	var mesh: MeshInstance
	var currentPos: Vector3
	var oldPos: Vector3
	func _init(isStatic: bool, center: bool, currentPos: Vector3, oldPos: Vector3):
		self.isStatic = isStatic
		self.center = center
		self.currentPos = currentPos
		self.oldPos = oldPos

class Stick:
	var p0: Point
	var p1: Point
	var length: float
	
	func _init(p0: Point, p1: Point):
		self.p0 = p0
		self.p1 = p1
		self.length = (p0.currentPos - p1.currentPos).length()
		
var rng = RandomNumberGenerator.new()

# Called when the node enters the scene tree for the first time.
func _ready():
	rng.randomize()
	
	generate_lattice(20, 20)

	for chainLink in points:
		if chainLink.center:
			var mesh := MeshInstance.new()
			mesh.mesh = load("res://torus.obj") 
			mesh.translate(chainLink.currentPos)
			add_child(mesh)
			chainLink.mesh = mesh

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	for i in range(len(points)):
		if points[i].center:
			points[i].currentPos = points[i].mesh.transform.origin
	
	updatePoints()
	for i in range(10):
		updateSticks()
	
	for i in range(len(points)):
		if points[i].center:
			points[i].mesh.transform.origin = points[i].currentPos

func updatePoints():
	for i in range(len(points)):
		var p = points[i]
		var v: Vector3 = (p.currentPos - p.oldPos) * friction
		if(p.isStatic):
			continue
	
		p.oldPos = p.currentPos
		p.currentPos += v
		p.currentPos.y += gravity

func updateSticks():
	for i in range(len(sticks)):
		var s = sticks[i]
		var d = s.p1.currentPos - s.p0.currentPos
		var distance = sqrt(d.x * d.x + d.y * d.y) + 0.0001
		var difference = min(s.length - distance, 0)
		var percent = difference / distance / 2
		var offsetX = d.x * percent
		var offsetY = d.y * percent
		
		if(!s.p0.isStatic && !s.p1.isStatic):
		  s.p0.currentPos.x -= offsetX
		  s.p0.currentPos.y -= offsetY
		  s.p1.currentPos.x += offsetX
		  s.p1.currentPos.y += offsetY
		elif(s.p0.isStatic):
		  s.p1.currentPos.x += 2 * offsetX
		  s.p1.currentPos.y += 2 * offsetY
		elif(s.p1.isStatic):
		  s.p0.currentPos.x -= 2 * offsetX
		  s.p0.currentPos.y -= 2 * offsetY
		
		
func generate_lattice(width, height):
	var prevTop = []

	for i in range(width):
		var pos = self.translation + Vector3(HOR_DIST*i, 0, 0)
		var point = Point.new(false, false, pos, pos)
	  
		prevTop.append(point)
		points.append(point)

	for j in range(height):
		var topPoints = prevTop
		var bottomPoints = []
		for i in range(width):
			var pos = self.translation + Vector3(HOR_DIST*i, (1 + j) * VER_DIST, 0)
			var point = Point.new(i == 0 || i == width - 1, false, pos, pos)
			bottomPoints.append(point)
			points.append(point)
		
		for i in range(width - 1):
			var pos = self.translation + Vector3(HOR_DIST*i + HOR_DIST/2, j * VER_DIST + VER_DIST/2, 0)
			var middlePoint = Point.new(false, true, pos, pos)
		
			points.append(middlePoint)
		  
			sticks.append(Stick.new(topPoints[i], middlePoint))
			sticks.append(Stick.new(topPoints[i+1], middlePoint))
			sticks.append(Stick.new(bottomPoints[i], middlePoint))
			sticks.append(Stick.new(bottomPoints[i+1], middlePoint))
		
		prevTop = bottomPoints
		
	for point in prevTop:
		point.isStatic = true
	
