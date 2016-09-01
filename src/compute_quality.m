function [quality] = compute_quality(vd_optimal_resource, user_group_index, quality_values)
        quality_value_matrix = [0 0 0 0];
        
        % a weight of 0.25 is associated with all quality dimensions
        weight = [0.25 0.25 0.25 0.25];
        
        resource_type = 1;
       
        % iterate through the Q1 and Q2 values for CPU and RAM
        for j = 1:4
            quality_list_of_application_resource_type = quality_values{user_group_index}{j};
            quality_values_time = quality_list_of_application_resource_type(:,1);
            quality_values_resource = quality_list_of_application_resource_type(:,2)/1000;
            quality_values_length = length(quality_values_resource);
            
            if j==3
                resource_type = 2;
            end
            
            if vd_optimal_resource(resource_type)>=quality_values_resource(quality_values_length)
                   quality_value_matrix(j) = 1;
            else 
                   for i = 1:quality_values_length-1  
                         if vd_optimal_resource(resource_type)>quality_values_resource(i)&& vd_optimal_resource(resource_type)<=quality_values_resource(i+1)
                                    quality_value_matrix(j) = quality_values_time(i) + ((quality_values_time(i+1)-quality_values_time(i,1))/(quality_values_resource(i+1)-quality_values_resource(i)))*(vd_optimal_resource(resource_type)-quality_values_resource(i));                           
                         end

                   end
            end
        end
        quality = quality_value_matrix*weight';
 end    