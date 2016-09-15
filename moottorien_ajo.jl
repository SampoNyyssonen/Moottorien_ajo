function aseta_asemat(kara_asema::Float64)
  global global_kara_asema=kara_asema
end

const maksimi_kierrosnopeus=502 #[rad/s]4793rpm
const kierteen_nousu=10 #mm
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


function position_control(nykyinen_asema::Float64,haluttu_asema::Float64,alku_asema::Float64,
                          alku_aika::Float64,nyt_aika::Float64,
                          nopeus::Float64,haluttu_nopeus::Float64,haluttu_kiihtyvyys::Float64,haluttu_jarrutus::Float64)

  kulunut_matka   = abs(alku_asema - nykyinen_asema)
  koko_matka      = abs(haluttu_asema - alku_asema)
  kiihdytys_matka = abs(0.5*haluttu_kiihtyvyys*(haluttu_nopeus/haluttu_kiihtyvyys)^2)
  jarrutus_matka  = abs(0.5*haluttu_jarrutus*(nopeus/haluttu_jarrutus)^2)
  suunta          = sign(haluttu_asema - alku_asema)
  println(kulunut_matka, " ",koko_matka," ",kiihdytys_matka," ",jarrutus_matka," ",suunta)

  if(koko_matka > 0)
    if (abs(nopeus) < abs(haluttu_nopeus) && abs(haluttu_asema-nykyinen_asema) > jarrutus_matka)
      println("kiihdytys")
      return suunta*abs(haluttu_kiihtyvyys*(nyt_aika-alku_aika)) #nopeus on aika riippuvainen, eikä ota huomioon nykyistä nopeutta. Pyrkii pitämään annetussa nopeudessa.
      #return suunta*moottorin_nopeudenmuutos(nopeus,aika_askel,haluttu_kiihtyvyys)

    elseif (abs(haluttu_asema-nykyinen_asema) <= jarrutus_matka && kulunut_matka < koko_matka)
      println("jarrutusta")
      return -1*suunta*abs(haluttu_jarrutus*(nyt_aika-alku_aika)) #nopeus on aika riippuvainen, eikä ota huomioon nykyistä nopeutta. Pyrkii pitämään annetussa nopeudessa.
      #return suunta*moottorin_nopeudenmuutos(nopeus,aika_askel,haluttu_jarrutus)

    elseif (abs(nopeus) >= abs(haluttu_nopeus) && abs(haluttu_asema-nykyinen_asema) > jarrutus_matka)
      println("ajoa")
      return suunta*abs(haluttu_nopeus)

    elseif nykyinen_asema == haluttu_asema
      println("saavutettu")
      return 0

    end
  end


end

function millimetri_kierrosnopeudeksi(nopeus::Float64,nousu::Float64)
  println("millimetrit kierrokseiksi")
  return ((nopeus/nousu)*2*pi)
end


function moottorin_nopeudenmuutos(nyt_nopeus::Float64,aika_askel::Float64,muutosnopeus::Float64)
    return abs(nyt_nopeus+(muutosnopeus*aika_askel))
end

function kierrokset_vaannoksi(Wref::Float64,Mref::Float64,w::Float64,M::Float64,tao::Float64,kytkin::Float64)
  println("muuetaan kierrokset väännkösi")
  if kytkin == 0.0 #kierrosnoepus
    Kw=Mref/Wref
    Mmuutos = (Kw*(Wref-w) - M)/tao

  else #vääntö
    Mmuutos = (Mref-M)/ tao

  end

  return M + Mmuutos

end
