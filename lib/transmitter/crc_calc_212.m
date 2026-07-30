function crc_bits = crc_calc_212(data_in,polynomial)
	%Three crc generation polynomial were proposed in 36.212:
	%   gCRC24A(D) = [D24 + D23 + D18 + D17 + D14 + D11 + D10 + D7 + D6 + D5 + D4 + D3 + D + 1]
	%   gCRC24B(D) = [D24 + D23 + D6 + D5 + D + 1]
	%   gCRC16(D)  = [D16 + D12 + D5 + 1] 
	%reference: 3GPP TS 36.212 V8.1.0 (2007-11) Multiplexing and channel coding (Release 8)
	%date: 2008-3-18
	
	len_data = length(data_in);
	
	%%  gCRC24A(D) = [D24 + D23 + D18 + D17 + D14 + D11 + D10 + D7 + D6 + D5 + D4 + D3 + D + 1]
	if strcmp(upper(polynomial),'CRC24A')==1
       s=zeros(1,24);
       for i=1:len_data
           T2=mod(s(24)+data_in(i),2);
           s(24)=mod(s(23)+T2,2);
           s(23)=s(22);
           s(22)=s(21);
           s(21)=s(20);
           s(20)=s(19);
           s(19)=mod(s(18)+T2,2);
           s(18)=mod(s(17)+T2,2);
           s(17)=s(16);
           s(16)=s(15);
           s(15)=mod(s(14)+T2,2);
           s(14)=s(13);
           s(13)=s(12);
           s(12)=mod(s(11)+T2,2);
           s(11)=mod(s(10)+T2,2);
           s(10)=s(9);
           s(9)=s(8);
           s(8)=mod(s(7)+T2,2);
           s(7)=mod(s(6)+T2,2);
           s(6)=mod(s(5)+T2,2);
           s(5)=mod(s(4)+T2,2);
           s(4)=mod(s(3)+T2,2);
           s(3)=s(2);
           s(2)=mod(s(1)+T2,2);
           s(1)=T2;
       end
       
%         s=zeros(1,8);
%         for i=1:len_data
%             T2=mod(s(8)+data_in(i),2)
%             s(8)=mod(s(7)+T2);
%             s(7)=s(6);
%             s(6)=s(5);
%             s(5)=mod(s(4)+T2,2);
%             s(4)=mod(s(3)+T2,2);
%             s(3)=s(2);
%             s(2)=mod(s(1)+T2,2);
%             s(1)=T2;
%         end
            
	elseif strcmp(upper(polynomial),'CRC24B')==1
       %%  gCRC24B(D) = [D24 + D23 + D6 + D5 + D + 1]
       s=zeros(1,24);
       for i=1:len_data
           T2=mod(s(24)+data_in(i),2);
           s(24)=mod(s(23)+T2,2);
           s(23)=s(22);
           s(22)=s(21);
           s(21)=s(20);
           s(20)=s(19);
           s(19)=s(18);
           s(18)=s(17);
           s(17)=s(16);
           s(16)=s(15);
           s(15)=s(14);
           s(14)=s(13);
           s(13)=s(12);
           s(12)=s(11);
           s(11)=s(10);
           s(10)=s(9);
           s(9)=s(8);
           s(8)=s(7);
           s(7)=mod(s(6)+T2,2);
           s(6)=mod(s(5)+T2,2);
           s(5)=s(4);
           s(4)=s(3);
           s(3)=s(2);
           s(2)=mod(s(1)+T2,2);
           s(1)=T2;
        end
        
	elseif strcmp(upper(polynomial),'CRC16')==1
	%%  gCRC16(D) = [D16 + D12 + D5 + 1] 
       s=zeros(1,16);
       for i=1:len_data
           T2=mod(s(16)+data_in(i),2);
           s(16)=s(15);
           s(15)=s(14);
           s(14)=s(13);
           s(13)=mod(s(12)+T2,2);
           s(12)=s(11);
           s(11)=s(10);
           s(10)=s(9);
           s(9)=s(8);
           s(8)=s(7);
           s(7)=s(6);
           s(6)=mod(s(5)+T2,2);
           s(5)=s(4);
           s(4)=s(3);
           s(3)=s(2);
           s(2)=s(1);
           s(1)=T2;
        end
	else
        error('the crc polynomial is not proposed in 36.212');
	end
	
	%The bits in the Codec status is the cyclic redundancy check bit.
	%remeber to reverse the vecter s from right to left.
	crc_bits=rot90(s)';

