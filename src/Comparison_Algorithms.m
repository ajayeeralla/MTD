%Market Driven Resource Optimization
clear
clc

% Load config and csv files path
addpath('Config');
addpath('csvFiles');

%Load application quality values for Campus, Engineering and Distance User
%Groups - Q1 - Application Open Time, Q2 - Application Close Time of Matlab
%for all the 3 users
quality_values{1}{1} =csvread('Campus_q1_CPU.csv');
quality_values{1}{2} =csvread('Campus_q2_CPU.csv');
quality_values{1}{3} =csvread('Campus_q1_RAM.csv');
quality_values{1}{4} =csvread('Campus_q2_RAM.csv');

quality_values{2}{1} =csvread('Engineering_q1_CPU.csv');
quality_values{2}{2} =csvread('Engineering_q2_CPU.csv');
quality_values{2}{3} =csvread('Engineering_q1_RAM.csv');
quality_values{2}{4} =csvread('Engineering_q2_RAM.csv');

quality_values{3}{1} =csvread('Distance_q1_CPU.csv');
quality_values{3}{2} =csvread('Distance_q2_CPU.csv');
quality_values{3}{3} =csvread('Distance_q1_RAM.csv');
quality_values{3}{4} =csvread('Distance_q2_RAM.csv');

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
available_data_center_resource = csvread('Available_Resource_Data_Center.csv');

% vd_information column values <VD Index, User Group Index, Latency@L1, Latency@L2, Latency@L3>
%Convention of user group index, 1->Campus Student
%2->Engineering site 3->Distance Learner
vd_information = load('VDInfo.txt'); 
vd_information = sortrows(vd_information,1);
vd_information(:,3:5) = vd_information(:,3:5)/1000; % Convert Latency values to 0-1 range

% vd_allocation is the current allocation based on initial utility values. Column values are  <VD Index, Data Center Index, Initial Utility>
vd_allocation = load('VDAlloc.txt'); 

%=====initial configurations start =======

number_of_iterations = 1000;
number_of_VDs = length(vd_allocation);
number_of_user_groups = 3;
number_of_resource_types = 3;
number_of_data_centers = 3;

%=====initial configurations end ==========

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

% current_resource_SLA of all 3 user groups
user_group_resource_vector{1} = csvread('Campus_Current_SLA.csv');
user_group_resource_vector{2} = csvread('Engineering_Current_SLA.csv');
user_group_resource_vector{3} = csvread('Distance_Current_SLA.csv');


% least latency
for i = 1:3
    user_group_row_indices = user_group_vd_row_indices{i};
    k = 1;
    migration_cost_vector = [];
    for j=1:length(user_group_row_indices)
        cur_data_center_index = vd_allocation(user_group_row_indices(j),2);
        vd_latencies = vd_user_group_index_latency(user_group_row_indices(j),3:5);
        [row, new_data_center_index] = min(vd_latencies);
        vd_least_latency = vd_user_group_index_latency(user_group_row_indices(j),new_data_center_index+2);
        vd_optimal_resource = user_group_resource_vector{i}(:,new_data_center_index)';
        vd_quality = compute_quality(vd_optimal_resource, 1, quality_values);
        vd_utility{i}(j) = vd_quality*vd_least_latency;
        if cur_data_center_index ~= new_data_center_index
            migration_cost_vector(k) = migration_cost_matrix(cur_data_center_index,new_data_center_index);
            k = k+1;
        end
    end
    user_group_utility_least_latency = sum(vd_utility{i})
    user_group_migration_cost_least_latency = sum(migration_cost_vector)
    user_group_migration_count_least_latency = length(migration_cost_vector(1,:))
    
end

%random walk 
for i = 1:3
    user_group_row_indices = user_group_vd_row_indices{i};
    k = 1;
    migration_cost_vector = [];
    for j=1:length(user_group_row_indices)
        cur_data_center_index = vd_allocation(user_group_row_indices(j),2);
        new_data_center_index = randi([1, 3]);
        vd_least_latency = vd_user_group_index_latency(user_group_row_indices(j),new_data_center_index+2);
        vd_optimal_resource = user_group_resource_vector{i}(:,new_data_center_index)';
        vd_quality = compute_quality(vd_optimal_resource, 1, quality_values);
        vd_utility{i}(j) = vd_quality*vd_least_latency;
        if cur_data_center_index ~= new_data_center_index
            migration_cost_vector(k) = migration_cost_matrix(cur_data_center_index,new_data_center_index);
            k = k+1;
        end
    end
    user_group_utility_random_walk = sum(vd_utility{i})
    user_group_migration_cost_random_walk = sum(migration_cost_vector)
    user_group_migration_count_random_walk = length(migration_cost_vector(1,:))
end

%round_robin
k = 0;
for i = 1:3
    user_group_row_indices = user_group_vd_row_indices{i};
    p = 1;
    migration_cost_vector = [];
    for j=1:length(user_group_row_indices)
        cur_data_center_index = vd_allocation(user_group_row_indices(j),2);
        if k >=0
            k = 0;
        end
        k = k+1;
        new_data_center_index = k;
        vd_least_latency = vd_user_group_index_latency(user_group_row_indices(j),new_data_center_index+2);
        vd_optimal_resource = user_group_resource_vector{i}(:,new_data_center_index)';
        vd_quality = compute_quality(vd_optimal_resource, 1, quality_values);
        % penalty factor - round robin 
        alpha = 0.2;
        vd_utility{i}(j) = (vd_quality*vd_least_latency) - alpha;
        if cur_data_center_index ~= new_data_center_index
            migration_cost_vector(p) = migration_cost_matrix(cur_data_center_index,new_data_center_index);
            p = p+1;
        end
    end
    user_group_utility_round_robin = sum(vd_utility{i})
    user_group_migration_cost_round_robin = sum(migration_cost_vector)
    user_group_migration_count_round_robin = length(migration_cost_vector(1,:))
end


%security constraint algorithm
for i= 1:length(vd_allocation(:,1))
    security_index = randi([1, 3]);
    vd_allocation(i,4) = security_index;
end

z= 3;
for i= 1:number_of_data_centers
    data_center_security_level(i,:) = [i z];
    z = z-1;
end

for i = 1:3
    user_group_row_indices = user_group_vd_row_indices{i};
    p = 1;
    migration_cost_vector = [];
    for j=1:length(user_group_row_indices)
        vd_security_index = vd_allocation(user_group_row_indices(j),4);
        cur_data_center_index = vd_allocation(user_group_row_indices(j),2);
        new_data_center_index = cur_data_center_index;
        for k= 1:number_of_data_centers
            data_center_security_index = data_center_security_level(k,2);
            if vd_security_index == data_center_security_index
                new_data_center_index = data_center_security_level(k,1);
            end
            
        end
                vd_least_latency = vd_user_group_index_latency(user_group_row_indices(j),new_data_center_index+2);
                vd_optimal_resource = user_group_resource_vector{i}(:,new_data_center_index)';
                vd_quality = compute_quality(vd_optimal_resource, 1, quality_values);
                vd_utility{i}(j) = vd_quality*vd_least_latency;
                if cur_data_center_index ~= new_data_center_index
                    migration_cost_vector(p) = migration_cost_matrix(cur_data_center_index,new_data_center_index);
                    p = p+1;
                end
        
    end
     user_group_utility_security_level = sum(vd_utility{i})
     user_group_migration_cost_security_level = sum(migration_cost_vector)
     user_group_migration_count_security_level = length(migration_cost_vector(1,:))
     
end



