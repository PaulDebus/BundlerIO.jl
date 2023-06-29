module BundlerIO

using FileIO
using ImageProjectiveGeometry: Camera
using Meshes
using ColorTypes
using Printf

export Bundle

struct Bundle{T<:AbstractFloat}
    cameras::Array{Camera}
    points::Array{Point{3, T}}
    views::Dict{Tuple{Int64,Int64},Array{T,1}}
    colors::Union{Nothing, Array{Color,1}}
    keypoints::Union{Nothing, Dict{Tuple{Int, Int}, Int}}
end

function load(f::File{format"OUT"}; colors=true, keypoints=true, F=Float64)
    open(f) do s
        skipmagic(s)  # skip over the magic bytes
        load(s, colors=colors, keypoints=keypoints, F=F)
    end
end

function load(ss::Stream{format"OUT"}; colors=true, keypoints=true, F=Float64)
    readparse(file, T=F) = parse.(T, split(readline(file)))
    s = stream(ss)
    n_cams, n_points = readparse(s, Int)

    cams = Array{Camera, 1}(undef, n_cams)
    points = Array{Point{3, F}, 1}(undef, n_points)
    views = Dict{Tuple{Int, Int},Array{F,1}}()
    color_array = nothing
    keypoints_array = nothing
    if colors
        color_array = Array{Color, 1}(undef, n_points)
    end
    if keypoints
        keypoints_dict = Dict{Tuple{Int, Int}, Int}()
    end
        
    for cam_index in 1:n_cams
        f, k1, k2 = readparse(s)
        R = [transpose(readparse(s)) for r in 1:3]
        R = vcat(R...)
        t = -transpose(R) * readparse(s)
        R[3,:] *= -1 # different coordinate systems 
        c = Camera(fx=f, fy=f, k1=k1, k2=k2, P=t, Rc_w=R)
        cams[cam_index] =  c
    end
    @assert length(cams) == n_cams

    for point_index in 1:n_points
        points[point_index] = Point(readparse(s)...)

        c = RGB(readparse(s, Int)./255...)
        if colors
            color_array[point_index] = c
        end

        view_line = split(readline(s))
        num_views = parse(Int, view_line[1])
        for view_id in 1:num_views
            view = view_line[(view_id-1)*4+2:view_id*4+1]
            cam_id = parse(Int, view[1]) + 1 # bundle is zero based
            key = parse(Int, view[2])
            if keypoints
                keypoints_dict[(cam_id, point_index)] = key
            end
            px = parse.(F, view[3:4])
            views[(cam_id, point_index)] = px
        end
    end
    return Bundle(cams, points, views, color_array, keypoints_dict)
end

function save(f::File{format"OUT"}, bundle::Bundle)
    j(x) = join(x, " ")
    open(f, "w") do s
        write(s, magic(format"OUT"))
        write(s, "$(size(bundle.cameras, 1)) $(size(bundle.points, 1))\n")
        for cam in bundle.cameras
            write(s, "$(cam.fx) $(cam.k1) $(cam.k2)\n")
            R = cam.Rc_w
            R[3,:] *= -1 # still different coordinate systems
            write(s, j(R[1,:]) * "\n")
            write(s, j(R[2,:]) * "\n")
            write(s, j(R[3,:]) * "\n")
            t = -cam.P' * R'
            write(s, j(t) * "\n")
        end

        for point_index in 1:length(bundle.points)
            p = bundle.points[point_index]
            write(s, j(p.coords)*"\n")
            if !isnothing(bundle.colors)
                c = bundle.colors[point_index]
                r = Int(round(red(c)*255))
                g = Int(round(green(c)*255))
                b = Int(round(blue(c)*255))
                write(s, "$r $g $b\n")
            else
                write(s, "0 0 0\n")
            end
            views = filter(v -> v[2] == point_index, keys(bundle.views))
            write(s, "$(length(views)) ")
            for v in views
                px = bundle.views[v]
                if isnothing(bundle.keypoints)
                    key = -1
                else
                    key = bundle.keypoints[v]
                end
                # subtract 1 from the view id, as Bundler is zero based
                write(s, "$(v[1]-1) $key $(px[1]) $(px[2]) ")
            end
            write(s, "\n")
        end
    end
end
end

