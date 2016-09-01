function resource_bid = compute_bid(vd_optimal_resource,individual_utility_user_group, current_user_group_quality, migration_cost_matrix, price_vector, j,vd_latency,data_center_index,quality_values,user_group_index)
number_of_resource_types = 3;
%compute vd quality based on current VD optimal resource
vd_quality = compute_quality(vd_optimal_resource, user_group_index, quality_values);

% compute vd utility based on the quality  
vd_utility = vd_quality*vd_latency;

%compute the price based on the current optimal resource assigned to the VD
price_value = price_vector((number_of_resource_types*(j-1)+1):(number_of_resource_types*j))*(vd_optimal_resource');

% penalty - computed as a utility difference from the rest of VDs belonging to the
% same user group
for i=1:length(individual_utility_user_group)
    utility_difference(i) = (vd_utility-individual_utility_user_group(i))^2;
end

%quality - computed as a quality difference from the rest of VDs belonging to the
% same user group
for i = 1:length(current_user_group_quality)
    quality_difference(i) = (current_user_group_quality(i)-vd_quality)^2;
end

%resource bid computation
resource_bid = -vd_utility+ price_value+ migration_cost_matrix(data_center_index,j)+sum(quality_difference)+sum(utility_difference); 

end

