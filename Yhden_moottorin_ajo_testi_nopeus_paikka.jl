include("moottorien_ajo.jl")
include("ajo_ohjeet.jl")

function plc_mevea_connection()
  println("Waiting for connection")
  server_mevea = listen(5112) # Avataan Modelerissa asetettu portti #listen(ip"127.0.0.1",2000)
  server_plc = listen(5003)

  conn_mevea = accept(server_mevea)
  conn_plc = accept(server_plc)


  #moottorien_ruuvien_nousut = [10,20,20,10,20,10,10,10,(2*pi*30)/50,10,10,20,10,10]        #Kuularuuvin nousu
  #moottorien_max_kierrosnopeus = [502 397 397 502 397 502 502 502 502 502 502 397 502 502]
  moottorien_maara = 14
  antureiden_maara = 4
  venttiilien_maara = 2

  #Mevea moottorien tiedon määrä
  mevea_rivi = 2

  ninputs_plc = (moottorien_maara + 1)*10
  noutputs_plc = moottorien_maara + 1

  ninputs_mevea = moottorien_maara*mevea_rivi + 1 + antureiden_maara         # Mevea solverista tulevat outputit #Lisätään simulaation aika
  noutputs_mevea = moottorien_maara*2 + 1                         # Mevea solveriin menevät inputit

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
  outs_plc=zeros(4,noutputs_plc)

  Tao = 0.005 #Moottoin reaktio nopeus Time Constant
  Aika_askel = 0.001
  Edellinen_aika = 0
  Driker = 0.0
  alusta = 0.0
  PID_saadin = 1.0

  pyorivat_moottorit = [9]

  moottorit = zeros(19,moottorien_maara)
  #moottorit[1,:] = moottorien_ruuvien_nousut
  #moottorit[2,:] = moottorien_max_kierrosnopeus
  #Moottorit tiedot:
      # 1. Ruuvin nousu                       [mm]
      # 2. Nopeus vai paikkas                 [0/1]
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
      # 13.PID lisä
      # 14.Jarrutus                          [0/1]
      # 15.Jarrutus matka                    [mm]
      # 16.Driker                            [0/1]



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
      # 12.ArmSlider
      # 13.Lathe spindle L
      # 14.Lathe spindle R


  println("Connection established")
  while isopen(conn_mevea) #Kommunikointi

    try
      ins_plc = round(read(conn_plc,Float64,ninputs_plc),4)
      ins_mevea = round(read(conn_mevea,Float64,ninputs_mevea),4)

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
      #println(ins_mevea[end])
      if ins_mevea[end] < 2.0
        alusta = 1.0
      end

      if aika_askel >= Tao
        ins_matrix_PLC = reshape(ins_plc[1:moottorien_maara*10],10,moottorien_maara)    #PLC:ltä tulevat yhteydet
        ins_matrix_Mevea = reshape(ins_mevea[1:(mevea_rivi*moottorien_maara)],mevea_rivi,moottorien_maara)
        paalla = find(ins_matrix_PLC[5,:])        #Onko moottori paalla. Antaa luettelon mitkä moottorit ovat päällä
        liikkeessa = filter(e->e∉paalla,find(ins_matrix_Mevea[2,:])) #Mottorrt jotka liikkuvat mutta eivät kuuluisi liikkua.
        outs_plc[2,1:moottorien_maara] = ins_matrix_PLC[5,1:moottorien_maara]
        #println(ins_matrix_PLC[1,:])

        if alusta == 1.0      #Alustetaan moottotreille lähtöasema
          #println("alustetaan")
          moottorit[7,:] = ins_matrix_Mevea[1,:]
          alusta =0.0
        end

       for moottori_id in paalla  #käy jokaisen päällä olevan moottorin läpi
          moottori = moottorit[:,moottori_id]
          Driker_muutos = ins_matrix_PLC[1,moottori_id] - moottori[16] #Tätä käyetään simuloimaan signaalin nousevaa jalkaa
          Asetusmuutoos_muutos = ins_matrix_PLC[4,moottori_id] - moottori[2]
          moottori[16] = ins_matrix_PLC[1,moottori_id]
          moottori[2] = ins_matrix_PLC[4,moottori_id]
          #println("moottori ", moottori_id, " on päällä. Tiedot:",ins_matrix_Mevea[1,moottori_id], "mm, ",ins_matrix_Mevea[2,moottori_id],"mm/s")
          if(ins_matrix_PLC[3,moottori_id] == 1.0)   #Moottorilla on vääntösäätö päällä
             outs_mevea[(moottori_id*2)-1] = 0 #Vääntösäätö ei ole vielä mahdollista
             outs_mevea[moottori_id*2] = 0 #Vääntösäätö ei ole vielä mahdollista

          elseif(ins_matrix_PLC[3,moottori_id] == 0 && ins_matrix_PLC[4,moottori_id] == 1) #Nopeusäätöinen moottori
            #println("nopeus säätö")
            if(ins_matrix_PLC[1,moottori_id] == 1.0)
              if Driker_muutos == 1.0 || Asetusmuutoos_muutos == 1.0
                #println("alustetaan")
                moottori[9] = moottori[10]
                #moottori[9] = millimetrinopeus_kierrosnopeudeksi(moottori[10],moottori[1])
                #moottori[10] = ins_matrix_Mevea[2,moottori_id]
                moottori[11] = 0.0
                moottori[12] = 0.0
                moottori[13] = 0.0
                moottori[14] = 0.0
              end

              if moottori[10] == ins_matrix_PLC[7,moottori_id] #Jos sama nopeus kun vaadittu

                moottori[10] = ins_matrix_PLC[7,moottori_id]

              elseif moottori[10] < ins_matrix_PLC[7,moottori_id]

                moottori[10] += abs(ins_matrix_PLC[8,moottori_id])*aika_askel

              elseif moottori[10] > ins_matrix_PLC[7,moottori_id]

                moottori[10] += abs(ins_matrix_PLC[9,moottori_id])*aika_askel*-1

              end
            else

              if abs(moottori[10]) > 0.05
                moottori[10] += abs(ins_matrix_PLC[9,moottori_id])*aika_askel*-1*sign(moottori[10])
              else
                moottori[10] = 0
              end

            end


            if   PID_saadin == 1
              moottori[13] += pid_saadin(moottori,moottori[9],ins_matrix_Mevea[2,moottori_id],aika_askel)
              #moottori[13] += pid_saadin(moottori,moottori[9],millimetrinopeus_kierrosnopeudeksi(ins_matrix_Mevea[2,moottori_id],moottori[1]),aika_askel)

              if abs(moottori[13]) > 50.0 && 0 == findfirst(pyorivat_moottorit,moottori_id)
              #  println("Pysähtynyt")
                moottori[10] = 0
                nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],0.0)
              end

              moottori[9] = moottori[10]
              #moottori[9] = millimetrinopeus_kierrosnopeudeksi(moottori[10],moottori[1])
              if moottori[9] == 0 || moottori[10] == 0
                moottori[11] = 0
                moottori[12] = 0
                moottori[13] = 0
              end
              outs_mevea[(moottori_id*2)-1] = moottori[9] + moottori[13]
            else
              moottori[9] = moottori[10]
              #moottori[9] = millimetrinopeus_kierrosnopeudeksi(moottori[10],moottori[1])
              outs_mevea[(moottori_id*2)-1] = moottori[9]

            end
            outs_mevea[moottori_id*2] = outs_mevea[(moottori_id*2)-1]


          elseif(ins_matrix_PLC[3,moottori_id] == 0 && ins_matrix_PLC[4,moottori_id] == 0) #Paikkasäätöinen

            #println("paikkasäätö")
            #Otetaan alkutilanteen tiedot ylös ajoa varten. Tämä resetoituu aina kun execute on 1 tai moottori on mennyt yli aseman, jolloin se pyrkii menemään samaan asemaan uudestaan.
            #println("Matka - kuljettu: ",(abs(moottori[3]  - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])), "mm. PID Interger: ",moottori[13],". PID ero: ",moottori[12],"muutos: ",Driker_muutos)
            if Driker_muutos == 1.0 || Asetusmuutoos_muutos == -1.0
            #if(ins_matrix_PLC[1,moottori_id] == 1 && Driker_muutos == 1.0)
            #  println("alustetaan lähtöä arvoilla: ","Haluttu arvot:",ins_matrix_PLC[6,moottori_id],"mm ",ins_matrix_PLC[7,moottori_id],"mm/s ",ins_matrix_PLC[8,moottori_id],"mm/s2 ",ins_matrix_PLC[9,moottori_id],"mm/s2. Lähtöarvot:",ins_matrix_Mevea[1,moottori_id],"mm ",ins_mevea[end]-0.001,"s." )
            #  println(moottori)
            #  println("asento alustetaan")
              nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],1.0)

            elseif (abs(moottori[3] - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])) < -0.1
            #  println("yli")
              moottori[10] = 0.0
              nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],0.0)
            end

            #println("määritetään nopeus")

            #outs_mevea[1],outs_mevea[2] = speed_profile(moottori,
            #                      ins_mevea[end], aika_askel,
            ##                      ins_matrix_Mevea[1,moottori_id],
            #                      ins_matrix_Mevea[2,moottori_id])
            #
            #println("nopeus: ",outs_mevea[1,moottori_id],"mm/s. Kierrosnpeus:  ", millimetrinopeus_kierrosnopeudeksi(outs_mevea[1,moottori_id],moottori[1]),"rad/s")
            #outs_mevea[2] = millimetrinopeus_kierrosnopeudeksi(outs_mevea[2],moottori[2])
            #outs_mevea[1] = millimetrinopeus_kierrosnopeudeksi(outs_mevea[1],moottori[1])
            #outs_mevea[1] = 25
            #moottori[9] = ins_matrix_Mevea[2,moottori_id]
            #moottori[10] = ins_matrix_Mevea[2,moottori_id]
            #moottorit[:,moottori_id] = moottori
            #println(round((ins_mevea[end]-moottori[8])/Tao))

            #moottori[13] += pid_saadin(moottori,moottori[9],millimetrinopeus_kierrosnopeudeksi(ins_matrix_Mevea[2,moottori_id],moottori[1]),aika_askel)


            #println("Lisä: ",moottori[13]," edellelinen haluttu: ",moottori[9],"rad/s. Saavutettu: ",millimetrinopeus_kierrosnopeudeksi(ins_matrix_Mevea[2,moottori_id],moottori[1]),"rad/s. aika_askel: ",aika_askel,"s. Aika: ",ins_mevea[end])
            if   PID_saadin == 1
              moottori[13] += pid_saadin(moottori,moottori[9],ins_matrix_Mevea[2,moottori_id],aika_askel)
              #moottori[13] += pid_saadin(moottori,moottori[9],millimetrinopeus_kierrosnopeudeksi(ins_matrix_Mevea[2,moottori_id],moottori[1]),aika_askel)

              if abs(moottori[13]) > 50.0 && 0 == findfirst(pyorivat_moottorit,moottori_id)
                #println("Pysähtynyt")
                moottori[10] = 0
                ins_matrix_PLC[6,moottori_id] = ins_matrix_Mevea[1,moottori_id]
                nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],1.0)
              end

              moottori[9] = speed_profile(moottori,ins_mevea[end],aika_askel,ins_matrix_Mevea[1,moottori_id],ins_matrix_Mevea[2,moottori_id])
              #moottori[9] = millimetrinopeus_kierrosnopeudeksi(speed_profile(moottori,ins_mevea[end],aika_askel,ins_matrix_Mevea[1,moottori_id],ins_matrix_Mevea[2,moottori_id]),moottori[1])
              if moottori[9] == 0 || moottori[10] == 0
                moottori[11] = 0
                moottori[12] = 0
                moottori[13] = 0
              end
              outs_mevea[(moottori_id*2)-1] = moottori[9] + moottori[13]
            else

              moottori[9] = speed_profile(moottori,ins_mevea[end],aika_askel,ins_matrix_Mevea[1,moottori_id],ins_matrix_Mevea[2,moottori_id])
              #moottori[9] = millimetrinopeus_kierrosnopeudeksi(speed_profile(moottori,ins_mevea[end],aika_askel,ins_matrix_Mevea[1,moottori_id],ins_matrix_Mevea[2,moottori_id]),moottori[1])
              outs_mevea[(moottori_id*2)-1] = moottori[9]

            end

            outs_mevea[moottori_id*2] = outs_mevea[(moottori_id*2)-1]
          end

          if abs(moottori[3] - ins_matrix_Mevea[1,moottori_id]) < 0.1
            outs_plc[1,moottori_id] = 1
          else
            outs_plc[1,moottori_id] = 0
          end
          outs_plc[3,moottori_id] = ins_matrix_Mevea[1,moottori_id]
          outs_plc[4,moottori_id] = ins_matrix_Mevea[2,moottori_id]

          moottorit[:,moottori_id] = moottori
        end #For end
        Edellinen_aika = ins_mevea[end]

        for moottori_liike in liikkeessa

          outs_mevea[(moottori_liike*2)-1] = 0
          outs_mevea[(moottori_liike*2)] = outs_mevea[(moottori_liike*2)-1]

        end
        #println("lähetetään mevealle: ", outs_mevea)
        #println("lähetetään plc: ", outs_plc)
      end #aika loppu

      #Outs_plc on 4*(moottorien_maara+1) matriisi
      outs_plc[1,moottorien_maara+1] = ins_mevea[(2*moottorien_maara)+1]
      outs_plc[2,moottorien_maara+1] = ins_mevea[(2*moottorien_maara)+2]
      outs_plc[3,moottorien_maara+1] = ins_mevea[(2*moottorien_maara)+3]
      outs_plc[4,moottorien_maara+1] = ins_mevea[(2*moottorien_maara)+4]

      #Venttiilien ohjaus
      if ins_plc[10*moottorien_maara + 1] == 1
        outs_mevea[moottorien_maara*2 + 1] = 1
      elseif ins_plc[10*moottorien_maara+2] == 1
        outs_mevea[moottorien_maara*2 + 1] = -1
      else
        outs_mevea[moottorien_maara*2 + 1] = 0
      end
      #println("lähetetään plc: ", outs_plc[1,:])
      #println("lähetetään mevea: ", outs_mevea[moottorien_maara*2 + 1])
      #write(conn_plc,outs_plc)
      write(conn_mevea,outs_mevea)
    catch ex
      println("caught an error $ex")
      break
    end
  end

  println("Connection closed")
  close(conn_mevea)
  close(server_mevea)
  close(conn_plc)
  close(server_plc)
end
