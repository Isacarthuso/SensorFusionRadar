# Radar Target Generation and Detection

1) Implementation steps for the 2D CFAR process.

First of all loop the set of cells in the doppler range, start and ending at indices that have appropriate margins. Second, cut the training cells excluding the guard cells around. 
After that apply the conversion from decibel to power and find the noise level to cells and apply the conversion from power to decibels. After that add an offset and apply the threshold 
and store the result in an array. 

2) Selection of Training, Guard cells and offset.
The manual value was chosen based on a rectangular window with the major dimension along with the range cell to have a better-filtered result from RDM.
The offset value is quite important to isolate the simulated target avoiding false positives. 

Values considred in source coude:
Tr = 80;
Td = 20; 
Gr = 7;
Gd = 7;
offset =12;

3) Steps taken to suppress the non-thresholded cells at the edges.


for i = 1 : Nr/2
    for j = 1:Nd
        
        if (RDM(i,j) ~= 0 && RDM(i,j) ~= 1 )
             RDM(i,j) = 0;
        end
    end
end