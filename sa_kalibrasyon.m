clear; clc; close all; format shortG;
%görüntüleri yükleme ve hataların ve levha üzerinde noktaların gösterimi
images = imageDatastore(fullfile('image')); 
imageFileNames = images.Files;
imagesay=length(imageFileNames);
figure,imshow(imageFileNames{1,1})
figure,imshow(imageFileNames{3})

[imagePoints, boardSize] = detectCheckerboardPoints(imageFileNames);
squareSizeInMM = 23; 
worldPoints = generateCheckerboardPoints(boardSize,squareSizeInMM);
params=estimateCameraParameters(imagePoints,worldPoints,'EstimateSkew',true);

figure,showReprojectionErrors(params); 
figure;
imshow(imageFileNames{1});
hold on;
plot(imagePoints(:,1,1), imagePoints(:,2,1),'go');
plot(params.ReprojectedPoints(:,1,1), params.ReprojectedPoints(:,2,1),'r+');
legend('Detected Points','ReprojectedPoints');
hold off;

%her levha için yöneltme parametrelerini hesaplama
x=4;y=0;z=0;
for i =1:imagesay
    [R,t]=extrinsics(imagePoints(:,:,i),worldPoints,params); 
    SA=[R;t];
    sT(i,:)=SA(4,:);
for k=1:3
    z=z+1;
    sR(z,:)=R(k,:);
end
for j=1:x
    y=y+1;
    Rt(y,:)=SA(j,:);
end
end
K=params.IntrinsicMatrix; %iç yöneltme matrisi
M=cameraMatrix(params,R,t)'; 
M_normal=K'*Rt'; %Her levha için projeksiyon matrisi

% RQ ayrıştırması 
say=0;say2=0;
for i=1:imagesay   
    say=say+4;
    [estK,estR] = rq(M_normal(:,say-3:say-1));
for j=1:3
    say2=say2+1;
    eK(say2,:)=[estK(j,:)];
    eR(say2,:)=[estR(j,:)];
end
end

%estK ve estR kontrolü
say3=0;
for i=1:imagesay  
    say3=say3+3;
    D(say3-2:say3,:)=diag(sign(diag(eK(say3-2:say3,:))));
    estK(say3-2:say3,:)=eK(say3-2:say3,:)*D(say3-2:say3,:);
    estR(say3-2:say3,:)=D(say3-2:say3,:)*eR(say3-2:say3,:);
    estK(say3-2:say3,:)=estK(say3-2:say3,:)/estK(say3,3);
    estt(say3-2:say3,:)=estK(say3-2:say3,:)^(-1)*M_normal(:,say3+1);
end

%distorsiyon kalibre etme
I=imread('dist-image\dist-image.jpeg'); %distorsiyonu kalibre edilecek görüntüyü yükleme
J1=undistortImage(I,params); 
figure; snc=imshowpair(I,J1, 'montage'); 
title('Orjinal Görüntü (sol) - Kalibre Edilmiş Görüntü (sağ)'); 
saveas(snc,'sonuclar\sonuc.jpeg');

%sonuçları dosyaya yazdırma
xlswrite('sonuclar\M_normal_projeksiyon_matrisi.xlsx',M_normal,'A1:AN3') 
xlswrite('sonuclar\K_ic_yoneltme_matrisi.xlsx',K','A1:C3')
xlswrite('sonuclar\radyal_distorsiyon_parametreler_k1_k2.xlsx',params.RadialDistortion,'A1:B1') 
xlswrite('sonuclar\R_donukluk_matrisi.xlsx',sR,'A1:C30') 
xlswrite('sonuclar\t_oteleme_vektoru.xlsx',sT,'A1:C10') 
save sonuclar\params.mat

