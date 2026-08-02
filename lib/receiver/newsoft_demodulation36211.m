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
        % TS 38.211 maps the bit labels in I/Q-interleaved order:
        % b0,b2,b4,b6 select I and b1,b3,b5,b7 select Q.
        demod_bits(1,:) = demod_soft(1,:)*4*D.*rou;
        demod_bits(2,:) = demod_soft(2,:)*4*D.*rou;
        demod_bits(3,:) = (8*D-abs(demod_soft(1,:)))*4*D.*rou;
        demod_bits(4,:) = (8*D-abs(demod_soft(2,:)))*4*D.*rou;
        demod_bits(5,:) = (4*D-abs(abs(demod_soft(1,:))-8*D))*4*D.*rou;
        demod_bits(6,:) = (4*D-abs(abs(demod_soft(2,:))-8*D))*4*D.*rou;
        demod_bits(7,:) = (2*D-abs(abs(abs(demod_soft(1,:))-8*D)-4*D))*4*D.*rou;
        demod_bits(8,:) = (2*D-abs(abs(abs(demod_soft(2,:))-8*D)-4*D))*4*D.*rou;
        demod_out = reshape(demod_bits,1,[]);
    case 1024 %% 1024QAM
        D=1/sqrt(682);
        demod_bits=zeros(10,L);
        % Keep the same I/Q-interleaved labeling for 1024QAM.
        demod_bits(1,:) = demod_soft(1,:)*4*D.*rou;
        demod_bits(2,:) = demod_soft(2,:)*4*D.*rou;
        demod_bits(3,:) = (16*D-abs(demod_soft(1,:)))*4*D.*rou;
        demod_bits(4,:) = (16*D-abs(demod_soft(2,:)))*4*D.*rou;
        demod_bits(5,:) = (8*D-abs(abs(demod_soft(1,:))-16*D))*4*D.*rou;
        demod_bits(6,:) = (8*D-abs(abs(demod_soft(2,:))-16*D))*4*D.*rou;
        demod_bits(7,:) = (4*D-abs(abs(abs(demod_soft(1,:))-16*D)-8*D))*4*D.*rou;
        demod_bits(8,:) = (4*D-abs(abs(abs(demod_soft(2,:))-16*D)-8*D))*4*D.*rou;
        demod_bits(9,:) = (2*D-abs(abs(abs(abs(demod_soft(1,:))-16*D)-8*D)-4*D))*4*D.*rou;
        demod_bits(10,:) = (2*D-abs(abs(abs(abs(demod_soft(2,:))-16*D)-8*D)-4*D))*4*D.*rou;
        demod_out = reshape(demod_bits,1,[]);
    otherwise
        disp('Error! Please input again');        
end
