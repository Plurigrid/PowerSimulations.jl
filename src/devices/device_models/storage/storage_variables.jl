function activepower_variables(ps_m::CanonicalModel, devices::Array{T,1}, time_range::UnitRange{Int64}) where {T <: PSY.Storage}

    add_variable(ps_m, devices, time_range, :Psin, false,:var_active, -1)
    add_variable(ps_m, devices, time_range, :Psout, false, :var_active)

    return

end

function reactivepower_variables(ps_m::CanonicalModel, devices::Array{T,1}, time_range::UnitRange{Int64}) where {T <: PSY.Storage}

    add_variable(ps_m, devices, time_range, :Qst, false, :var_reactive)

    return

end

function energystorage_variables(ps_m::CanonicalModel, devices::Array{T,1}, time_range::UnitRange{Int64}) where T <: PSY.Storage

    add_variable(ps_m, devices, time_range,:Est, false)

    return

end

function storagereservation_variables(ps_m::CanonicalModel, devices::Array{T,1}, time_range::UnitRange{Int64}) where T <: PSY.Storage

    add_variable(ps_m, devices, time_range, :Sst, true)

    return

end