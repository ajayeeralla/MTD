%Market Driven Resource Optimization
clear
clc

% Load config and csv files path
addpath('Config');
addpath('csvFiles');

%Load application quality values for Campus, Engineering and Distance User
%Groups - Q1 - Application Open Time, Q2 - Application Close Time of Matlab
%for all the 3 users
quality_values{1}{1} =csvread('Dips_q1_CPU.csv');
quality_values{1}{2} =csvread('Dips_q2_CPU.csv');
quality_values{1}{3} =csvread('Dips_q1_RAM.csv');
quality_values{1}{4} =csvread('Dips_q2_RAM.csv');

quality_values{2}{1} =csvread('Banking_q1_CPU.csv');
quality_values{2}{2} =csvread('Banking_q2_CPU.csv');
quality_values{2}{3} =csvread('Banking_q1_RAM.csv');
quality_values{2}{4} =csvread('Banking_q2_RAM.csv');

% quality_values{3}{1} =csvread('Banking_q1_CPU.csv');
% quality_values{3}{2} =csvread('Banking_q2_CPU.csv');
% quality_values{3}{3} =csvread('Banking_q1_RAM.csv');
% quality_values{3}{4} =csvread('Banking_q2_RAM.csv');

%Cost associated in moving a VD from one data center to another
migration_cost_matrix = csvread('Migration_Cost.csv');

%minimum and maximum CPU, RAM and N/W resources (SLA) required by the 3
%user groups
%=======convention===========
%row - 3 User Groups,
%column - CPU, RAM and N/W SLAs
user_group_min_resource_SLA = csvread('Resource_Min_SLA.csv');
user_group_max_resource_SLA = csvread('Resource_Max_SLA.csv');

%CPU, RAM and N/W Resources available across all the 3 data centers
%=====Convention=========
%Each row - L1, L2, L3 data centers
%Each column - CPU, RAM and N/W resources at each data center
available_data_center_resource = csvread('Available_Resource_Aggregates.csv');

% vd_information column values <VD Index, User Group Index, Latency@L1, Latency@L2, Latency@L3>
%Convention of user group index, 1->Campus Student
%2->Engineering site 3->Distance Learner
vd_information = load('VDInfo.txt'); 
vd_information = sortrows(vd_information,1);
vd_information(:,3:5) = vd_information(:,3:5)/1000; % Convert Latency values to 0-1 range

% vd_allocation is the current allocation based on initial utility values. Column values are  <VD Index, Data Center Index, Initial Utility>
vd_allocation = load('VDAlloc.txt'); 

%=====initial configurations start =======

number_of_iterations = 100;
number_of_VDs = length(vd_allocation);
number_of_user_groups = 2;
number_of_resource_types = 3;
number_of_data_centers = 3;

%=====initial configurations end ==========

final_net_utility = 0;
vd_user_group_index_latency = [];

% Retrieve user group index and latency information for the allocated VDs
% stored in vd_user_group_index_latency with column values <VD Index, User Group Index, Latency@L1, Latency@L2, Latency@L3>
for i= 1:length(vd_allocation(:,1))
   [status,index] = ismember(vd_allocation(i),vd_information(1:length(vd_information)));
    if status == 1    
       vd_user_group_index_latency(i,:) = vd_information(index,:);
    end      
end


%user_group_vd_row_indices contains a cell array of sorted VDs row indices according to
%individual user groups where each cell contains row indices of VDs
%beloging to the particular user group
for i = 1:number_of_user_groups
    [row_indices, col_indices] = find(vd_user_group_index_latency(:,2) == i);
    user_group_vd_row_indices{i} = row_indices;
end


%=====initialization start ==================
%vd_new_allocation structure column values -<VD Index, Data Center Index>
vd_new_allocation = vd_allocation;

current_data_center_resource = available_data_center_resource;
current_user_group_resource_SLA = user_group_min_resource_SLA;
current_net_utility = zeros(number_of_VDs,1);
current_vd_resource_SLA = zeros(number_of_VDs,3);

price_vector = zeros(1,number_of_resource_types*number_of_data_centers);             % Initializing Prices

new_user_group_quality = zeros(1,number_of_user_groups);

current_user_group_quality = 4*ones(1,number_of_user_groups);
%vd_optimal_resource = zeros(1,3);

%=====initialization end ==================

% the main logic
% compute new utility over the entire allocated VD set for the configured number of
% iterations

for t = 1:number_of_iterations
    %user_group_assignment structure - a value of '1' indicates the optimized
    %resource_bid is already computed for the given user_group else '0'
    user_group_assignment = zeros(1,number_of_user_groups);
    
    % iterate through the entire set of VDs for every iteration to compute
    % the new utility for each VD
    for i = 1:number_of_VDs
           
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


    %resources at each of the data centers should not exceed the maximum
    %available resource at the data center
for i = 1:number_of_data_centers
    for j=1:number_of_resource_types
        if current_data_center_resource(j,i)>available_data_center_resource(j,i)
            current_data_center_resource(j,i)=available_data_center_resource(j,i);
        end
    end
end

current_user_group_quality = new_user_group_quality;
% Weight Change #####
alpha1(t) =1.5/sqrt(t);
gamma = 1/sqrt(t);
if t>450                                    
    alpha1(t)=1/t;
    gamma = 1/t;
