#=function position_control_timestep(nykyinen_asema::Float64,haluttu_asema::Float64,alku_asema::Float64,
                          alku_aika::Float64,nyt_aika::Float64,aika_askel::Float64,
                          nopeus::Float64,haluttu_nopeus::Float64,haluttu_kiihtyvyys::Float64,haluttu_jarrutus::Float64)

  kulunut_matka   = abs(alku_asema - nykyinen_asema)
  koko_matka      = abs(haluttu_asema - alku_asema)
  kiihdytys_matka = abs(0.5*haluttu_kiihtyvyys*(haluttu_nopeus/haluttu_kiihtyvyys)^2)
  jarrutus_matka  = abs(0.5*haluttu_jarrutus*(nopeus/haluttu_jarrutus)^2)
  suunta          = sign(haluttu_asema - alku_asema)
  println("Kulunut matka:",kulunut_matka," mm. Koko matka:",koko_matka," mm. Kiihdytys matka:",kiihdytys_matka,"mm. Jarrutus matka:",jarrutus_matka,"mm. Suunta:",suunta)

  if(koko_matka > 0)
    if (abs(nopeus) < abs(haluttu_nopeus) && abs(haluttu_asema-nykyinen_asema) > jarrutus_matka)
      println("kiihdytys")
      #return suunta*abs(haluttu_kiihtyvyys*(nyt_aika-alku_aika)) #nopeus on aika riippuvainen, eikä ota huomioon nykyistä nopeutta. Pyrkii pitämään annetussa nopeudessa.
      return suunta*moottorin_nopeudenmuutos(nopeus,aika_askel,haluttu_kiihtyvyys)

    elseif (abs(haluttu_asema-nykyinen_asema) <= jarrutus_matka && kulunut_matka < koko_matka)
      println("jarrutusta")
      #return -1*suunta*abs(haluttu_jarrutus*(nyt_aika-alku_aika)) #nopeus on aika riippuvainen, eikä ota huomioon nykyistä nopeutta. Pyrkii pitämään annetussa nopeudessa.
      return -1*suunta*moottorin_nopeudenmuutos(nopeus,aika_askel,haluttu_jarrutus)

    elseif (abs(nopeus) >= abs(haluttu_nopeus) && abs(haluttu_asema-nykyinen_asema) > jarrutus_matka)
      println("ajoa")
      return suunta*abs(haluttu_nopeus)

    elseif nykyinen_asema == haluttu_asema
      println("saavutettu")
      return 0

    end
  end


end

function position_control(nykyinen_asema::Float64,haluttu_asema::Float64,alku_asema::Float64,
                          alku_aika::Float64,nyt_aika::Float64,
                          nopeus::Float64,haluttu_nopeus::Float64,haluttu_kiihtyvyys::Float64,haluttu_jarrutus::Float64)

  kulunut_matka   = abs(alku_asema - nykyinen_asema)
  koko_matka      = abs(haluttu_asema - alku_asema)
  kiihdytys_matka = abs(0.5*haluttu_kiihtyvyys*(haluttu_nopeus/haluttu_kiihtyvyys)^2)
  jarrutus_matka  = abs(0.5*haluttu_jarrutus*(nopeus/haluttu_jarrutus)^2)
  suunta          = sign(haluttu_asema - alku_asema)
  println("Kulunut matka:",kulunut_matka," mm. Koko matka:",koko_matka," mm. Kiihdytys matka:",kiihdytys_matka,"mm. Jarrutus matka:",jarrutus_matka,"mm. Suunta:",suunta)

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

function speed_profile_vaihe(nykyinen_asema::Float64,haluttu_asema::Float64,alku_asema::Float64,
                                nopeus::Float64,haluttu_nopeus::Float64,haluttu_jarrutus::Float64)

  kulunut_matka   = abs(alku_asema - nykyinen_asema)
  koko_matka      = abs(haluttu_asema - alku_asema)
  jarrutus_matka  = abs(0.5*haluttu_jarrutus*(nopeus/haluttu_jarrutus)^2)
  suunta          = sign(haluttu_asema - alku_asema)
  #todellinen_kiihtyvyys = (nykyinen_nopeus - edellinen_nopeus) / aika_askel

  if(koko_matka > 0)
    if (abs(nopeus) < abs(haluttu_nopeus) && abs(haluttu_asema-nykyinen_asema) > jarrutus_matka)
      println("kiihdytys")
      return 1

    elseif (abs(haluttu_asema-nykyinen_asema) <= jarrutus_matka && kulunut_matka < koko_matka)
      println("jarrutusta")
      return 2

    elseif (abs(nopeus) >= abs(haluttu_nopeus) && abs(haluttu_asema-nykyinen_asema) > jarrutus_matka)
      println("ajoa")
      return 3

    elseif nykyinen_asema == haluttu_asema
      println("saavutettu")
      return 0

    end
  end
