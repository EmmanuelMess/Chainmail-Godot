import math
from dataclasses import dataclass, field


class Vector3:
    x: float
    y: float
    z: float

    def __init__(self, x: float, y: float, z: float):
        self.x = x
        self.y = y
        self.z = z


class Vector3i:
    x: int
    y: int
    z: int

    def __init__(self, x: int, y: int, z: int):
        self.x = x
        self.y = y
        self.z = z

    def __hash__(self):
        return hash("(" + str(self.x) + ", " + str(self.y) + ", " + str(self.z) + ")")


class Deformation:
    index: Vector3i
    deformation: Vector3

    def __init__(self, index: Vector3i, deformation: Vector3):
        self.index = index
        self.deformation = deformation


class Volume:
    """Deformable volume object"""
    data: list
    size: Vector3i
    deformation_range: Vector3  # x, y and z range of deformation
    spacing: Vector3  # the spacing between the voxels

    min_deformation: Vector3 = Vector3(0.04, 0.04, 0.04)  # point at which deformation is ignored
    x: list
    y: list
    z: list

    def __init__(self, data: list, size: Vector3i, deformation_range: Vector3 = Vector3(0.2, 0.2, 0.2), spacing: Vector3 = Vector3(1, 1, 1)):
        """initial (x, y, z) positions of the items of the volume"""
        self.data = data
        self.size = size
        self.deformation_range = deformation_range
        self.spacing = spacing

        check = self.spacing.x > 1 or self.spacing.y > 1 or self.spacing.z > 1
        spacingCorrectionX = self.spacing.x if check else 1
        spacingCorrectionY = self.spacing.y if check else 1
        spacingCorrectionZ = self.spacing.z if check else 1

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

    def deform(self, index: Vector3i, initialDeformation: Vector3):
        """deform positions by deformation vector starting at index"""
        self._deform_position(index, initialDeformation)
        sponsors = [Deformation(index, initialDeformation)]
        sponsor_hist = [hash(index)]

        while len(sponsors) > 0:
            de: Deformation = sponsors.pop(0)
            sponsor = de.index
            deformation = de.deformation

            # keep the sign for negative values
            vecSign = Vector3(math.copysign(1, deformation.x), math.copysign(1, deformation.y), math.copysign(1, deformation.z))
            deformation = Vector3(abs(deformation.x) - self.deformation_range.x, abs(deformation.y) - self.deformation_range.y, abs(deformation.z) - self.deformation_range.z)
            deformation = Vector3(max(0, deformation.x), max(0, deformation.y), max(0, deformation.z))
            if deformation.x < self.min_deformation.x and deformation.y < self.min_deformation.y and deformation.z < self.min_deformation.z:
                continue
            deformation = Vector3(vecSign.x * deformation.x, vecSign.y * deformation.y, vecSign.z * deformation.z)

            # get and deform neighbors
            neighbors = self._get_neighbors(sponsor, sponsor_hist)
            if len(neighbors) > 0:
                self._deform_positions(neighbors, deformation)
                for i in neighbors:
                    sponsors.append(Deformation(i, deformation))
                    sponsor_hist.append(hash(i))

    def get_position(self, index: Vector3i) -> Vector3:
        """return the position of the index"""
        return Vector3(self.x[index.x][index.y][index.z], self.y[index.x][index.y][index.z], self.z[index.x][index.y][index.z])

    def _deform_position(self, index: Vector3i, deformation: Vector3):
        """deform the position of the provided index"""
        self.x[index.x][index.y][index.z] += deformation.x
        self.y[index.x][index.y][index.z] += deformation.y
        self.z[index.x][index.y][index.z] += deformation.z

    def _deform_positions(self, indices: list, deformation: Vector3):
        """deform the positions of the provided indices"""
        for vec in indices:
            self._deform_position(vec, deformation)

    def _get_neighbors(self, index: Vector3i, sponsor_hist: list = []) -> list:
        """return the possible 6 neighbors of the """
        neighbors = []

        if index.x > 0:
            item = Vector3i(index.x - 1, index.y, index.z)
            if hash(item) not in sponsor_hist:
                neighbors.append(item)
        if index.x < self.size.x - 1:
            item = Vector3i(index.x + 1, index.y, index.z)
            if hash(item) not in sponsor_hist:
                neighbors.append(item)

        if index.y > 0:
            item = Vector3i(index.x, index.y - 1, index.z)
            if hash(item) not in sponsor_hist:
                neighbors.append(item)
        if index.y < self.size.y - 1:
            item = Vector3i(index.x, index.y + 1, index.z)
            if hash(item) not in sponsor_hist:
                neighbors.append(item)

        if index.z > 0:
            item = Vector3i(index.x, index.y, index.z - 1)
            if hash(item) not in sponsor_hist:
                neighbors.append(item)
        if index.z < self.size.z - 1:
            item = Vector3i(index.x, index.y, index.z + 1)
            if hash(item) not in sponsor_hist:
                neighbors.append(item)

        return neighbors

    def show(self, scatter=True):
        """show the volume's voxel positions"""
        import numpy as np
        import matplotlib.pyplot as plt

        if scatter:
            # get x, y, z for matplotlib
            fig = plt.figure(figsize=(15, 15))
            ax = fig.add_subplot(111, projection='3d')

            # show the deformed cube
            ax.scatter(self.x, self.y, self.z, c='r', marker='o')
            ax.set_xlabel('X')
            ax.set_ylabel('Y')
            ax.set_zlabel('Z')
            plt.show(block=True)

        else:
            # show the cubes in 3d for a nicer visualization
            from mpl_toolkits.mplot3d.art3d import Poly3DCollection

            def cuboid_data(p: Vector3i, size=(1, 1, 1)):
                cube = np.array([[[0, 1, 0], [0, 0, 0], [1, 0, 0], [1, 1, 0]],
                                 [[0, 0, 0], [0, 0, 1], [1, 0, 1], [1, 0, 0]],
                                 [[1, 0, 1], [1, 0, 0], [1, 1, 0], [1, 1, 1]],
                                 [[0, 0, 1], [0, 0, 0], [0, 1, 0], [0, 1, 1]],
                                 [[0, 1, 0], [0, 1, 1], [1, 1, 1], [1, 1, 0]],
                                 [[0, 1, 1], [0, 0, 1], [1, 0, 1], [1, 1, 1]]], dtype=float)

                for i in range(3):
                    cube[:, :, i] *= size[i]

                return cube + np.array([p.x, p.y, p.z])

            def plot_cube_at(positions: list, colors: list):

                sizes = [(1, 1, 1)] * len(positions)
                g = []
                for p, s in zip(positions, sizes):
                    g.append(cuboid_data(p, size=s))

                return Poly3DCollection(np.concatenate(g), facecolors=colors, edgecolor="k")

            x, y, z = self.x, self.y, self.z
            positions = []
            for i in range(len(self.x)):
                for j in range(len(self.x)):
                    for k in range(len(self.x)):
                        positions.append(self.get_position(Vector3i(i, j, k)))

            flatdata = []
            for sublist in self.data:
                for subsublist in sublist:
                    for item in subsublist:
                        flatdata.append((item.x, item.y, item.z))

            fig = plt.figure()
            ax = fig.gca(projection='3d')
            colors = np.repeat(flatdata, 6, axis=0)
            pc = plot_cube_at(positions, colors)
            ax.add_collection3d(pc)
            max_range = np.max((x, y, z)) * 1.3
            ax.set_xlim([0, max_range])
            ax.set_ylim([0, max_range])
            ax.set_zlim([0, max_range])
            plt.show(block=True)