end
alpha =alpha1(t);


k = 1;

%compute the price vector for each of the resource types in every data
%center
for i = 1:number_of_data_centers
    for j=1:number_of_resource_types
        error(k) = -(current_data_center_resource(j,i));
        delta = alpha*(error(k));
        price_vector(k) = max(0,price_vector(k) + delta);
        k=k+1;
    end    

end

%if the new utility is greater than the current utility, then update it as
%the final utility with vd allocation
if t>1
    utility_test = sum(current_net_utility);
    if utility_test>=final_net_utility
        final_vd_allocation = vd_new_allocation;
        final_net_utility = current_net_utility;
    end

end

end

%migration_list contains the list of VDs to be migrated
migration_list = [];
counter =1;
for i=1:number_of_VDs
    if vd_allocation(i,2)~=final_vd_allocation(i,2)
        %add VD Index
        migration_list(counter,1) = vd_allocation(i,1);
        %add User Group Index
        migration_list(counter,2) = vd_user_group_index_latency(i,2);
        %add the original data center index
        migration_list(counter,3) = vd_allocation(i,2);
        %add the new data center index
        migration_list(counter,4) = final_vd_allocation(i,2);
        counter=counter+1;
    end
end

%migration_cost_vector - contains the structure with column names
%<Migration cost from old data center to new data center User Group Index>
for i=1:length(migration_list(:,1))
    migration_cost_vector(i,1:2) = [migration_cost_matrix(migration_list(i,3),migration_list(i,4)) migration_list(i,2)];
end

%print the net utility per user group
for i = 1:number_of_user_groups
    net_utility_user_groups(i) = sum(final_net_utility(user_group_vd_row_indices{i}))
end

%print the migration cost per user group
for i = 1:number_of_user_groups
    [user_group_row_indices column_indices] = find(migration_cost_vector(:,2)==i);
    number_of_users_migrated = length(user_group_row_indices)
    migration_cost_user_group(i) = sum(migration_cost_vector(user_group_row_indices,1))   
end
%======initial utility start ==============================
%structure of below variables - row - CPU,RAM and N/W, col- Data Center 1,
%Data Center 2 and Data Center 3

resource_vector_campus = csvread('Dips_Current_SLA.csv');
% resource_vector_engineering = csvread('Engineering_Current_SLA.csv');
resource_vector_distance = csvread('Banking_Current_SLA.csv');

campus_row_indices = user_group_vd_row_indices{1};

for i=1:3
    
    [row_indices col_indices] = find(vd_allocation(:,2)== i);
    new_vd_row_indices = intersect(campus_row_indices, row_indices);
    number_of_campus_users(i) = length(new_vd_row_indices);
    
    campus_latency{i}= vd_user_group_index_latency(new_vd_row_indices,i+2);
    
    vd_optimal_resource = resource_vector_campus(:,i)';
    for j=1:number_of_campus_users(i)
        campus_user_group_quality{i}(j) = compute_quality(vd_optimal_resource, 1, quality_values);
        
    end
    
    initial_utility_campus(i) = campus_user_group_quality{i}*campus_latency{i};
end

campus_initial_utility = sum(initial_utility_campus)

engineering_row_indices = user_group_vd_row_indices{2};
for i=1:length(resource_vector_engineering(:,1))
    [vd_row_indices col_indices] = find(vd_allocation(:,2)==i);
     new_vd_row_indices = intersect(engineering_row_indices, vd_row_indices);
    engineering_latency{i} = vd_user_group_index_latency(new_vd_row_indices,i+2);
    number_of_engineering_users(i) = length(new_vd_row_indices);
    
    vd_optimal_resource = resource_vector_engineering(:,i)';
    for j=1:number_of_engineering_users(i)
        engineering_user_group_quality{i}(j) = compute_quality(vd_optimal_resource, 2, quality_values);
    end
    
    initial_utility_engineering(i) = engineering_user_group_quality{i}*engineering_latency{i};
end

engineering_initial_utility = sum(initial_utility_engineering)

distance_row_indices = user_group_vd_row_indices{3};
for i=1:length(resource_vector_distance(:,1))
    [vd_row_indices col_indices] = find(vd_allocation(:,2)==i);
    new_vd_row_indices = intersect(distance_row_indices, vd_row_indices);
    number_of_distance_users(i) = length(new_vd_row_indices);
     distance_latency{i} = vd_user_group_index_latency(new_vd_row_indices,i+2);
   
    vd_optimal_resource = resource_vector_distance(:,i)';
    for j=1:number_of_distance_users(i)
        distance_learner_user_group_quality{i}(j) = compute_quality(vd_optimal_resource, 3, quality_values);
    end
    
    initial_utility_distance(i) = distance_learner_user_group_quality{i}*distance_latency{i};
end

distance_initial_utility = sum(initial_utility_distance)



%{
for i=1:number_of_user_groups
    row_indices = user_group_vd_row_indices{i};
    for j= 1:length(row_indices)
        data_center_index = vd_allocation(row_indices(j),2);
         initial_vd_utility(j)= initial_campus_quality*vd_user_group_index_latency(row_indices(j),data_center_index+2);
    end
    initial_net_utility(i) = sum(initial_vd_utility)
end
%}
%======initial utility end ==============================
