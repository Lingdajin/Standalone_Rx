function y_descramble=descramble(y)
%y为输入的需要解扰的序列
%输出的y_descramble为经过解扰操作后的序列
n=length(y);  %输入序列的长度

%产生第一个m序列x1
x1(1)=1;  
x1(2:31)=0;

%产生第二个m序列x2
n1=1;
n2=10;  %n1，n2为产生x2的参数
c_init=n1*2^15+n2;
c_bin=dec2bin(c_init);
nn=length(c_bin);
for i=1:nn
    x2(i)=str2num(c_bin(nn-i+1));
end
x2(nn+1:31)=0;

%通过不断迭代，扩展产生相应长度的m序列x1，x2
for j=32:n+1600
    x1(j)=xor(x1(j-28),x1(j-31));
    x2(j)=xor(xor(x2(j-28),x2(j-29)),xor(x2(j-30),x2(j-31)));   
end

c(1:n)=xor(x1(1601:1600+n),x2(1601:1600+n));  %产生加扰序列（也是解扰需要的序列）
softc=ones(1,n);
for i = 1:n
    if c(i) == 1
        softc(i) = -1;
    end
end
y_descramble=y.*softc;  %解扰操作后的序列
% y_descramble=xor(y,c);  %解扰操作后的序列

