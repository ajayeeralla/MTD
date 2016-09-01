%Market Driven Resource Optimization
clear
clc

% Load config and csv files path
addpath('Config');
addpath('csvFiles');

for i = 1:4
    number_of_available_VMS
           
            % retrieve the user group index
            user_group_index = vd_user_group_index_latency(i,2);
            % retrieve the number of users for the given user group 
            total_users_in_user_group = length(user_group_vd_row_indices{user_group_index});
            
            % retrieve the data center index for the VD
            data_center_index = vd_allocation(i,2);
            % retrieve the VD index
            vd_index = vd_allocation(i,1);
            
            % assign VD's min and max SLA for CPU, RAM and N/W as the user group's
            % minimum and maximum SLA as the required SLA
            vd_resource_min_SLA = user_group_min_resource_SLA(user_group_index,:);
            vd_resource_max_SLA = user_group_max_resource_SLA(user_group_index,:);
            
           
            
            %individual_utility_user_group contains the current computed
            %utility of each of the VDs belonging to that user group
            individual_utility_user_group = current_net_utility(user_group_vd_row_indices{user_group_index});
            
            %if the optimal resource bid is already computed for the given
            %user_group, then calculate the net utility directly
            if user_group_assignment(user_group_index) == 1
                
                % retrieve the computed optimal resource based on the user
                % group of the VD
                vd_optimal_resource = current_user_group_resource_SLA(user_group_index,:);
                
                %compute bid = sum of (negative utility) +price
                %associated in fetching optimal resource at the given data
                %center
                for j=1:number_of_data_centers
                     %find the latency for the currently assigned data center index
                    vd_latency = vd_user_group_index_latency(i, j+2);
                    
                    % current utility
                    vd_utility = new_user_group_quality(user_group_index)*vd_latency;
                    
                     %==========================================================
                        % penalty for having the same user group but different utility   
                        %==========================================================
                        for a=1:total_users_in_user_group
                            utility_difference(a) = (vd_utility-individual_utility_user_group(a))^2;
                        end
                    
                    bid(j) = -vd_utility+sum(utility_difference)+ price_vector(number_of_resource_types*(j-1)+1:number_of_resource_types*j)*(vd_optimal_resource') + migration_cost_matrix(data_center_index,j);
                end
        
                [row,new_data_center_index] = min(bid); % Choosing the data center where minimum cost is incurred
                
                    %give back the previously computed resource in the last
                    %iteration to the old data center
                    current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2))+current_vd_resource_SLA(i,:)'; % giving back the resource to the data center where i was
                    %update the new data center index
                    vd_new_allocation(i,1:2)=[vd_index new_data_center_index]; 
                    %compute the new utility for the given VD
                    current_net_utility(i)=new_user_group_quality(user_group_index)*vd_user_group_index_latency(i,new_data_center_index+2);
                    %update the resources available in the data center list
                    current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2)) - vd_optimal_resource'; % Taking resource from the new data center
                    %update the resource SLA list in the current iteration
                    current_vd_resource_SLA(i,:) = vd_optimal_resource; % updating the allocated resources
              
            else 
                %set the user group index to 1 - to indicate optimal
                %resource allocation
                user_group_assignment(user_group_index) = 1;
                
                %square point algorithm
                option = optimset('Algorithm', 'active-set' );
                
                %current allocated resource for VD from the previous
                %iteration
                vd_current_resource_SLA = current_vd_resource_SLA(i,:);
                
                %resource SLA that is required for the VD's user group
                %vd_current_optimal_resource = user_group_min_resource_SLA(user_group_index,:);
               
                
                %calculate the new optimal resource based on constrained
                %optimization function
                for j=1:number_of_data_centers
                    vd_latency = vd_user_group_index_latency(i, j+2);
                                                                                        
                    [vd_new_resource, cost_bid, exitflag] = fmincon(@(vd_optimal_resource) compute_bid(vd_optimal_resource,individual_utility_user_group,current_user_group_quality, migration_cost_matrix, price_vector, j,vd_latency,data_center_index,quality_values,user_group_index),vd_current_resource_SLA,[],[],[],[],vd_resource_min_SLA,vd_resource_max_SLA,[],option);
                   
                    cost_data_center(j) = cost_bid;
                    resource_vector(j,:) = vd_new_resource;
                end
                [row,new_data_center_index] = min(cost_data_center);          % Choosing the data center so that utility  is maximized (negative cost minimized)
                
                %retrieve the new optimal resource for VD based on lowest
                %bid of the data center
                vd_optimal_resource = resource_vector(new_data_center_index,:);
                
                %update the user group resource SLA
                current_user_group_resource_SLA(user_group_index,:) = vd_optimal_resource;
                
                %give back the resources to the old data center
                current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2))+current_vd_resource_SLA(i,:)';
                
                %update the new allocation
                vd_new_allocation(i,1:2)=[vd_index new_data_center_index]; % Updating the allocation (moving to data center 'qjj')
                
                %substract the resource from the new data center
                current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2)) - vd_optimal_resource'; % Taking resource from the new data center
                current_vd_resource_SLA(i,:) = vd_optimal_resource; % updating the resource SLA vector
                
                %calculate the new quality
                vd_quality = compute_quality(vd_optimal_resource, user_group_index, quality_values);
                
                %update the computed quality in the user group quality
                %vector
                new_user_group_quality(user_group_index) = vd_quality;
                
                %calculate the new utility as a product of quality*latency
                current_net_utility(i)=new_user_group_quality(user_group_index)*vd_user_group_index_latency(i,new_data_center_index+2);
                
        end
        
    end