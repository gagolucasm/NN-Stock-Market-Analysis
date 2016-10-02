%Predict Market orders with NN
%Author: lucasgago
close all;
clc
clear
contado=0;

%Adjust risk ratio

%% Import Data
filename = 'DATAPATH';
load(filename);
clearvars filename
openh=hed(:,2);
closeh=hed(:,5);
openh=openh/1000000;
closeh=closeh/1000000;
closeh( 258762)=closeh(258761);
openh( 258762)=openh(258761);

%Choose number of elements
noe=1000000;
noenn=300000;
closehr=closeh(1:noe);
openhr=openh(1:noe);

%% Create data with previous values
contador=1;
h = waitbar(0,'Initializing waitbar...');
for i=101:noe
    for j=1:100
        Open100(contador,j)=openhr(i-j);
    end
    if(mod(i,10000)==0)
     perc=round(100*i/(noe-101));
    waitbar(i/(noe-101),h,sprintf('%d%% along...',perc))
    end
    contador=contador+1;
end

Close100=closehr(100:noe);
%% Select zone of inactivity
var=0;

%% Generate clasification
for i=1:noe-100
    if Open100(i,1)>Close100(i)+var
        Clasif(i,1)=1;
        Clasif(i,2)=0;
    elseif Open100(i,1)<Close100(i)-var
        Clasif(i,1)=0;
        Clasif(i,2)=1;
    else
        Clasif(i,2)=0;
        Clasif(i,1)=0;
    end
end
%% Use part of it to train the NN
% RedOpen=Open100(1:1800,:);
% RedClose=Close100(1:1800,:);
% RedClasif=Clasif(1:1800,:);
% aRedOpen=Open100(1801:length(Open100),:);
% aRedClose=Close100(1801:length(Open100),:);
% aRedClasif=Clasif(1801:length(Open100),:);
aRedOpen=Open100;
aRedClose=Close100;
aRedClasif=Clasif;
RedOpen=Open100(1:noenn,:);
RedClose=Close100(1:noenn);
RedClasif=Clasif(1:noenn,:);

ex = RedOpen';
t = RedClasif';

hiddenLayerSize = 100;
net = patternnet(100);



net.divideParam.trainRatio = 80/100;
net.divideParam.valRatio = 10/100;
net.divideParam.testRatio = 10/100;

[net,tr] = train(net,ex,t);

y = net(ex);
e = gsubtract(t,y);
tind = vec2ind(t);
yind = vec2ind(y);
percentErrors = sum(tind ~= yind)/numel(tind);
performance = perform(net,t,y);



%% Evaluate Performace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%for x=0.5:0.01:0.78
x=0.57;
PClasif=net(aRedOpen');
PClasif=PClasif';
fallo=0;
contcomprar=0;
contvender=0;
contfallo=0;
acierto=0;
ventas=0;
compras=0;
fallos=0;
nooperar=0;
nooperarbien=0;



for i=1:length(PClasif)
    if PClasif(i,1)>x
        RoundClasif(i,2)=0;
        RoundClasif(i,1)=1;
    elseif PClasif(i,2)>x
        RoundClasif(i,2)=1;
        RoundClasif(i,1)=0;
    else
        RoundClasif(i,2)=0;
        RoundClasif(i,1)=0;
    end
end
%disp('Non Zero:')
%disp(nnz(RoundClasif))

%Clasificacion
for i=1:length(RoundClasif)
    if RoundClasif(i,1)==1 && RoundClasif(i,2)==0 && aRedClasif(i,1)==1 && aRedClasif(i,2)==0
        acierto=acierto+1;
        
        contcomprar=contcomprar+1;
        compras(contcomprar,1)=i;
        compras(contcomprar,2)=aRedOpen(i);
    elseif RoundClasif(i,1)==0 && RoundClasif(i,2)==1  && aRedClasif(i,1)==0 && aRedClasif(i,2)==1
        acierto=acierto+1;
        contvender=contvender+1;
        ventas(contvender,1)=i;
        ventas(contvender,2)=aRedOpen(i);
        
    elseif RoundClasif(i,1)==0 && RoundClasif(i,2)==0  && aRedClasif(i,1)==0 && aRedClasif(i,2)==0
        nooperarbien=nooperarbien+1;
        
        
    elseif RoundClasif(i,1)==0 && RoundClasif(i,2)==0
        nooperar=nooperar+1;
    else
        fallo=fallo+1;
        contfallo=contfallo+1;
        fallos(contfallo,1)=i;
        fallos(contfallo,2)=aRedOpen(i);
    end
end
ratio=acierto/(acierto+fallo);
parapie=[acierto,fallo];
if ( and( fallo,acierto)~=0)
    pie(parapie);
else
    disp('Algo esta mal')
    
end
contado=contado+1;
resultmatr(contado)=ratio;
resultopera(contado)=nnz(RoundClasif);
lratio(contado)=(((resultopera(contado)/3559)-0.5)*.5+(resultmatr(contado)));
%end
%% Plot Results
figure (2)
plot(aRedOpen(:,1),'k')
hold on

if fallos~=0
    plot (fallos(:,1),fallos(:,2),'r*')
end
if ventas~=0
    plot (ventas(:,1),ventas(:,2),'bo')
end
if compras~=0
    plot (compras(:,1),compras(:,2),'go')
end
str=['Hice ',num2str(contcomprar+contvender) , ' operaciones de ',num2str(length(aRedOpen) )];
disp(str)
figure (3)
subplot(2, 1, 1);
plot(resultmatr)
subplot(2, 1, 2);
plot(resultopera)

figure (4)
plot(lratio)
