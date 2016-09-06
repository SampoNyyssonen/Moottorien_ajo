
function plc_mevea_connection()
  println("Waiting for connection")
  server = listen(5112) # Avataan Modelerissa asetettu portti #listen(ip"127.0.0.1",2000)

  conn = accept(server)

  ninputs = 0 # Mevea solverista tulevat outputit
  noutputs = 0  # Mevea solveriin menevät inputit

  params=Array{Int32}(3)
  params2=Array{Int32}(3)
  params[1]=1
  params[2]=noutputs
  params[3]=ninputs
  params2 = read(conn,Int32,3) #Tarksitetaan että Ratkaisiassa ja Juliassa on sama määrä out-ja inputteja.

  write(conn,params)

  ins=Array{Float64}(ninputs)
  outs=Array{Float64}(noutputs)

  moottorien_ruuvien_nousut = [10,20,20,10,20,10,10,10,0,10,10,20,20,10,10]
  moottorit = zeros(5,length(moottorien_ruuvien_nousut))
  moottorit[1,:] = moottorien_ruuvien_nousut
  #Moottorit tiedot:
      # 1. Ruuvin nousu [mm]
      # 2. Haluttu asema
      # 3. Nopeusprofiilin nopeus
      # 4. Nopeusprofiilin kiihdytys
      # 5. Nopeusprofiilin jarrutus
      # 6. Lähtöasema

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
      # 12.ArmSlider L
      # 13.ArmSlider R
      # 14.Lathe spindle L
      # 15.Lathe spindle R

  aika_askel = 0.001
  println("Connection established")
  while isopen(conn) #Kommunikointi

    try
      ins_plc = round(read(conn,Float64,ninputs),3)
      ins_mevea = round(read(conn,Float64,ninputs),3)
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

      #AO 3.Motor_speed   [rad/s]      = Moottorin kierrosnopeus

      ins_matrix_PLC=reshape(ins_plc,11,?)    #PLC:ltä tulevat yhteydet
      paalla=find(ins_matrix_PLC[5,:])        #Onko moottori paalla. Antaa luettelon mitkä moottorit ovat päällä
      liike_paalla=find(ins_matrix_PLC[1,:])  #Onko liikukäsky annettu. Luettelona mille moottoreille on
      liikkeessa=find(ins_matrix_Mevea[2,:])  #Onko moottori liikkeessä. Luetelo mitkä moottorit ovat liikkeessä.
      moottorin_arvot=Array{Float64}(11)

      for moottori in paalla                                                       #käy jokaisen päällä olevan moottorin läpi
        if(ins_matrix_PLC[3,moottori] == 1)                                       #Moottori illa on vääntösäätö päällä

        elseif(ins_matrix_PLC[3,moottori] == 0 & ins_matrix_PLC[4,moottori] == 1) #Nopeusäätöinen
          if(ins_matrix_PLC[1,moottori] == 1)
            if ins_matrix_Mevea[2,moottori] == ins_matrix_PLC[7,moottori] #Jos sama nopeus kun vaadittu
              outs_mevea[1,moottori] = millimetri_kierrosnopeudeksi(ins_matrix_PLC[7,moottori],moottorit[1,moottori]) #Lähetetään sama kierrosnopeus takas

            elseif abs(ins_matrix_Mevea[2,moottori]) < abs(ins_matrix_PLC[7,moottori])
              outs_mevea[1,moottoir] = millimetri_kierrosnopeudeksi(moottorin_nopeudenmuutos(ins_matrix_Mevea[2,moottori],aika_askel,ins_matrix_PLC[8,moottori]),moottorit[1,moottori])
            end
          else
            outs_mevea[1,moottori] = millimetri_kierrosnopeudeksi(moottorin_nopeudenmuutos(ins_matrix_Mevea[2,moottori],aika_askel,ins_matrix_PLC[9,moottori]),moottorit[1,moottori] # lähetetään jarrutus kierrosnopeus takaisin
          end


        elseif(ins_matrix_PLC[3,moottori] == 0 & ins_matrix_PLC[4,moottori] == 0) #Paikkasäätöinen

          if(ins_matrix_PLC[1,moottori] == 1 || ( abs(ins_matrix_PLC[6,moottori] - moottorit[6,moottori])  - abs(moottorit[6,moottori] - ins_matrix_Mevea[1,moottori])) < 0) #Tallennetaan haluttu asema ja nopeusprofiili lähtö tilanteessa ja jos menee yli tavoite pisteen.
            moottorit[2,moottori] = ins_matrix_PLC[6,moottori]
            moottorit[3,moottori] = ins_matrix_PLC[7,moottori]
            moottorit[4,moottori] = ins_matrix_PLC[8,moottori]
            moottorit[5,moottori] = ins_matrix_PLC[9,moottori]
            moottorit[6,moottori] = ins_matrix_Mevea[1,moottori]
          end
                                                    #Nykyinen asema, haluttu asema,lähtö asema, aika askel, noepusprofiilin nopeus,kiihtyvyys, jarrutus
          outs_mevea[1,moottori] = position_control(ins_matrix_Mevea[1,moottori],moottorit[2,moottori],moottorit[6,moottori],aika_askel,ins_matrix_Mevea[1,moottori],moottorit[3,moottori],moottorit[4,moottori],moottorit[5,moottori])

          if outs_mevea
        end
      end






      for i in paalla
        println(ins_matrix[:,paalla[i]])
        moottorien_kierrosnopeus(ins_matrix[1,paalla[i]],ins_matrix[2,paalla[i]],ins_matrix[:,paalla[i]])
      end
    if(ins[1]==0.001)
      aseta_asemat(ins[12])
      resetoi()
    end
    if(ins[24]!=ins[12] && ins[24]>0)
      print("ajetaan: ")
      outs[1]=fun_moottorin_ajo(ins[24],ins[12],ins[1])
      println(ins[1], "s, ",ins[24],"m, ",ins[12],"m, ",round(outs[1],1), "rad/s, ", global_kara_asema, "m, ", round(alku_aika,3),"s, ", kiihdytys_matka, "m, ", koko_matka,"m")
    elseif(ins[24]==ins[12] && alku_aika>0)
      resetoi()
      aseta_asemat(ins[12])
      outs[1]=0
    else
      resetoi()
      aseta_asemat(ins[12])
      println(ins[12])
      outs[1]=0
    end

      write(conn,outs)
    catch e
      println("caught an error $e")
      break
    end
  end

  println("Connection closed")
  close(conn)
  close(server)
end
