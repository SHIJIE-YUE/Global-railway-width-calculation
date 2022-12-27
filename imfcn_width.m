function max_width = imfcn_width(I)
%% 
%This function is to calculate the width of the google tile merged map

%% image process
% convert to gray picture
I_gray=rgb2gray(I);
% rot1=imrotate(I_gray,33,'crop');  % rotate
%% get the longest line
fillgap=10;
fillgap_gap=1;
while true
    minlength=50;
    thresh_gap=0.1;
    sigma_gap=2;
    all_max_len=0;
    all_xy_long=[];
    max_width=0;
    for thresh=0.1:thresh_gap:0.2
        for sigma=1:sigma_gap:5
            % edge detection
            bw=edge(I_gray,'canny',thresh,sigma);
            [H,T,R]=hough(bw);
            p=houghpeaks(H,5,'threshold',ceil(0.1*max(H(:))));
            lines=houghlines(bw,T,R,p,'FillGap',fillgap,'MinLength',minlength);
            % get the longest line
            max_len=0;
            for k=1:length(lines)
                xy=[lines(k).point1;lines(k).point2];

                len=norm(lines(k).point1-lines(k).point2);
                if(len>max_len)
                    max_len=len;
                    xy_long=xy;
                end
            end
            if max_len>all_max_len
                all_max_len=max_len;
                all_xy_long=xy_long;
            end
        end
    end

    %% get the parallel line
    angle_thresh=5;
    lines_new=[];
    for thresh=0.1:thresh_gap:0.2
        for sigma=1:sigma_gap:5
            % edge detection
            bw=edge(I_gray,'canny',thresh,sigma);
            [H,T,R]=hough(bw);
            p=houghpeaks(H,5,'threshold',ceil(0.1*max(H(:))));
            lines=houghlines(bw,T,R,p,'FillGap',fillgap,'MinLength',minlength);
            for k=1:length(lines)
                xy=[lines(k).point1;lines(k).point2];
                x1=xy(1,1);
                y1=xy(1,2);
                x2=xy(2,1);
                y2=xy(2,2);
                x3=all_xy_long(1,1);
                y3=all_xy_long(1,2);
                x4=all_xy_long(2,1);
                y4=all_xy_long(2,2);

                a=[x2-x1,y2-y1];
                b=[x3-x4,y3-y4];
                A=[a;b];
                B=1-pdist(A,'cosine');
                angle=acos(B)/pi*180;
                delta_angle=abs(angle-180);
                if delta_angle<angle_thresh
                    lines_new=[lines_new,lines(k)];
                end
            end
        end
    end
    %% get the width
    max_dist=0;
    for k=1:length(lines_new)
        xy=[lines_new(k).point1;lines_new(k).point2];
        x1=xy(1,1);
        y1=xy(1,2);
        x2=xy(2,1);
        y2=xy(2,2);
        for j=1:length(lines_new)
            xy_another=[lines_new(j).point1;lines_new(j).point2];
            x3=xy_another(1,1);
            y3=xy_another(1,2);
            x4=xy_another(2,1);
            y4=xy_another(2,2);
            p1=[x1;y1];
            p2=[x2;y2];
            p3=[x3;y3];
            p4=[x4;y4];
            dist_1=abs(det([p2-p1,p3-p1]))/norm(p2-p1);
            dist_2=abs(det([p2-p1,p4-p1]))/norm(p2-p1);
            mean_dist=(dist_1+dist_2)/2;
            if mean_dist>max_dist
                max_dist=mean_dist;
            end
        end
    end

    max_width=max_dist;
    if max_width>50
        break;
    else

        fillgap=fillgap-fillgap_gap;
        if fillgap<=0
            max_width=50;
            break;
        end
    end

end
end





%--------------------------------------------------------------------------
