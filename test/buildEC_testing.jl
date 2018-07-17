using PowerSystems
using JuMP

include(string(homedir(),"/.julia/v0.6/PowerSystems/data/data_5bus.jl"))

battery = [GenericBattery(name = "Bat",
                status = true,
                energy = 10.0,
                realpower = 10.0,
                capacity = @NT(min = 0.0, max = 10.0,),
                inputrealpowerlimit = 10.0,
                outputrealpowerlimit = 10.0,
                efficiency = @NT(in = 0.90, out = 0.80),
                )];

generators_hg = [
    HydroFix("HydroFix",true,nodes5[2],
        TechHydro(60.0, 15.0, @NT(min = 0.0, max = 60.0), nothing, nothing, nothing, nothing),
        TimeSeries.TimeArray(DayAhead,solar_ts_DA)
    ),
    HydroCurtailment("HydroCurtailment",true,nodes5[3],
        TechHydro(60.0, 10.0, @NT(min = 0.0, max = 60.0), nothing, nothing, @NT(up = 10.0, down = 10.0), nothing),
        1000.0,TimeSeries.TimeArray(DayAhead,wind_ts_DA) )
]

sys5b = PowerSystem(nodes5, append!(generators5, generators_hg), loads5_DA, branches5, battery, 230.0, 1000.0)

m=Model()

pth = PowerSimulations.generationvariables(m, sys5b.generators.thermal, sys5b.time_periods)
pre = PowerSimulations.generationvariables(m, sys5b.generators.renewable, sys5b.time_periods)
Pin, Pout = PowerSimulations.generationvariables(m, sys5b.storage, sys5b.time_periods)
phg = PowerSimulations.generationvariables(m, generators_hg, sys5b.time_periods)
fl = PowerSimulations.branchflowvariables(m, sys5b.branches, sys5b.time_periods)
pcl = PowerSimulations.loadvariables(m, sys5b.loads, sys5b.time_periods)
