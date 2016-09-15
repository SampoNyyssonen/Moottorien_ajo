yhteys2= connect(5001)
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
moottori = [1.0,1.0,0.0,0.0,0.0,1.0,300.0,50.0,20.0,-20.0,0.0]
#moottori = [3.0,0.0,0.0,0.0,1.0,1.0,60.0,20.0,10.0,-5.0,0.0]
write(yhteys2,moottori)
close(yhteys2)
