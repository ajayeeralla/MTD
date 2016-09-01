%Market Driven Resource Optimization
clear
clc

% Load config and csv files path
addpath('Config');
addpath('csvFiles');
 VM_information = load('utility_location.txt');
 Euclidean_distance = zeros(1,5);
current_VM_location(1, :) = input('enter location of current VM as an ordered pair in the form [a b]:\n');
total_number_of_VMs = length(VM_information);
ordered_pair_location = VM_information(:,2:3);
%Find the Euclidean distance from current aggregate to each of the
%available VM
for j=1: total_number_of_VMs
                   Euclidean_distance(j) = sqrt(sum(current_VM_location - ordered_pair_location(j))^2);
end
%Find the aggregate manager close to the current VM
for i=1:total_number_of_VMs
    if min(Euclidean_distance)== Euclidean_distance(i)      
  sprintf ('Closest aggregate is the one contains VM%d\n  Euclidean_distance from the current VM = %d', i , Euclidean_distance(i))
  break;
     end
   end

     
