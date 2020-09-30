clear all;
clc;


%% Eviroment setup
% Radar Specifications
% Frequency of operation = 77GHz
% Max Range = 200m
% Range Resolution = 1 m
% Max Velocity = 100 m/s
frequency = 77e9;
maxRange = 200;
rangeResolution = 1;
maxVelocity = 100;

%speed of light = 3e8
c = 3*10^8;

% User Defined Range and Velocity of target
% Target initial pose =  110 m
% Target constant speed -20 m/s
range = 100;
speed = -50;

%% Target Generation and Detection

% Bandwidth = speed of light / (2 * range resolution)
B = c / (2 * rangeResolution);

% Chirp Time = 5.5 * 2 * max Range / speed of light
Tchirp = 5.5 * 2 * maxRange / c;

% Slope = Bandwidth / Chirp Time
slope = B / Tchirp;

%Operating carrier frequency of Radar 
fc= 77e9;             
                                                    
% Total Time Nd * Tchirp 
Nd=128;                  

%The number of samples on each chirp. 
Nr=1024;                  

% Timestamp for running the displacement scenario for every sample on each
% chirp
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples

%transmitted signal
Tx=zeros(1,length(t)); 

%received signal
Rx=zeros(1,length(t)); 

%beat signal
Mix = zeros(1,length(t)); 

%beat signal
Mix2 = zeros(1,length(t)); 

%Similar vectors for range_covered and time delay.
r_t=zeros(1,length(t));
td=zeros(1,length(t));

for i=1:length(t)         
    
    
    r_t(i) =  range + speed*t(i);
    delay = 2 *  r_t(i) / c;
    td(i) = delay;
 
    Tx(i) = cos(2 * pi() * (fc * t(i) + slope * power(t(i),2) / 2));
    Rx(i) = cos(2 * pi() * (fc * (t(i) - delay) + slope * power(t(i)- delay,2) / 2));
    
    Mix2(i) = cos(2 * pi() * (2 * slope * r_t(i)  / c) * t(i) + (2 * fc * speed / c)* t(i));
    Mix(i)= Tx(i)  * Rx(i);

   
end
%% FFT Operation

Mix=reshape(Mix,[1, (Nr * Nd)]);

sigFft = fft(Mix,Nr)/Nr;

A = abs(sigFft);

B = A(1:Nr/2 - 1);

figure ('Name','FFT')
f = (0:200)/Nr;
plot(B) 
axis ([0 200 0 1]);

%% 2nd FFT RANGE DOPPLER RESPONSE


Mix=reshape(Mix,[Nr,Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix,Nr,Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1:Nr/2,1:Nd);
sig_fft2 = fftshift (sig_fft2);
RDM = abs(sig_fft2);
RDM = 10*log10(RDM) ;

%use the surf function to plot the output of 2DFFT and to show axis in both
%dimensions

doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure,surf(doppler_axis,range_axis,RDM);


%% CFAR implementation

Tr = 80;
Td = 20; 
Gr = 7;
Gd = 7;

n_traincell = (2*(Td+Gd)+1)  * (2 * (Tr + Gr)+ 1) - ((2 * Gr + 1) * (2 * Gd +1));

offset =12;

%Create a vector to store noise_level for each iteration on training cells

noise_level = zeros(1,1);

for i = Tr + Gr + 1:Nr/2 - (Gr +Tr)
    for j = Td + Gd +1:Nd - (Gd+Td)
        
        for k = i  - ( Tr + Gr) : i + (Gr + Tr)
            for l = j - (Td + Gd) : j + (Gd + Td)
                
                if ( abs( i - k) > Gr || abs(j - l) > Gd)
                    noise_level = noise_level + db2pow(RDM(k,l));
                end
            end
        end

        
        threeshold = pow2db(noise_level/n_traincell);
        
       
        threeshold = threeshold  + offset;
        
        CUT = RDM(i,j);
        
        if  (CUT < threeshold)
            RDM(i,j) = 0;
        else
            RDM(i,j) = 1;
        end
        
        % cleaning noise_level value
         noise_level = zeros(1,1);
    end
end


for i = 1 : Nr/2
    for j = 1:Nd
        
        if (RDM(i,j) ~= 0 && RDM(i,j) ~= 1 )
             RDM(i,j) = 0;
        end
    end
end
    

figure,surf(doppler_axis,range_axis,RDM);
colorbar; 