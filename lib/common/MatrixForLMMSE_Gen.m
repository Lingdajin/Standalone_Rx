%% Aimed to calculate the LMMSE matrix.
%% Modified at 2012.3.13.

function [ M_LMMSE ]= MatrixForLMMSE_Gen(path_power,path_delay,Pilot_position,FFT_size,sigma,Nc,NumOfTaps,Nc_used_Pilot)

% Note: (1) M_LMMSE is the matrix 'RHH(RHH+NoisePower)^(-1)' for LMMSE channel estimation [ RHH(RHH+NoisePower)^(-1)*Hls].
      % (2) M_LMMSEs will be different if interval patterns of Pilot in different columns are different
index = squeeze(Pilot_position(1,:,1))-(FFT_size-Nc)/2;
interval = kron(index',ones(1,Nc_used_Pilot))-kron(index,ones(Nc_used_Pilot,1));
Matrix = zeros(Nc_used_Pilot,Nc_used_Pilot);
for indexOfTaps = 1:NumOfTaps
    Matrix = Matrix + (path_power(indexOfTaps))*exp(-1j*2*pi*path_delay(indexOfTaps)*interval/FFT_size);
end
M_LMMSE = Matrix/(Matrix + diag(ones(1,Nc_used_Pilot))*sigma^2);

end
