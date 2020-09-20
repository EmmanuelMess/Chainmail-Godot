import random

from volume import Volume, Vector3, Vector3i


def deform_volume():
    size = Vector3i(9, 9, 9)
    volume = Volume(gen_data(size), size, Vector3(0.6, 0.6, 0.6), Vector3(0.2, 0.2, 0.2))
    deformation = Vector3(1, 1, 3)
    deformation_index = Vector3i(7, 7, 8)
    volume.deform(deformation_index, deformation)
    volume.show()
    volume.show(scatter=False)


def gen_data(size: Vector3i) -> list:
    data = []
    for x in range(size.x):
        data.append([])
        for y in range(size.y):
            data[x].append([])
            for z in range(size.z):
                data[x][y].append(Vector3(x=random.uniform(0, 1), y=random.uniform(0, 1), z=random.uniform(0, 1)))
    return data


if __name__ == '__main__':
    deform_volume()