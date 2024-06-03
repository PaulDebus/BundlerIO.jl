using FileIO
using Test
using BundlerIO
using Downloads
using ImageProjectiveGeometry

@testset "BundlerIO" begin
    # download an example file
    url = "https://raw.githubusercontent.com/snavely/bundler_sfm/master/examples/kermit/results.example/bundle.out"
    filepath = tempdir()*"/bundle.out"
    Downloads.download(url, filepath)

    bundle = load(filepath)
    @test length(bundle.cameras) == 11
    @test size(bundle.points, 2) == 634
    @test length(bundle.views) == 2039
    @test bundle.views[(4,452)] == [-40.93, -5.87]
    # test the projections. the errors are surprisingly large...
    for (cam_id, point_id) in keys(bundle.views)
	p = bundle.points[:, point_id]
	cam = bundle.cameras[cam_id]
	@test isapprox(cameraproject(cam, p), bundle.views[(cam_id, point_id)], atol=8.) # figure out if we can reduce the tolerance
    end
    save(filepath, bundle)
    rm(filepath)
end
