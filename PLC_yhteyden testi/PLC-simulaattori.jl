function server2_oma(lahetys,kuuntelu)
  notwaiting = true
  mottorien_maara = 3
  plc = zeros(10,mottorien_maara)
  server1 = listen(5002)
  yhteys1=connect(5003)
  #server2 = listen(5001)
  #sock2 = accept(server2)
  while true
      if notwaiting
          notwaiting = false
          # Runs accept async (does not block the main thread)
          @async begin
              sock = accept(server1)
              moottori2 = read(sock, Float64, 11)
              plc[:,convert(Int64,moottori2[1])] = moottori2[2:11]
              #println(moottori2)
              #println(plc)
              write(yhteys1,reshape(plc,mottorien_maara*10))
              global notwaiting = true

          end
      end
      try
        #println(reshape(plc,30))
        write(yhteys,reshape(plc,30))
      catch e
        println("caught an error $e")
        close(server)
        close(server)
        break
      end
  end
  close(server)

end

function lahetys_komento(portti)

  yhteys2= connect(portti)
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

  moottorin_id = 6.0              # 0
  kytkin = 1.0                    # 1
  nopeus_säätö = 0.0              # 4
  matka = 300.0                   # 6
  nopeus = 60.0                   # 7
  kiihdytys = sign(nopeus)*20.0   # 8
  jarrutus = sign(nopeus)*20.0*-1 # 9


  moottori = [moottorin_id,kytkin,0.0,0.0,nopeus_säätö,1.0,matka,nopeus,kiihdytys,jarrutus,0.0]

  write(yhteys2,moottori)
  close(yhteys2)


end
