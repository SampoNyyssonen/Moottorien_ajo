function aseta_asemat(kara_asema::Float64)
  global global_kara_asema=kara_asema
end

const maksimi_kierrosnopeus=502 #[rad/s]4793rpm
const kierteen_nousu=0.01 #mm
const maksimi_kiihtys=(2/kierteen_nousu)*2*pi #rad/s^2
const asetettu_nopeus=314 #[rad/s] 3000rpm
const kiihdytys_aika=asetettu_nopeus/maksimi_kiihtys

function resetoi()
  global kiihdytys_matka=5.0
  global koko_matka=0
  global alku_aika=0
  global jarrutus_aika=0
  global kiihdytys_kierros=0
end

function fun_moottorin_ajo(haluttu_asema::Float64,uusi_asema::Float64,uusi_aika::Float64)
  kulunut_matka=abs(((uusi_asema - global_kara_asema)/kierteen_nousu)*2*pi)
  suunta=sign(haluttu_asema - global_kara_asema)
  if(kulunut_matka==0.0 && alku_aika==0)
    global koko_matka=(abs(haluttu_asema - global_kara_asema)/kierteen_nousu)*2*pi
    global alku_aika=uusi_aika-0.001
  end
  if(koko_matka>(2*kiihdytys_matka) && koko_matka>0)
    if((uusi_aika-alku_aika)<kiihdytys_aika && asetettu_nopeus>maksimi_kiihtys*(uusi_aika-alku_aika))
      kierrosnopeus=suunta*maksimi_kiihtys*(uusi_aika-alku_aika)
      global kiihdytys_matka=kulunut_matka                            #Asettaa tällä kappaleelle kiihdytys matkan, jota käytetään jarrutuksessa
  elseif(asetettu_nopeus <= maksimi_kiihtys*(uusi_aika-alku_aika) && kulunut_matka < (koko_matka-kiihdytys_matka))
        kierrosnopeus=suunta*asetettu_nopeus
        global jarrutus_aika=uusi_aika
  elseif((kulunut_matka)>=(koko_matka-kiihdytys_matka) && kulunut_matka<koko_matka)
        kierrosnopeus=suunta*asetettu_nopeus-suunta*maksimi_kiihtys*(uusi_aika-jarrutus_aika)
    end
  elseif(koko_matka<=(2*kiihdytys_matka) && koko_matka>0) # Jos moottori ei kerkeä kiihtymään tavoite nopeuteen
    if(kulunut_matka<(koko_matka/2))
      kierrosnopeus=suunta*maksimi_kiihtys*(uusi_aika-alku_aika)
      global jarrutus_aika=uusi_aika
      global kiihdytys_kierros=kierrosnopeus
    elseif((kulunut_matka>=(koko_matka/2)) && kulunut_matka<koko_matka)
      kierrosnopeus=kiihdytys_kierros-suunta*maksimi_kiihtys*(uusi_aika-jarrutus_aika)#saavutettu kierronopeus miinus nykinen sqrt(2*s/a)=t--sjoitus-->a*sqrt(2*s/a)-->sqrt(2*a*s)
    end
  elseif(koko_matka==0 && kulunut_matka !=0)
    aseta_asemat(uusi_asema)
    kierrosnopeus=0
  end
  if sign(kierrosnopeus) != suunta
    kierrosnopeus=suunta*kierrosnopeus
  end

  return kierrosnopeus
end

function moottorien_kierrosnopeus(Fwd::Float64,Bwd::Float64,Torque::Float64,SpeedControl::Float64,Enable::Float64,TargetPos::Float64,TargetSpeed::Float64,TargetAcc::Float64,TargetDec::Float64,TargetTorque::Float64)
    suunta::Float64

    if((Fwd+Bwd)>1 || (Torque+SpeedControl)>1)  #virhe tarkastelua
      return 0
    end

    if(Fwd==1)  #liikesuunta
      suunta=1
    elseif(Bwd==1)
      suunta=-1
    else
      suunta=0
    end

    if Torque==0 && SpeedControl==0

    end

end
