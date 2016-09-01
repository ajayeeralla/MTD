 # Author : Ajay kumar Eeralla
 # Calculate Euclidean Distance accross all the available aggregates
# Choose the closest aggregate
#for the sake of simplicity the data is assumed and given in the form of csv files

import csv
import numpy as np
with open('utility_location.csv') as csvfile:
 VM_information = list(csv.reader(csvfile))
 Euclidean_distance = [[1]*1]*5
 current_VM_location = [ ]
current_VM_location = input('enter location of current VM as an ordered pair in the form [a b]:\n')
#print current_VM_location
total_number_of_VMs = len(VM_information)
#print VM_information
ordered_pair_location = np.array(VM_information)[: , 1:3]
#print ordered_pair_location
current_VM_location= [float(i) for i in current_VM_location]
#print ordered_pair_location
#print current_VM_location
#Find the Euclidean distance from current aggregate to each of the available aggregate
for j in range(0 , total_number_of_VMs):
                   temp = map(float , ordered_pair_location[j])
                   Euclidean_distance[j] = np.sqrt(np.sum((np.array(current_VM_location) -np.array(temp))**2))
print Euclidean_distance 
#Find the aggregate manager close to the current VM
for i in range(0 , total_number_of_VMs):
    if min(Euclidean_distance)== Euclidean_distance[i]:      
    	print "Closest aggregate is the one contains VM%d \nEuclidean_distance from the current VM : %f ." % (i+1 , Euclidean_distance[i])
    	break



