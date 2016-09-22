include("moottorien_ajo.jl")

function plc_mevea_connection()
  println("Waiting for connection")
  server_mevea = listen(5112) # Avataan Modelerissa asetettu portti #listen(ip"127.0.0.1",2000)
  server_plc = listen(5003)

  conn_mevea = accept(server_mevea)
  conn_plc = accept(server_plc)


  moottorien_ruuvien_nousut = [10,20,20,10,20,10,10,10,0,10,10,20,10,10]        #Kuularuuvin nousu
  #moottorien_niemmelisvääntö = [7.3,26.0,26.0,7.3,26.0,7.3,7.3,7.3,7.3,7.3,7.3,26.0,7.3,7.3]    #moottorin nimellisvääntö
  moottorien_max_kierrosnopeus = [502 397 397 502 397 502 502 502 502 502 502 397 502 502]
  moottorien_maara = length(moottorien_ruuvien_nousut)

  #Mevea moottorien tiedon määrä
  mevea_rivi = 2

  Tao = 0.01 #Moottoin reaktio nopeus Time Constant
  Aika_askel = 0.001
  Edellinen_aika = 0
  Driker = 0.0
  ninputs_plc = moottorien_maara*10
  noutputs_plc = 4*moottorien_maara

  ninputs_mevea = moottorien_maara*mevea_rivi+1           # Mevea solverista tulevat outputit #Lisätään simulaation aika
  noutputs_mevea = 2                                      # Mevea solveriin menevät inputit

  #Mevea yhteyden tarkastaminen
  params=Array{Int32}(3)
  params2=Array{Int32}(3)
  params[1]=1
  params[2]=noutputs_mevea
  params[3]=ninputs_mevea
  params2 = read(conn_mevea,Int32,3) #Tarksitetaan että Ratkaisiassa ja Juliassa on sama määrä out-ja inputteja.

  write(conn_mevea,params)

  ins_mevea=zeros(ninputs_mevea)
  outs_mevea=zeros(noutputs_mevea)

  ins_plc=zeros(ninputs_plc)

  moottorit = zeros(13,moottorien_maara)
  moottorit[1,:] = moottorien_ruuvien_nousut
  moottorit[2,:] = moottorien_max_kierrosnopeus
  #Moottorit tiedot:
      # 1. Ruuvin nousu                       [mm]
      # 2. Moottorein maksimi kierrosnopeus   [Nm]
      # 3. Haluttu asema                      [mm]
      # 4. Nopeusprofiilin nopeus             [mm/s]
      # 5. Nopeusprofiilin kiihdytys          [mm/s^2]
      # 6. Nopeusprofiilin jarrutus           [mm/s^2]
      # 7. Lähtöasema                         [mm]
      # 8. Lähtöaika                          [s]
      # 9. Mottorin edellinen nopeus          [rad/s]
      # 10.Profiilin nopeus                   [mm/s]
      # 11.PIDintegral
      # 12.PIDerror_prior
      # 13.Edellinwen PIDerror

  # Moottorien järjestys:
      # 1. Stepfeeder carriage
      # 2. Linearfeeder carriage
      # 3. X-carriage L
      # 4. Y-carriage L
      # 5. X-carriage R
      # 6. Y-carriage R
      # 7. Charger spindle L
      # 8. Charger spindle R
      # 9. Charger shaft L
      # 10.Clamp L
      # 11.Clamp R
      # 12.ArmSlider R
      # 13.Lathe spindle L
      # 14.Lathe spindle R


  println("Connection established")
  while isopen(conn_mevea) #Kommunikointi

    try
      ins_plc = round(read(conn_plc,Float64,ninputs_plc),3)
      ins_mevea = round(read(conn_mevea,Float64,ninputs_mevea),3)
      #PLC
      #DI 1.Execute         [0/1]        = Onko moottorille annettu liikkelle käskyä
      #DI 2.Reserve         [0/1]        = Tyhjä
      #DI 3.Torque          [0/1]        = Jos 0, nii lukee 4 rivin tiedot. Jos 1, niin moottori muuttuu torque säätöiseksi. Tämä vaikka kesken ajon
      #DI 4.SpeedControl    [0/1]        = Jos 0, nii on paikkasäätöinen. Jos 1, niin on nopeus säätöinen.
      #DI 5.Enable          [0/1]        = Onko moottori päällä

      #AI 6.TargetPos       [mm]         = Haluttu asema
      #AI 7.TargetSpeed     [mm/s]       = Haluttu nopeus. Lähetetään aina
      #AI 8.TargetAcc       [mm/s2]      = Haluttu kiihdytysnopeus
      #AI 9.TargetDec       [mm/s2]      = Haluttu jarrutusnopeus
      #AI 10.TargetTorque   [Nm]         = Haluttu vääntö

      #DO 1.InPosition      [0/1]        = Onko asemassa
      #DO 2.Enable          [0/1]        = Onko moottori käytössä

      #AO 3.ActualPos       [mm]         = Moottorin asema
      #AO 4.ActualSpeed     [mm/s]       = Moottorin nopeus

      #Mevea

      #AI 1.Motor_position  [mm]         = Voimakomponentin pituus
      #AI 2.Motor_speed     [mm/s]       = Voimakomponentin nopeus
      #AI 3.Simulation time [s]          = Simuloinnissa juokseva aika

      # Vanha versio #AO 1.Motor_speed   [rad/s]      = Moottorin kierrosnopeus
      #AO 1. Motor_torque   [Nm]         = Moottorin vääntö
      aika_askel = ins_mevea[end] - Edellinen_aika
      if aika_askel >= Tao
        ins_matrix_PLC=reshape(ins_plc[1:20],10,2)    #PLC:ltä tulevat yhteydet
        ins_matrix_Mevea=reshape(round(ins_mevea[1:(length(ins_mevea)-1)],1),mevea_rivi,14)
        paalla=find(ins_matrix_PLC[5,:])        #Onko moottori paalla. Antaa luettelon mitkä moottorit ovat päällä
        #println(paalla)

        for moottori_id in paalla  #käy jokaisen päällä olevan moottorin läpi
          moottori = moottorit[:,moottori_id]
          println("moottori ", moottori_id, " on päällä. Tiedot:",ins_matrix_Mevea[1,moottori_id], "mm, ",ins_matrix_Mevea[2,moottori_id],"mm/s")
        #=  if(ins_matrix_PLC[3,moottori] == 1.0)   #Moottorilla on vääntösäätö päällä
             outs_mevea[1,moottori] = 0 #Vääntösäätö ei ole vielä mahdollista


          elseif(ins_matrix_PLC[3,moottori] == 0 && ins_matrix_PLC[4,moottori] == 1) #Nopeusäätöinen moottori
            if(ins_matrix_PLC[1,moottori] == 1)
              dire = sign(ins_matrix_PLC[7,moottori])

              if ins_matrix_Mevea[2,moottori] == ins_matrix_PLC[7,moottori] #Jos sama nopeus kun vaadittu
                outs_mevea[1,moottori] = dire*millimetri_kierrosnopeudeksi(ins_matrix_PLC[7,moottori],moottorit[1,moottori]) #Lähetetään sama kierrosnopeus takas

              elseif abs(ins_matrix_Mevea[2,moottori]) < abs(ins_matrix_PLC[7,moottori])
                outs_mevea[1,moottoir] = dire*millimetri_kierrosnopeudeksi(moottorin_nopeudenmuutos(ins_matrix_Mevea[2,moottori],aika_askel,ins_matrix_PLC[8,moottori]),moottorit[1,moottori])
              end
            else
              dire = sign(ins_matrix_PLC[9,moottori])
              outs_mevea[1,moottori] = dire*millimetri_kierrosnopeudeksi(moottorin_nopeudenmuutos(ins_matrix_Mevea[2,moottori],aika_askel,ins_matrix_PLC[9,moottori]),moottorit[1,moottori]) # lähetetään jarrutus kierrosnopeus takaisin
            end

            #Muutetaan kierrokset väännöksi
            outs_mevea[1,moottori] = kierrokset_vaannoksi(millimetri_kierrosnopeudeksi(ins_matrix_PLC[7,moottori],moottorit[1,moottori]),moottorit[2,moottori],outs_mevea[1,moottori],ins_matrix_Mevea[3,moottori],Tao,0.0)

    else=#if(ins_matrix_PLC[3,moottori_id] == 0 && ins_matrix_PLC[4,moottori_id] == 0) #Paikkasäätöinen
            println("paikkasäätö")
            Driker_muutos = ins_matrix_PLC[1,moottori_id] - Driker #Tätä käyetään simuloimaan signaalin nousevaa jalkaa
            #Otetaan alkutilanteen tiedot ylös ajoa varten. Tämä resetoituu aina kun execute on 1 tai moottori on mennyt yli aseman, jolloin se pyrkii menemään samaan asemaan uudestaan.
            if((ins_matrix_PLC[1,moottori_id] == 1 && Driker_muutos == 1.0)  || ( abs(ins_matrix_PLC[6,moottori_id] - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])) < 0)
              println("alustetaan lähtöä arvoilla: ","Haluttu arvot:",ins_matrix_PLC[6,moottori_id],"mm ",ins_matrix_PLC[7,moottori_id],"mm/s ",ins_matrix_PLC[8,moottori_id],"mm/s2 ",ins_matrix_PLC[9,moottori_id],"mm/s2. Lähtöarvot:",ins_matrix_Mevea[1,moottori_id],"mm ",ins_mevea[end]-0.001,"s." )
              println(moottori)
              suunta = sign(ins_matrix_PLC[6,moottori_id] - ins_matrix_Mevea[1,moottori_id])
              if suunta != sign(ins_matrix_PLC[7,moottori_id])
                moottori[4] = -1*ins_matrix_PLC[7,moottori_id]
                moottori[5] = -1*ins_matrix_PLC[8,moottori_id]
                moottori[6] = -1*ins_matrix_PLC[9,moottori_id]
              else
                moottori[4] = ins_matrix_PLC[7,moottori_id]
                moottori[5] = ins_matrix_PLC[8,moottori_id]
                moottori[6] = ins_matrix_PLC[9,moottori_id]
              end
                moottori[3] = ins_matrix_PLC[6,moottori_id]
                moottori[7] = ins_matrix_Mevea[1,moottori_id]
                moottori[8] = ins_mevea[end]-0.001
            end
            println(moottori)
            Driker = ins_matrix_PLC[1,moottori_id]
            #Resetoidaan alku_aika jarrutusta varten, jotta jarrutus pystyy aikasuhteelisena. Käytetään samaa muuttujaa, koska halutaan välttää globaaleja muuttujia.
            #Ehto lause on sama kuin position_control function jarrutuksessa.
            #if (abs(moottori[3]-ins_matrix_Mevea[1,moottori_id]) <= abs(0.5*moottori[6,moottori_id]*(ins_matrix_Mevea[2,moottori_id]/moottori[6])^2))
            #    moottori[8] = ins_mevea[end]-0.001
            #    moottori[4] = 0
          #  end
                                                    #(nykyinen_asema::Float64,haluttu_asema::Float64,alku_asema::Float64,alku_aika::Float64,nyt_aika::Float64,nopeus::Float64,haluttu_nopeus::Float64,haluttu_kiihtyvyys::Float64,haluttu_jarrutus::Float64)
            #outs_mevea[1,moottori] =  position_control_timestep(ins_matrix_Mevea[1,moottori],moottorit[3,moottori],moottorit[7,moottori],moottorit[8,moottori],ins_mevea[end],aika_askel,ins_matrix_Mevea[2,moottori],moottorit[4,moottori],moottorit[5,moottori],moottorit[6,moottori])
            #outs_mevea[1,moottori] =  position_control(ins_matrix_Mevea[1,moottori],moottorit[3,moottori],moottorit[7,moottori],moottorit[8,moottori],ins_mevea[end],ins_matrix_Mevea[2,moottori],moottorit[4,moottori],moottorit[5,moottori],moottorit[6,moottori])
            println("määritetään nopeus")

            outs_mevea[1],outs_mevea[2] = speed_profile(moottori,
                                  ins_mevea[end], aika_askel,
                                  ins_matrix_Mevea[1,moottori_id],
                                  ins_matrix_Mevea[2,moottori_id])

            println("nopeus: ",outs_mevea[1,moottori_id],"mm/s. Kierrosnpeus:  ", millimetrinopeus_kierrosnopeudeksi(outs_mevea[1,moottori_id],moottori[1]),"rad/s")
            outs_mevea[1] = millimetrinopeus_kierrosnopeudeksi(outs_mevea[1],moottori[1])
            outs_mevea[2] = millimetrinopeus_kierrosnopeudeksi(outs_mevea[2],moottori[1])
            moottori[9] = ins_matrix_Mevea[2,moottori_id]
            #moottori[10] = ins_matrix_Mevea[2,moottori_id]
            moottorit[:,moottori_id] = moottori
          end
        end
        Edellinen_aika = ins_mevea[end]
        println("lähetetään mevealle: ", outs_mevea)
      end
      write(conn_mevea,outs_mevea)
    catch e
      println("caught an error $e")
      break
    end
  end

  println("Connection closed")
  close(conn_mevea)
  close(server_mevea)
  close(conn_plc)
  close(server_plc)
end
