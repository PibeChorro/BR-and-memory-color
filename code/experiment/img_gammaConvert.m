function img = img_gammaConvert(LUT, img, varargin)
% function img = img_gammaLUT(gammaLUT,img);
% same as last bit in img_gammaLUT.m, takes gammaLUT as input and gives img as output.
% abartels 1.5.2007
%
% img: any old truecolor rgb img (y,x,rgb), range [0-255] or [0-1], 2D (n_pix,3) or 3D (x,y,3)
%		output img: img with values looked up in LUT.
% LUT:	Lookup-table such that normalized R,G,B functions are identical and follow the desired_gamma. 
%			Re-write your img-files then with that lookup table.
%		LUT has 256 entries, each has a value between [0,255]. 
%			To transform image, you take rgb-value+1 as index to LUT, and LUT's value as new rgb-value.
%
% optional: keyword followd by value:
%		'-1' : 1	invert_flag:	Do the inversion of LUT, such that img = LUT(LUTinv(img)).
%
% see img_gammaLUT.m


flag3d=0;
if ndims(img)>2
	flag3d=1;
	[ny,nx,~]=size(img);
	img=reshape(img,nx*ny,3); % 2D
end

% make sure img goes from 0-255:
flag255=1;
if max(img(:))<=1
	flag255=0;
	img=floor(img*255.999); % [0,255]
end

% LUT transform:
img(:,1)=LUT(img(:,1)+1,1);
img(:,2)=LUT(img(:,2)+1,2);
img(:,3)=LUT(img(:,3)+1,3);	


if ~flag255 % return it in same format as it came in
	img=img/255;
end
if flag3d
	img=reshape(img,ny,nx,3); % 3D
end