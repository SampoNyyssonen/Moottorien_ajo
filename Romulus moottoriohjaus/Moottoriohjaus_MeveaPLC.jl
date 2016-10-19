include("moottorien_ajo_funktiot.jl")

function plc_mevea_connection()
  println("Waiting for connection")
  server_mevea = listen(5112)                                                   # Avataan Modelerissa asetettu portti #listen(ip"127.0.0.1",2000)
  server_plc = listen(5003)                                                     # Avataan plcn yhteys.

  conn_mevea = accept(server_mevea)
  conn_plc = accept(server_plc)


  moottorien_maara = 14                                                         #Tämä on määrä moottoreista jota ohjataan tämän ohjaimen avulla.
  antureiden_maara = 4                                                          # 2 * onko pölli asemassa ja 2 * kuinka paksu pölli on
  venttiilien_maara = 2

  #Mevea moottorien tiedon määrä: paikka ja nopeus
  mevea_rivi = 2

  ninputs_plc = (moottorien_maara + 1)*10                                       # PLC:n lähettämä datan määrä. Moottorit + venttiilin ohjaus. Viimeisessä matriisi sarakkeessa on venttiili ohjaus
  noutputs_plc = moottorien_maara + antureiden_maara/4                          #Kuinka monta saraketta PLClle lähetetään. Moottorit + anturit.

  ninputs_mevea = moottorien_maara*mevea_rivi + 1 + antureiden_maara            # Mevea solverista tulevat outputit #Lisätään simulaation aika
  noutputs_mevea = moottorien_maara*2 + 1                                       # Mevea solveriin menevät inputit

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
  outs_plc=zeros(4,convert(Int64,noutputs_plc))

  Tao = 0.005 #Moottoin reaktio nopeus Time Constant
  Aika_askel = 0.001
  Edellinen_aika = 0
  Driker = 0.0
  alusta = 0.0
  PID_saadin = 1.0 # Jos PID säädin on päällä, on arvo 1, muuten 0.

  pyorivat_moottorit = [9] #Mitkä moottorit ovat pyöriviä
  pyorivan_moottorin_kehapituus = 2*pi*30 # Pyörivän moottorin kehapituus

  moottorit = zeros(16,moottorien_maara) #Jokaisesta moottorista talletetaan 16 tietoa.
  #Moottorit tiedot:
      # 1. Korjaus liikkeiden määrä
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

  println("Connection established") #Odotetaan Mevean reaktiota
  while isopen(conn_mevea) #Kommunikointi

    try
      ins_plc = round(read(conn_plc,Float64,ninputs_plc),2) #Haetaan PLCn arvot
      ins_mevea = round(read(conn_mevea,Float64,ninputs_mevea),3) #Haetaan Mevean arvot

      #PLC moottorit
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

      #PLClle lähetetään moottorista
      #DO 1.InPosition      [0/1]        = Onko asemassa
      #DO 2.Enable          [0/1]        = Onko moottori käytössä

      #AO 3.ActualPos       [mm]         = Moottorin asema
      #AO 4.ActualSpeed     [mm/s]       = Moottorin nopeus

      #Mevea

      #AI 1.Motor_position  [mm]         = Voimakomponentin pituus
      #AI 2.Motor_speed     [mm/s]       = Voimakomponentin nopeus

      #AI 3.Simulation time [s]          = Simuloinnissa juokseva aika


      aika_askel = ins_mevea[end] - Edellinen_aika # Lasketaan aika_askelta
      #println(ins_mevea[end]) # aika
      if ins_mevea[end] < 2.0 #Asetetaan aloitus asemat niiksi mihin kappaleet ovat asettuneet.
        alusta = 1.0
      end

      if aika_askel >= Tao # Joka 0.005 ohjataan moottoria.
        ins_matrix_PLC = reshape(ins_plc[1:moottorien_maara*10],10,moottorien_maara)                        #PLC:ltä tulevat moottoriohjausarvot muutetaan matriisiksi
        ins_matrix_Mevea = reshape(ins_mevea[1:(mevea_rivi*moottorien_maara)],mevea_rivi,moottorien_maara)  #Mevean moottoriarvot muutetaan matriisiksi
        paalla = find(ins_matrix_PLC[5,:])                                                                  #Onko moottori paalla. Antaa luettelon mitkä moottorit ovat päällä
        liikkeessa = filter(e->e∉paalla,find(ins_matrix_Mevea[2,:]))                                        #Mottorrt jotka liikkuvat mutta eivät kuuluisi liikkua.
        outs_plc[2,1:moottorien_maara] = ins_matrix_PLC[5,1:moottorien_maara]                               #Lähetetään PLClle takaisin päällä olevat moottorit
        #println(ins_matrix_PLC[1,:])

        if alusta == 1.0      #Alustetaan moottotreille lähtöasema
          #println("alustetaan")
          moottorit[7,:] = ins_matrix_Mevea[1,:] #Asetataan asema aloitukseksi
          outs_plc[3,1:moottorien_maara] = ins_matrix_Mevea[1,1:moottorien_maara]   #lähetään plclle moottorien asema
          alusta =0.0
        end

       for moottori_id in paalla  #käy jokaisen päällä olevan moottorin läpi
          moottori = moottorit[:,moottori_id] #Otetaan jokainen moottori erikseen käsittelyyn

          #pyöriville moottotreille
          Driker_muutos = ins_matrix_PLC[1,moottori_id] - moottori[16]          #Tätä käyetään simuloimaan signaalin nousevaa jalkaa
          Asetusmuutoos_muutos = ins_matrix_PLC[4,moottori_id] - moottori[2]    #aseman ja nopeuden välinen trikkeri
          moottori[16] = ins_matrix_PLC[1,moottori_id]                          #Asema trikkerin tulos
          moottori[2] = ins_matrix_PLC[4,moottori_id]                           #Nopeus ja paikka trikkerin talletus
          #println("moottori ", moottori_id, " on päällä. Tiedot:",ins_matrix_Mevea[1,moottori_id], "mm, ",ins_matrix_Mevea[2,moottori_id],"mm/s")
          if(ins_matrix_PLC[3,moottori_id] == 1.0)   #Moottorilla on vääntösäätö päällä
             outs_mevea[(moottori_id*2)-1] = 0 #Vääntösäätö ei ole vielä mahdollista
             outs_mevea[moottori_id*2] = 0 #Vääntösäätö ei ole vielä mahdollista

          elseif(ins_matrix_PLC[3,moottori_id] == 0 && ins_matrix_PLC[4,moottori_id] == 1) #Nopeusäätöinen moottori
            #println("nopeus säätö")
            if(ins_matrix_PLC[1,moottori_id] == 1.0) #Jos trikkeri on 1 ajetaan
              if Driker_muutos == 1.0 || Asetusmuutoos_muutos == 1.0 #Oettaan kiinni siitä nopeudesta mihin on viimeksi jääty.
                #println("alustetaan")
                moottori[9] = moottori[10]
                moottori[11] = 0.0
                moottori[12] = 0.0
                moottori[13] = 0.0
                moottori[14] = 0.0
              end
              #Nopeus ohjaus
              if moottori[10] == ins_matrix_PLC[7,moottori_id]

                moottori[10] = ins_matrix_PLC[7,moottori_id]

              elseif moottori[10] < ins_matrix_PLC[7,moottori_id]

                moottori[10] += abs(ins_matrix_PLC[8,moottori_id])*aika_askel

              elseif moottori[10] > ins_matrix_PLC[7,moottori_id]

                moottori[10] += abs(ins_matrix_PLC[9,moottori_id])*aika_askel*-1

              end
            else # Jos trikkeri on nolla, niin jarrutetaan

              if abs(moottori[10]) > 0.05
                moottori[10] += abs(ins_matrix_PLC[9,moottori_id])*aika_askel*-1*sign(moottori[10])
              else
                moottori[10] = 0
              end

            end


            if   PID_saadin == 1 #PID säädin nopeudelle.
              moottori[13] += pid_saadin(moottori,moottori[9],ins_matrix_Mevea[2,moottori_id],aika_askel) # Lisätty nopeus määrä jotta moottori pysyy nopeudessa

              if abs(moottori[13]) > 50.0 && 0 == findfirst(pyorivat_moottorit,moottori_id) # Jos lisätty nopeus alkaa olemaan liian suuri tai moottori on pyörivä.
              #  println("Pysähtynyt")
                moottori[10] = 0
                nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],0.0) # Nollataan kaikki.
              end

              moottori[9] = moottori[10]
              if moottori[9] == 0 || moottori[10] == 0 # Jos haluttu pyörimisnopeus on 0, niin PID säädin asetetaan myös nollaksi.
                moottori[11] = 0
                moottori[12] = 0
                moottori[13] = 0
              end
              outs_mevea[(moottori_id*2)-1] = moottori[9] + moottori[13]
            else #Jos PID säädin ei ole päällä
              moottori[9] = moottori[10]
              outs_mevea[(moottori_id*2)-1] = moottori[9] #Moottrin ohjausarvo

            end
            outs_mevea[moottori_id*2] = outs_mevea[(moottori_id*2)-1] #Jarrulle ohjausarvo


          elseif(ins_matrix_PLC[3,moottori_id] == 0 && ins_matrix_PLC[4,moottori_id] == 0) #Paikkasäätöinen
            #println("paikkasäätö: ",moottori_id, " kohtaan: ",ins_matrix_PLC[6,moottori_id], " haluttu_asema:",moottori[3], " lähtöasema: ", moottori[7], " nykyinen asema: ",ins_matrix_Mevea[1,moottori_id])
            #Otetaan alkutilanteen tiedot ylös ajoa varten. Tämä resetoituu aina kun execute on 1 tai moottori on mennyt yli aseman, jolloin se pyrkii menemään samaan asemaan uudestaan.
            #println("Matka - kuljettu: ",(abs(moottori[3]  - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])), "mm. PID Interger: ",moottori[13],". PID ero: ",moottori[12],"muutos: ",Driker_muutos)
            if Driker_muutos == 1.0 || (Asetusmuutoos_muutos == -1.0 && moottori[16] ==1)
              moottori[1] = 0
              if 1 == findfirst(pyorivat_moottorit,moottori_id)
                ins_matrix_PLC[6,moottori_id] = pyorimsmatka(ins_matrix_PLC[6,moottori_id],ins_matrix_Mevea[1,moottori_id],pyorivan_moottorin_kehapituus)
              end
              println("asento alustetaan ",moottori_id, " kohtaan: ",ins_matrix_PLC[6,moottori_id])
              nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],1.0)

            elseif Asetusmuutoos_muutos == -1.0 && moottori[16] ==0
              println("alustus väärä ",moottori_id, " kohtaan: ",ins_matrix_PLC[6,moottori_id])
              ins_matrix_PLC[6,moottori_id] = ins_matrix_Mevea[1,moottori_id] + abs(0.5*moottori[6]*(moottori[10]/moottori[6])^2)*sign(moottori[10])
              nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],1.0)

            elseif (abs(moottori[3] - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])) < -0.1 && moottori[1] < 20
            #elseif (abs(moottori[3] - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])) < -0.05 || (moottori[10] == 0 && moottori[14] == 1 && abs(abs(moottori[3] - moottori[7])  - abs(moottori[7] - ins_matrix_Mevea[1,moottori_id])) > 0.04 ) #Jos moottorin asema poikkeaa yli 0.04mm alustaa sen ajon.
              println("yli ",moottori_id, " kohtaan: ",ins_matrix_PLC[6,moottori_id], " haluttu_asema:",moottori[3], " lähtöasema: ", moottori[7], " nykyinen asema: ",ins_matrix_Mevea[1,moottori_id])
              moottori[10] = 0.0
              moottori[1] += 1

              #pienenetään nopeuksia
              ins_matrix_PLC[7,moottori_id] = 0.1*ins_matrix_PLC[7,moottori_id]
              ins_matrix_PLC[8,moottori_id] = 0.1*ins_matrix_PLC[8,moottori_id]
              ins_matrix_PLC[9,moottori_id] = 0.1*ins_matrix_PLC[9,moottori_id]
              nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],0.0)

            end

            if   PID_saadin == 1
              moottori[13] += pid_saadin(moottori,moottori[9],ins_matrix_Mevea[2,moottori_id],aika_askel)
              #println("Haluttu nopeus: ",moottori[9]," Saavutettu nopeus: ",ins_matrix_Mevea[2,moottori_id])
              if abs(moottori[13]) > 80.0 && 0 == findfirst(pyorivat_moottorit,moottori_id)
                println("PID yli 80 moottorilla: ",moottori_id)
                moottori[10] = 0
                ins_matrix_PLC[6,moottori_id] = ins_matrix_Mevea[1,moottori_id]
                nollaus(moottori,ins_matrix_PLC[:,moottori_id],ins_matrix_Mevea[:,moottori_id],ins_mevea[end],1.0)
              end

              moottori[9] = speed_profile(moottori,ins_mevea[end],aika_askel,ins_matrix_Mevea[1,moottori_id],ins_matrix_Mevea[2,moottori_id])
              if moottori[9] == 0 || moottori[10] == 0
                moottori[11] = 0
                moottori[12] = 0
                moottori[13] = 0
              end
              outs_mevea[(moottori_id*2)-1] = moottori[9] + moottori[13]
            else

              moottori[9] = speed_profile(moottori,ins_mevea[end],aika_askel,ins_matrix_Mevea[1,moottori_id],ins_matrix_Mevea[2,moottori_id])
              outs_mevea[(moottori_id*2)-1] = moottori[9]

            end

            outs_mevea[moottori_id*2] = outs_mevea[(moottori_id*2)-1]
          end
              #onko laite annetussa asemassa. Toleranssi 0.5mm
          if abs(moottori[3] - ins_matrix_Mevea[1,moottori_id]) < 0.5
            outs_plc[1,moottori_id] = 1
          else
            outs_plc[1,moottori_id] = 0
          end

          if 1 == findfirst(pyorivat_moottorit,moottori_id)
            outs_plc[3,moottori_id] = ((ins_matrix_Mevea[1,moottori_id]/pyorivan_moottorin_kehapituus)*360)%360 # Pyörimismatka muutetaan sen hetkiseski kulmaksi.
          else
            outs_plc[3,moottori_id] = ins_matrix_Mevea[1,moottori_id]
          end

          outs_plc[4,moottori_id] = ins_matrix_Mevea[2,moottori_id]

          moottorit[:,moottori_id] = moottori
          #println("lähetetään mevealle: ", outs_mevea[1*2], " Ohjelmanopeus: ",moottori[10]," PID lisä: ", moottori[13])
        end #For end
        Edellinen_aika = ins_mevea[end]

        for moottori_liike in liikkeessa

          outs_mevea[(moottori_liike*2)-1] = 0
          outs_mevea[(moottori_liike*2)] = outs_mevea[(moottori_liike*2)-1]

        end
        #println("lähetetään mevealle: ", outs_mevea[1*2], " Ohjelmanopeus: ",moottori[10]," PID lisä: ", moottoori[13])
        #println("lähetetään plc: ", outs_plc)
      end #aika loppu

      #Outs_plc on 4*(moottorien_maara+1) matriisi. Tässä asetetaan anturien arvot suoraan plc:lle. Katso IO määrittely documentti.
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
      #println("lähetetään mevea: ", outs_mevea[1*2])

      #outs_plc 4*15(moottorien määrä plus anturit) matriisi
      #Sarakkeet 1-14 ovat moottoreita:
      # 1. InPosition         [0/1]         = Onko kappale annetussa asemassa
      # 2. Enable             [0/1]         = Onko moottori päällä
      # 3. ActualPos          [mm]          = Mikä on kappaleen oikea asemassa
      # 4. ActualSpeed        [mm/s]        = Mikä on kappaleen oikea nopeus

      #Sarake 15 on antureille:
      # 1.LogOnStepfeeder_Down[0/1]         = Onko pölli ensimmäisen portaan kohdalla
      # 2.LogOnStepfeeder_Up  [0/1]         = Onko pölli toisen portaan kohdalla
      # 3.Laser_ActValue_LHS  [mm]          = Mikä on pöllin halkaisia vasemmalla
      # 4.Laser_ActValue_RHS  [mm]          = Mikä on pöllin halkaisia oikealla

      write(conn_plc,outs_plc)

      #Outs_mevea: Pituus 2*14 + 1(tasottajien ohjaus)
      #Numerot 1 - 28 ovat moottoorien ohjaus tietoja:
      # 1.Motor_rotation      [mm/s]        = Moottorin pyörimisnopeus. Mevean puolella muutetaan rad/s
      # 2.Motor_break         [copy from 1] = kun syöttöarvo on 0, jarru jarruttaa

      #Numero 29 venttiilien ohjaus:
      #29.Block even ender    [-1/1]        = -1 päästää männään taakse päin ja 1 päästää männän eteenpäin.

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
