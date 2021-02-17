# BundlerIO

This Julia package loads and saves [Bundler files](https://www.cs.cornell.edu/~snavely/bundler/bundler-v0.4-manual.html), used in the context of Photogrammetry and Struture from Motion.

## Installation
The package is available in the Julia package repository and can be installed in the Julia REPL package mode:

```julia
pkg> add FileIO BundlerIO
```

The dependencies are installed automatically. The package depends on [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) for the geometry representation, [ImageProjectiveGeometry.jl](https://github.com/peterkovesi/ImageProjectiveGeometry.jl) for the representation of the cameras. 

## Usage
The loading and writing is done via the [FileIO.jl](https://github.com/JuliaIO/FileIO.jl) interface:

```julia
using FileIO
bundle = load("bundle.out")
save("new_bundle.out", bundle)
```

The loaded data is in a `Bundle` struct, that contains the points, cameras, views, and optionally colors and keypoints. The cameras are an array of `Camera` objects from [ImageProjectiveGeometry.jl](https://github.com/peterkovesi/ImageProjectiveGeometry.jl), the 3D points are an array of `Point3` objects from  [Meshes.jl](https://github.com/JuliaGeometry/Meshes.jl) and the views are a `Dictionary` with a tuple of `(camera_id, point_id)` as keys and the pixel coordinates of the projection of that point into the image of that camera as value. The colors are an array of `Color` objects from [ColorTypes.jl](https://github.com/JuliaGraphics/ColorTypes.jl). The keypoints are in a similar dict to the views, where the values are the ID of the SIFT keypoints that have been computed during SfM. This data is not always present and only kept for completeness.