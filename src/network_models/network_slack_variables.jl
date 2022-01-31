get_variable_multiplier(::SystemBalanceSlackUp, _, _) = 1.0
get_variable_multiplier(::SystemBalanceSlackDown, _, _) = -1.0

function add_variables!(
    container::OptimizationContainer,
    ::Type{T},
    ::PSY.System,
    ::Type{U},
) where {
    T <: Union{SystemBalanceSlackUp, SystemBalanceSlackDown},
    U <: Union{CopperPlatePowerModel, StandardPTDFModel},
}
    time_steps = get_time_steps(container)
    variable = add_variable_container!(container, T(), PSY.System, time_steps)

    for t in time_steps
        variable[t] =
            JuMP.@variable(container.JuMPmodel, base_name = "$(T)_{$t}", lower_bound = 0.0)
    end
    return
end

function add_variables!(
    container::OptimizationContainer,
    ::Type{T},
    sys::PSY.System,
    ::Type{U},
) where {
    T <: Union{SystemBalanceSlackUp, SystemBalanceSlackDown},
    U <: PM.AbstractActivePowerModel,
}
    time_steps = get_time_steps(container)
    bus_numbers = PSY.get_number.(PSY.get_components(PSY.Bus, sys))
    variable = add_variable_container!(container, T(), PSY.Bus, bus_numbers, time_steps)

    for t in time_steps, n in bus_numbers
        variable[n, t] = JuMP.@variable(
            container.JuMPmodel,
            base_name = "$(T)_{$n, $t}",
            lower_bound = 0.0
        )
    end
    return
end

function add_variables!(
    container::OptimizationContainer,
    ::Type{T},
    sys::PSY.System,
    ::Type{U},
) where {
    T <: Union{SystemBalanceSlackUp, SystemBalanceSlackDown},
    U <: PM.AbstractPowerModel,
}
    time_steps = get_time_steps(container)
    bus_numbers = PSY.get_number.(PSY.get_components(PSY.Bus, sys))
    variable_active =
        add_variable_container!(container, T(), PSY.Bus, bus_numbers, time_steps, "P")
    variable_reactive =
        add_variable_container!(container, T(), PSY.Bus, bus_numbers, time_steps, "Q")

    for t in time_steps, n in bus_numbers
        variable_active[n, t] = JuMP.@variable(
            container.JuMPmodel,
            base_name = "$(T)_{p, $n, $t}",
            lower_bound = 0.0
        )
        variable_reactive[n, t] = JuMP.@variable(
            container.JuMPmodel,
            base_name = "$(T)_{q, $n, $t}",
            lower_bound = 0.0
        )
    end
    return
end

function cost_function!(
    container,
    ::Type{PSY.System},
    model::NetworkModel{T},
    S::Type{T},
) where {T <: Union{CopperPlatePowerModel, StandardPTDFModel}}
    variable_up = get_variable(container, SystemBalanceSlackUp(), PSY.System)
    variable_dn = get_variable(container, SystemBalanceSlackDown(), PSY.System)

    for t in get_time_steps(container)
        add_to_objective_function!(
            container,
            (variable_dn[t] + variable_up[t]) * BALANCE_SLACK_COST,
        )
    end
    return
end

function cost_function!(
    container,
    ::Type{PSY.Bus},
    model::NetworkModel{T},
    S::Type{T},
) where {T <: PM.AbstractActivePowerModel}
    variable_up = get_variable(container, SystemBalanceSlackUp(), PSY.Bus)
    variable_dn = get_variable(container, SystemBalanceSlackDown(), PSY.Bus)
    bus_numbers = axes(variable_up)[1]
    @assert_op bus_numbers == axes(variable_dn)[1]
    for t in get_time_steps(container), n in bus_numbers
        add_to_objective_function!(
            container,
            (variable_dn[n, t] + variable_up[n, t]) * BALANCE_SLACK_COST,
        )
    end
    return
end