end


function speed_profile_acceleration(moottori_profile::Array,vaihe,
                      aika_askel::Float64,
                      nykyinen_nopeus::Float64)
  todellinen_kiihtyvyys = (nykyinen_nopeus - moottori_profile[10]) / aika_askel
  if vaihe == 1 #kiihdytys

    println("ny: ",nykyinen_nopeus, "mm/s, ed: ",moottori_profile[10],"mm/s, ha_ki: ",abs(moottori_profile[5]),"mm/s2, tod_ki:  ",todellinen_kiihtyvyys,"mm/s2, aikaaskel: ", aika_askel)
    kiihtyvyys = pid_saadin(moottori_profile,moottori_profile[5],todellinen_kiihtyvyys,aika_askel)
    println("PID_ki: ",kiihtyvyys,"mm/s2.")
    return nykyinen_nopeus+kiihtyvyys*aika_askel

  elseif vaihe == 2 #jarrutus

    jarrutus = pid_saadin(moottori_profile,moottori_profile[6],todellinen_kiihtyvyys,aika_askel)
    return nykyinen_nopeus+jarrutus*aika_askel

  elseif vaihe == 3 #ajoa
    return pid_saadin(moottori_profile,0,todellinen_kiihtyvyys,aika_askel)
    #return nykyinen_nopeus

  elseif vaihe == 0
     return 0


  end


end
=#

function speed_profile2(moottori_profile,
                      nyt_aika::Float64, aika_askel_profil::Float64,
                      nykyinen_asema::Float64,
                      nykyinen_nopeus::Float64)

  kulunut_matka   = abs(moottori_profile[7]- nykyinen_asema)
  koko_matka      = abs(moottori_profile[3] - moottori_profile[7])
  suunta          = sign(moottori_profile[3] - moottori_profile[7])
println("Kulunut matka:",kulunut_matka," mm. Koko matka:",koko_matka," mm. Jarrutus matka: ",moottori_profile[15],"mm. Suunta:",suunta)
  if (abs(moottori_profile[3]-nykyinen_asema) <= moottori_profile[15] && kulunut_matka < koko_matka)
    println("jarrutus")
    moottori_profile[10] += moottori_profile[6]*aika_askel_profil
    moottori_profile[14] = 1.0                                                            #Jotta muu vaihe ei mene päälle, vaikka moottori jarruttaisi liian nopeasti.

  elseif (abs(moottori_profile[5]*(nyt_aika-moottori_profile[8])) < abs(moottori_profile[4]))
    println("kiihdytys")
    moottori_profile[10] += moottori_profile[5]*aika_askel_profil
    moottori_profile[15] = abs(0.5*moottori_profile[6]*(moottori_profile[10]/moottori_profile[6])^2)

  elseif (abs(moottori_profile[5]*(nyt_aika-moottori_profile[8])) >= abs(moottori_profile[4]) && moottori_profile[14] == 0.0)
    println("ajoa")
    moottori_profile[10] = moottori_profile[4]
    moottori_profile[15] = abs(0.5*moottori_profile[6]*(moottori_profile[10]/moottori_profile[6])^2)
  end

  if (koko_matka <= kulunut_matka || sign(moottori_profile[10]) != suunta)
    moottori_profile[10] = 0
  end

    println("profiili nopeus: ",moottori_profile[10],"mm/s")
    return moottori_profile[10]
end

function speed_profile3(moottori_profile,
                      nyt_aika::Float64, aika_askel_profil::Float64,
                      nykyinen_asema::Float64,
                      nykyinen_nopeus::Float64)

  kulunut_matka   = abs(moottori_profile[7]- nykyinen_asema)
  koko_matka      = abs(moottori_profile[3] - moottori_profile[7])
  suunta          = sign(moottori_profile[3] - moottori_profile[7])

