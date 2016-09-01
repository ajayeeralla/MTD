%Market Driven Resource Optimization
clear
clc

% Load config and csv files path
addpath('Config');
addpath('csvFiles');
 
%=====initial configurations start =======

number_of_resource_types = 3;

%Cost associated in moving a service from one VM to another
%Read data from input files
migration_cost_matrix = csvread('Migration_Cost.csv');
optimal_resource = csvread('Resource_Min_SLA.csv');
VM_information = load('utility_location.txt');
available_resource_information = csvread('available_resource_aggregates.csv');
%initialize objects
 final_net_utility = 0;
current_net_utility = [0.4];
total_number_of_VMs = length(VM_information);
utility_at_VM = VM_information(:, 1);
bid = zeros(1,5);
price_vector = ones(1,3,5);
%read price vector from file
for i=1:total_number_of_VMs
     price_vector(:,:,i) = available_resource_information (i+i,:);
     end
%Calculate bids accross all the candidate VMs

for j=1: total_number_of_VMs
    bid(j) = -utility_at_VM(j)+(current_net_utility - utility_at_VM(j))^2+ price_vector(:,:,j)*(optimal_resource') + migration_cost_matrix(1 , j);                
end
 %Find the VM which gives min BID
for i=1:total_number_of_VMs
    if min(bid) == bid(i)      
  sprintf ('Min Bid at VM%d, bid(VM %d) = %d', i, i , min(bid))
     final_net_utility = utility_at_VM(i)
             end
   end
%end
     
