# Author : Ajay kumar Eeralla
# Calculate Bids accross all the available VMs
# Choose the VM which gives low bid value
#for the sake of simplicity the data is assumed and given in the form of csv files

import csv
import numpy as np
with open('Available_Resource_Aggregates.csv') as csvfile:
  available_resource_information = list(csv.reader(csvfile))
with open('Migration_Cost.csv') as csvfile1:
 migration_cost_matrix = list(csv.reader(csvfile1))

with open('Resource_Min_SLA.csv') as csvfile2:
 optimal_resource = list(csv.reader(csvfile2))
with open('utility_location.csv') as csvfile3:
 VM_information =list(csv.reader(csvfile3 ))
number_of_resource_types = 3
# initialize objec
final_net_utility = 0
utility_at_VM = []
current_net_utility = 0.4
total_number_of_VMs = len(VM_information)
temp=np.array(VM_information)
utility_at_VM = temp[:,0]
#utility_at_VM.append(row[1] for row in VM_information)
bid = [0] * 5
price_vector = [[1]*3]*5
#print utility_at_VM
#print VM_information
#print price_vector
#print available_resource_information
#price_vector[0] = available_resource_information[1]
#print total_number_of_VMs

#read price vector from file
for i in range(0 , total_number_of_VMs) :
     price_vector[i] = available_resource_information[2*i+1]
#print price_vector
    
#Calculate bids accross all the candidate VMs
for j in range(0 , total_number_of_VMs):
    a =  [float(i) for i in price_vector[j]]
    b =  [float(i) for i in optimal_resource[0]]
    cost_for_optimal_resourse =  np.dot(np.array(a) , np.array(b).T)
    bid[j] = float(utility_at_VM[j]) + ( float(current_net_utility) - float( utility_at_VM[j]))**2 + cost_for_optimal_resourse + float(migration_cost_matrix[0][j])
#print bid
    
#Find the VM which gives min BID
for i in range(0 , total_number_of_VMs) :
    if min(bid) == bid[i]:    
       print "Min Bid at VM%d, bid(VM %d) = %f." % (i+1, i+1 ,min(bid))
       final_net_utility = utility_at_VM[i]
       print "final_net_utility = %f." % (float(final_net_utility))
 


 