#println("Kulunut matka:",kulunut_matka," mm. Koko matka:",koko_matka," mm. Jarrutus matka: ",moottori_profile[15],"mm. Suunta:",suunta)
  if ((abs(moottori_profile[3]-nykyinen_asema) <= moottori_profile[15] && kulunut_matka < koko_matka) || (abs(moottori_profile[10]) > abs(moottori_profile[4])))
    #println("jarrutus")
    moottori_profile[10] += moottori_profile[6]*aika_askel_profil
    if (abs(moottori_profile[3]-nykyinen_asema) <= moottori_profile[15])
      moottori_profile[14] = 1.0
    end                                                            #Jotta muu vaihe ei mene päälle, vaikka moottori jarruttaisi liian nopeasti.

  elseif (abs(moottori_profile[10]) < abs(moottori_profile[4]))
    #println("kiihdytys")
    moottori_profile[10] += moottori_profile[5]*aika_askel_profil
    moottori_profile[15] = abs(0.5*moottori_profile[6]*(moottori_profile[10]/moottori_profile[6])^2)

  elseif (abs(moottori_profile[10]) == abs(moottori_profile[4]) && moottori_profile[14] == 0.0)
  #  println("ajoa")
    moottori_profile[10] = moottori_profile[4]
    moottori_profile[15] = abs(0.5*moottori_profile[6]*(moottori_profile[10]/moottori_profile[6])^2)
  end

  if (koko_matka <= kulunut_matka || sign(moottori_profile[10]) != suunta)
    moottori_profile[10] = 0
  end

    #println("profiili nopeus: ",moottori_profile[10],"mm/s")
    return moottori_profile[10]
end

function speed_profile(moottori_profile,
                      nyt_aika::Float64, aika_askel_profil::Float64,
                      nykyinen_asema::Float64,
                      nykyinen_nopeus::Float64)

  kulunut_matka   = abs(moottori_profile[7]- nykyinen_asema)
  koko_matka      = abs(moottori_profile[3] - moottori_profile[7])
  suunta          = sign(moottori_profile[3] - moottori_profile[7])

#println("Kulunut matka:",kulunut_matka," mm. Koko matka:",koko_matka," mm. Jarrutus matka: ",moottori_profile[15],"mm. Suunta:",suunta)
#println(moottori_profile[10], " ",moottori_profile[3], " ",round(nykyinen_asema,2), " ",moottori_profile[4], " ",moottori_profile[5], " ",moottori_profile[6])
  if( abs(moottori_profile[3]-nykyinen_asema) > moottori_profile[15] && moottori_profile[14] == 0.0)
    #println("ajoa")
    if moottori_profile[10] < moottori_profile[4] + 0.05 && moottori_profile[10] > moottori_profile[4] - 0.05 #Jos sama nopeus kun vaadittu

      moottori_profile[10] = moottori_profile[4]

    elseif abs(moottori_profile[10]) > abs(moottori_profile[4])

      moottori_profile[10] += sign(moottori_profile[6])*abs(moottori_profile[5])*aika_askel_profil

    else
      moottori_profile[10] += moottori_profile[5]*aika_askel_profil

    end


    moottori_profile[15] = abs(0.5*moottori_profile[6]*(moottori_profile[10]/moottori_profile[6])^2)
  else
    #println("jarrutus")
    if koko_matka <= kulunut_matka
      #println("1")
          moottori_profile[10] = 0

    elseif abs(moottori_profile[10]) > 0.02
    #  println("2")
      moottori_profile[10] += abs(moottori_profile[6])*aika_askel_profil*-1*sign(moottori_profile[10])
    else
    #  println("3")
      moottori_profile[10] = 0
    end
    moottori_profile[14] = 1.0
  end
    #println("profiili nopeus: ",moottori_profile[10],"mm/s")
    return moottori_profile[10]
end

