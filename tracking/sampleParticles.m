function S_next_tag = sampleParticles(S_prev, C)
N=size(S_prev,2);
S_next_tag=zeros(size(S_prev));
%sampling each partical
for n=1:N
    r=rand(1);
    indicator=find(C>=r,1,'first');
    S_next_tag(:,n)=S_prev(:,indicator);
end

end 
