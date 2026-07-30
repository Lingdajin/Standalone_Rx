function OutSTBCDecoder=STBCDecoder(InData,ChannelEsti)

%%*************************************************************************
%%Function information:
%%-------------------------------------------------------------------------
%%First time   : 11/30/2001                                           
%%Newest modified time:12/12/2001                                         
%%Programmer:Xiaohui Yu
%%Modified by Alin
%%Version: 1.0
%%-------------------------------------------------------------------------
%%*************************************************************************

%%*************************************************************************
%% Reference:
%%-------------------------------------------------------------------------
%% 1.  S. M. Alamouti,¡°A simple transmitter diversity scheme for wireless
%% communications,¡±IEEE J. Select. Areas Commun.,vol. 16, pp.1451¨C1458,
%% Oct. 1998.

%% 2.  V. Tarokh,H. Jafarkhani and A.R. Calderbank "Space-Time Block 
%% Coding for Wireless Communication:Performance Results", IEEE J. Select.
%% Areas Commun.,VOL. 17, NO.3 pp. 451 - 460 March 1999
%%-------------------------------------------------------------------------

%% Function discription:
%%-------------------------------------------------------------------------
%% Function ReceiverSTBCDecoder is used to decoder the STBC encoded data.
%%-------------------------------------------------------------------------

%% Note:
%%-------------------------------------------------------------------------
%% This function just suitable to the 2 tranmit antennas
%%-------------------------------------------------------------------------

%% Input: 
%%-------------------------------------------------------------------------
%% InData: The input data matrix
%% ChannelEsti: Channel estimation result from estimator  a matrix of
%% Nr-by-Nt
%%-------------------------------------------------------------------------

%% Output:
%%-------------------------------------------------------------------------
%% OutSTBC: The output data column vector from the STBC decoder 
%%-------------------------------------------------------------------------
%%*************************************************************************


%%Robust part
if nargin~=2
   error('the number of input parameter for function --ReceiverSTBCDecoder -- should be 2.');
end 

[Nr,L]=size(InData);			 %Length of Sequence and Number of Receivers

if (rem(L,2))
    error('The size of input InData should be even.')
end 

[nr,Nt] = size(ChannelEsti);
if Nt~=2
    error('the number of transmit antenna should be 2 !!');
end
if nr~=Nr
    error('parameter size error: ChannelEsti');
end
%End of robust part
 
% Combination
index=[0:L/2-1]*2;
R_Combine=zeros(1,L);
for nr=1:Nr
   R_Combine(1,index+1) = R_Combine(1,index+1) + InData(nr,index+1) * conj(ChannelEsti(nr,1)) + conj(InData(nr,index+2)) * ChannelEsti(nr,2);
   R_Combine(1,index+2) = R_Combine(1,index+2) + InData(nr,index+1) * conj(ChannelEsti(nr,2)) - conj(InData(nr,index+2)) * ChannelEsti(nr,1);
end
% End of combination

% unitized
channel_gain=sum(sum(ChannelEsti.*conj(ChannelEsti)));
R_Combine=R_Combine/channel_gain;

%Output interface
OutSTBCDecoder=R_Combine;
%End of Output interface