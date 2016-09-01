%Market Driven Resource Optimization
clear
clc

% Load config and csv files path
addpath('Config');
addpath('csvFiles');
 
%=====initial configurations start =======
number_of_users = 10;
number_of_available_VMs = 4 ;
number_of_resource_types = 3;

%Cost associated in moving a VD from one data center to another
migration_cost_matrix = csvread('Migration_Cost.csv');
%=====initial configurations end ==========
optimal_resource = csvread('Resource_Min_SLA.csv');
 final_net_utility = 0;
current_net_utility = [0.4];
utility_at_VM = [ 0.2 ,0.3 , 0.25, 0.35];
price_vector{1} = csvread('resources_at_VM1.csv',1 , 0 );
price_vector{2} = csvread('resources_at_VM2.csv',1 , 0 );
price_vector{3} = csvread('resources_at_VM3.csv',1 , 0 );
price_vector{4} = csvread('resources_at_VM4.csv',1 , 0 );
price_vector{5} = csvread('resources_at_VM5.csv',1 , 0 );

 for j=1 : number_of_available_VMs
      bid(j) = -utility_at_VM(j)+(current_net_utility - utility_at_VM(j))^2+ price_vector{j}*(optimal_resource') + migration_cost_matrix(1,j);                
 end


%user_group_vd_row_indices contains a cell array of sorted VDs row indices according to
%individual user groups where each cell contains row indices of VDs
%beloging to the particular user group
% for i = 1:number_of_user_groups
%     [row_indices, col_indices] = find(vd_user_group_index_latency(:,2) == i);
%     user_group_vd_row_indices{i} = row_indices;
% end


%=====initialization start ==================
% %vd_new_allocation structure column values -<VD Index, Data Center Index>
% vd_new_allocation = vd_allocation;
% 
% current_data_center_resource = available_data_center_resource;
% current_user_group_resource_SLA = user_group_min_resource_SLA;
% current_net_utility = zeros(number_of_VDs,1);
% current_vd_resource_SLA = zeros(number_of_VDs,3);
% 
% price_vector = zeros(1,number_of_resource_types*number_of_data_centers);             % Initializing Prices
% 
% new_user_group_quality = zeros(1,number_of_user_groups);
% 
% current_user_group_quality = 4*ones(1,number_of_user_groups);
%vd_optimal_resource = zeros(1,3);

%=====initialization end ==================

% the main logic
% compute new utility over the entire allocated VD set for the configured number of
% iterations

% for t = 1:number_of_iterations
    %user_group_assignment structure - a value of '1' indicates the optimized
    %resource_bid is already computed for the given user_group else '0'
%     user_group_assignment = zeros(1,number_of_user_groups);
    
    % iterate through the entire set of VDs for every iteration to compute
    % the new utility for each VD
%     for i = 1:number_of_available_VMs
           
%             % retrieve the user group index
%             user_group_index = vd_user_group_index_latency(i,2);
%             % retrieve the number of users for the given user group 
%             total_users_in_user_group = length(user_group_vd_row_indices{user_group_index});
%             
%             % retrieve the data center index for the VD
%             data_center_index = vd_allocation(i,2);
%             % retrieve the VD index
%             vd_index = vd_allocation(i,1);
%             
%             % assign VD's min and max SLA for CPU, RAM and N/W as the user group's
%             % minimum and maximum SLA as the required SLA
%             vd_resource_min_SLA = user_group_min_resource_SLA(user_group_index,:);
%             vd_resource_max_SLA = user_group_max_resource_SLA(user_group_index,:);
%             
           
            
            %individual_utility_user_group contains the current computed
            %utility of each of the VDs belonging to that user group
%             individual_utility_user_group = current_net_utility(user_group_vd_row_indices{user_group_index});
%             
            %if the optimal resource bid is already computed for the given
            %user_group, then calculate the net utility directly
%             if user_group_assignment(user_group_index) == 1
                
                % retrieve the computed optimal resource based on the user
                % group of the VD
%                 vd_optimal_resource = current_user_group_resource_SLA(user_group_index,:)
                
                %compute bid = sum of (negative utility) +price
                %associated in fetching optimal resource at the given data
                %center
%                 for j=1:number_of_VMs
%                      %find the latency for the currently assigned data center index
%                     vd_latency = vd_user_group_index_latency(i, j+2);
%                     
%                     % current utility
%                     vd_utility = new_user_group_quality(user_group_index)*vd_latency;
%                     
%                      %==========================================================
%                         % penalty for having the same user group but different utility   
%                         %==========================================================
% %                         for a=1:
% %                             utility_difference(a) = (vd_utility-individual_utility_user_group(a))^2;
% %                         end
%                     
%                     %bid(j) = -vd_utility+sum(utility_difference)+ price_vector(number_of_resource_types*(j-1)+1:number_of_resource_types*j)*(vd_optimal_resource') + migration_cost_matrix(data_center_index,j);
%                     bid(j) = -utility_at_VM(i)+(current_utility - utility_at_VM(i))^2+ price_vector(number_of_resource_types*(j-1)+1:number_of_resource_types*j)*(optimal_resource') + migration_cost_matrix(1,j);
%                 end
%         
%                 [row,new_data_center_index] = min(bid); % Choosing the data center where minimum cost is incurred
%                 
%                     %give back the previously computed resource in the last
%                     %iteration to the old data center
%                     current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2))+current_vd_resource_SLA(i,:)'; % giving back the resource to the data center where i was
%                     %update the new data center index
%                     vd_new_allocation(i,1:2)=[vd_index new_data_center_index]; 
%                     %compute the new utility for the given VD
%                     current_net_utility(i)=new_user_group_quality(user_group_index)*vd_user_group_index_latency(i,new_data_center_index+2);
%                     %update the resources available in the data center list
%                     current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2)) - vd_optimal_resource'; % Taking resource from the new data center
%                     %update the resource SLA list in the current iteration
%                     current_vd_resource_SLA(i,:) = vd_optimal_resource; % updating the allocated resources
              
