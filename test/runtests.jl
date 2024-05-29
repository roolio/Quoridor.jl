using Quoridor
using Test

@testset "Quoridor.jl" begin
    @test Quoridor.greet_your_package_name() == "Hello YourPackageName!"
    @test Quoridor.greet_your_package_name() != "Hello world!"# Write your tests here.
end
