function pyöritä(akseli::Int64,kulma::Int64)

  if akseli == 1
    rotation = [1   0           0;
                0   cosd(kulma) -sind(kulma);
                0   sind(kulma)  cosd(kulma)]
  elseif akseli == 2
    rotation = [cosd(kulma)  0   sind(kulma);
                0           1   0;
               -sind(kulma)  0   cosd(kulma)]
  elseif akseli == 3 
     rotation = [cosd(kulma) -sind(kulma) 0;
                 sind(kulma)  cosd(kulma) 0;
                 0           0          1]
  end

  return rotation

end