%             else 
%                 %set the user group index to 1 - to indicate optimal
%                 %resource allocation
%                 user_group_assignment(user_group_index) = 1;
%                 
%                 %square point algorithm
%                 option = optimset('Algorithm','active-set');
%                 
%                 %current allocated resource for VD from the previous
%                 %iteration
%                 vd_current_resource_SLA = current_vd_resource_SLA(i,:);
                
                %resource SLA that is required for the VD's user group
                %vd_current_optimal_resource = user_group_min_resource_SLA(user_group_index,:);
               
                
                %calculate the new optimal resource based on constrained
                %optimization function
%                 for j=1:number_of_data_centers
%                     vd_latency = vd_user_group_index_latency(i, j+2);
%                                                                                         
%                     [vd_new_resource, cost_bid, exitflag] = fmincon(@(vd_optimal_resource) compute_bid(vd_optimal_resource,individual_utility_user_group,current_user_group_quality, migration_cost_matrix, price_vector, j,vd_latency,data_center_index,quality_values,user_group_index),vd_current_resource_SLA,[],[],[],[],vd_resource_min_SLA,vd_resource_max_SLA,[],option);
%                    
%                     cost_data_center(j) = cost_bid;
%                     resource_vector(j,:) = vd_new_resource;
%                 end
%                 [row,new_data_center_index] = min(cost_data_center);          % Choosing the data center so that utility  is maximized (negative cost minimized)
%                 
%                 %retrieve the new optimal resource for VD based on lowest
%                 %bid of the data center
%                 vd_optimal_resource = resource_vector(new_data_center_index,:);
%                 
%                 %update the user group resource SLA
%                 current_user_group_resource_SLA(user_group_index,:) = vd_optimal_resource;
%                 
%                 %give back the resources to the old data center
%                 current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2))+current_vd_resource_SLA(i,:)';
%                 
%                 %update the new allocation
%                 vd_new_allocation(i,1:2)=[vd_index new_data_center_index]; % Updating the allocation (moving to data center 'qjj')
%                 
%                 %substract the resource from the new data center
%                 current_data_center_resource(:,vd_new_allocation(i,2)) = current_data_center_resource(:,vd_new_allocation(i,2)) - vd_optimal_resource'; % Taking resource from the new data center
%                 current_vd_resource_SLA(i,:) = vd_optimal_resource; % updating the resource SLA vector
%                 
%                 %calculate the new quality
%                 vd_quality = compute_quality(vd_optimal_resource, user_group_index, quality_values);
%                 
%                 %update the computed quality in the user group quality
%                 %vector
%                 new_user_group_quality(user_group_index) = vd_quality;
%                 
%                 %calculate the new utility as a product of quality*latency
%                 current_net_utility(i)=new_user_group_quality(user_group_index)*vd_user_group_index_latency(i,new_data_center_index+2);
%                 
%         end
        
%     end
% 
% 
% for j = 1:4
%     for for a=1:total_users
%                             utility_difference(a) = (vd_utility-individual_utility_user_group(a))^2;
%                         end
%     
%     bid(j) = -vd_utility+sum(utility_difference)+ price_vector(number_of_resource_types*(j-1)+1:number_of_resource_types*j)*(vd_optimal_resource') + migration_cost_matrix(data_center_index,j);
%     
% end
% for i =1 : length(bid)
%     if bid(i) == min(bid)
%         sprintf ('Move to VM %d and bid(VMi) is %d', i, min(bid))
%         break;
%     end
% end

 
 
 