

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

function pyorimsmatka(haluttu_kulma::Float64,nykyinen_kulmamatka::Float64,keha::Float64)

  n_kierrosta = round(((nykyinen_kulmamatka)/keha)-(((nykyinen_kulmamatka)%keha)/keha))

  matka = zeros(2)
  haluttu_matka = zeros(2)
  haluttu_matka[1] = n_kierrosta*keha + (haluttu_kulma/360)*keha
  haluttu_matka[2] = (n_kierrosta + 1)*keha + (haluttu_kulma/360)*keha
  #haluttu_matka[3] = (n_kierrosta - 1)*360 + haluttu_kulma


  matka[1] = nykyinen_kulmamatka - haluttu_matka[1]
  matka[2] = nykyinen_kulmamatka - haluttu_matka[2]
  #matka[3] = nykyinen_kulmamatka - haluttu_matka[3]




  return haluttu_matka[findmin(abs(matka))[2]]
end
