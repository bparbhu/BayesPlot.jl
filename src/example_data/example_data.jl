function example_mcmc_draws(chains=4, params=4)
    @assert (1 <= chains <= 4) && (1 <= params <= 6)
    x = ex_draws[:, 1:chains]  # Assuming ex_draws is defined in scope
    if chains > 1
        return x[:, :, 1:params]
    else
        return x[:, 1:params]
    end
end


function example_yrep_draws()
    return ex_yrep   # Assuming ex_yrep is defined in scope
end

function example_y_data()
    return ex_y     # Assuming ex_y is defined in scope
end


function example_x_data()
    return ex_x     # Assuming ex_x is defined in scope
end


function example_group_data()
    return ex_group  # Assuming ex_group is defined in scope
end
