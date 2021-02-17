using FileIO
using Test
using BundlerIO

@testset "BundlerIO" begin
    # download an example file
    url = "https://raw.githubusercontent.com/snavely/bundler_sfm/master/examples/kermit/results.example/bundle.out"
    filepath = tempdir()*"/bundle.out"
    download(url, filepath)

    bundle = load(filepath)
    @test length(bundle.cameras) == 11
    @test length(bundle.points) == 634
    @test length(bundle.views) == 2039
    @test bundle.views[(4,452)] == [-40.93, -5.87]
    save(filepath, bundle)
    rm(filepath)
end