#=
function position_control_speed()
  #while Asetettu asema != Uusi asmea
  function fun_moottorin_ajo(nykyinen_asema::Float64,haluttu_asema::Float64,alku_asema::Float64,
                            alku_aika::Float64,nyt_aika::Float64,
                            nopeus::Float64,haluttu_nopeus::Float64,haluttu_kiihtyvyys::Float64,haluttu_jarrutus::Float64,
                            kierteen_nousu::Float64)

    kulunut matka=abs(uusi asema -edellinen asema)
    kulunut_matka   = abs(alku_asema - nykyinen_asema)
    edellinen asema = uusi asema
    #if(Edellinen aika == Uusi aika)
    #  Edellinen aseman=hae asema()
    #  Edellinen aika=aika()
  #else
    if(Edellinen aika < Uusi aika)
      Kulunut aika = aika_askel
      Uusi nopeus = nopeus
      uusi kiihtysyys = (Edellinen nopeus-Uusi nopeus)/kulunut aika
      Edellinen nopeus= uusi nopeus

        if (Uusi nopeus == asetettu nopeus)
          Uloskierrosnopeus = kierrosnopeus
        elseif( Uusi nopeus != asetettu nopeus)
          if(Uusikiihtyvyys == asetettu kiihtyvyys)
            kierrosnopeus=kierrosnopeus+ kierros askel*(neg/pos)
            kiihdystys kerroin=1
          #elseif (Uusikiihtyvyys > asetettu kiihtyvyys)
          #  kiihdystys kerroin=1
          elseif (Uusikiihtyvyys < asetettu kiihtyvyys)
            kierros askel=kierros askel*kiihdystys kerroin
            kierrosnopeus=kierrosnopeus + kierros askel*(neg/pos)
            kiihdystys kerroin+=1
          end
          uloskierrosnopeus = kierrosnopeus
        end


    end
    uloskierrosnopeus = kierrosnopeus
    Uusi asema=hae asema()(pituus vektorina?)
    Uusi aika= aika()
  end


end
=#
#function millimetrinopeus_kierrosnopeudeksi(nopeus::Float64,nousu::Float64)
#  return ((nopeus/nousu)*2*pi)
#end


function moottorin_nopeudenmuutos(nyt_nopeus::Float64,aika_askel::Float64,muutosnopeus::Float64)
    return abs(nyt_nopeus+(muutosnopeus*aika_askel))
end

function kierrokset_vaannoksi(Wref::Float64,Mref::Float64,w::Float64,M::Float64,tao::Float64,kytkin::Float64)
  #println("muuetaan kierrokset väännkösi")
  if kytkin == 0.0 #kierrosnoepus
    Kw=Mref/Wref
    Mmuutos = (Kw*(Wref-w) - M)/tao

  else #vääntö
    Mmuutos = (Mref-M)/ tao

  end

  return Mmuutos

end



function nollaus(nollaus_moottori::Array,moottori_PLC::Array,moottori_mevea::Array,aika::Float64,paikka_nollaus::Float64)



  if paikka_nollaus == 1.0
    nollaus_moottori[3] = moottori_PLC[6]
  end
  println()
  suunta = sign(nollaus_moottori[3] - moottori_mevea[1])
  if suunta != sign(moottori_PLC[8])
    nollaus_moottori[4] = -1*moottori_PLC[7]
    nollaus_moottori[5] = -1*moottori_PLC[8]
    nollaus_moottori[6] = -1*moottori_PLC[9]
  else
    nollaus_moottori[4] = moottori_PLC[7]
    nollaus_moottori[5] = moottori_PLC[8]
    nollaus_moottori[6] = moottori_PLC[9]
  end
  nollaus_moottori[7] = moottori_mevea[1]
  nollaus_moottori[8] = aika-0.001
  nollaus_moottori[11] = 0
  nollaus_moottori[12] = 0
  nollaus_moottori[13] = 0
  nollaus_moottori[14] = 0.0
  nollaus_moottori[15] = 0.0
end

function pid_saadin(moottori_PID,PID_haluttu::Float64,PID_nykyinen::Float64,PIDaika_askel::Float64)

  Kp = 0.2
  Ki = 0.3
  Kd = 0

  ero_PID = PID_haluttu - PID_nykyinen
  moottori_PID[11] += (ero_PID*PIDaika_askel)
  Derivaatta_PID = (ero_PID-moottori_PID[12])/PIDaika_askel
  muutos_PID = Kp*ero_PID+Ki*moottori_PID[11]+Kd*Derivaatta_PID
  moottori_PID[12] = ero_PID

  return muutos_PID
end
#=
function pid_saadin_nopeus(moottori_PID_speed,PID_haluttu_speed::Float64,PID_nykyinen_speed::Float64,PIDaika_askel_speed::Float64)

#  Kp = 0.5
#  Ki = 0.2
#  Kd = 0

  ero_speed = PID_haluttu_speed - PID_nykyinen_speed
  ero_muutos_speed = (ero_speed-moottori_PID_speed[12])
  nopeus_speed = moottori_PID_speed[9] + Kp*ero_muutos_speed + Ki*ero_speed*PIDaika_askel_speed + Kd*((ero_speed - 2*moottori_PID_speed[12] + moottori_PID_speed[13])/PIDaika_askel_speed)
  moottori_PID_speed[13] = moottori_PID_speed[12]
  moottori_PID_speed[12] = ero_speed

  return nopeus_speed
end
=#
