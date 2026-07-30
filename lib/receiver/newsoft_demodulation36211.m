function  demod_out = newsoft_demodulation36211(demod_in,mod_mode,rou)

%% created by lhrzrzlh, 2006.1.17
%% version 1.0
%% mod_in must be a vector
%%*************************************************************************
%% modified: zhc
%% 此解调函数是根据36.212写的
%% 相比于“%% Modified by HanLu  2005-11-12 Version: 0.2”的调制函数的不同在于：
%% (1) BSPK的星座图不一样  (2) QPSK的映射方式不一样
%% 其中16QAM与64QAM是一样的
%% reference: 36.212
%% date: 2008-4-14
%% data2012-5-9,由于BPSK的解调不怎么对，修改版。

demod_data = reshape(demod_in,1,[]);
if mod_mode==2 %% BPSK
    demod_data=demod_data*exp(-j*pi/4);
end

L = length(demod_data);  % 待解调的数据长度
 demod_temp=zeros(2,L);
demod_temp(1,:)=real(demod_data);
demod_temp(2,:)=imag(demod_data);
demod_soft = demod_temp;

switch (mod_mode)
    case 2    %% BPSK
        D=1;
        demod_out = demod_soft(1,:)*4*D.*rou;
    case 4    %% QPSK
        D=1/sqrt(2);
        demod_bits = zeros(2,L);
        demod_bits(1,:) = demod_soft(1,:)*4*D.*rou;
        demod_bits(2,:) = demod_soft(2,:)*4*D.*rou;
        demod_out = reshape(demod_bits,1,[]);
    case 16    %% 16QAM
        D=1/sqrt(10);
        demod_bits=zeros(4,L);
        demod_bits(1,:) = demod_soft(1,:)*4*D.*rou;
        demod_bits(2,:) = demod_soft(2,:)*4*D.*rou;
        demod_bits(3,:) = -(abs(demod_soft(1,:))-2*D)*4*D.*rou;
        demod_bits(4,:) = -(abs(demod_soft(2,:))-2*D)*4*D.*rou;
        demod_out = reshape(demod_bits,1,[]);   
    case 64  %% 64QAM    
        D=1/sqrt(42);
        demod_bits=zeros(6,L);
        demod_bits(1,:) = demod_soft(1,:)*4*D.*rou;
        demod_bits(2,:) = demod_soft(2,:)*4*D.*rou;
        demod_bits(3,:) = (4*D-abs(demod_soft(1,:)))*4*D.*rou;
        demod_bits(4,:) = (4*D-abs(demod_soft(2,:)))*4*D.*rou;
        demod_bits(5,:) = (2*D-abs(abs(demod_soft(1,:))-4*D))*4*D.*rou;
        demod_bits(6,:) = (2*D-abs(abs(demod_soft(2,:))-4*D))*4*D.*rou;
        demod_out = reshape(demod_bits,1,[]);
    case 256 %% 256QAM
        D=1/sqrt(170);
        demod_bits=zeros(8,L);
        demod_bits(1,:) = -demod_soft(1,:)*4*D.*rou;
        demod_bits(2,:) = (abs(demod_soft(1,:))-8*D)*4*D.*rou;
        demod_bits(3,:) = (-4*D+abs(abs(demod_soft(1,:))-8*D))*4*D.*rou;
        demod_bits(4,:) = (-2*D+abs(abs(abs(demod_soft(1,:))-8*D)-4*D))*4*D.*rou;
        demod_bits(5,:) = -demod_soft(2,:)*4*D.*rou;
        demod_bits(6,:) = (abs(demod_soft(2,:))-8*D)*4*D.*rou;
        demod_bits(7,:) = (-4*D+abs(abs(demod_soft(2,:))-8*D))*4*D.*rou;
        demod_bits(8,:) = (-2*D+abs(abs(abs(demod_soft(2,:))-8*D)-4*D))*4*D.*rou;
        demod_out = reshape(demod_bits,1,[]);
    otherwise
        disp('Error! Please input again');        
end

