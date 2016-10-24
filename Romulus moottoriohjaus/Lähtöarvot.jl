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
    # 15.Back up frame
    # 16.Back up frame roll
    # 17.Trunnion bearing
    # 18.Round bar carriage
    # 19.Knife round bar
    # 20.Lathe shaft 


moottorien_maara = 20
antureiden_maara = 4                                                          # 2 * onko pölli asemassa ja 2 * kuinka paksu pölli on
venttiilien_maara = 2

PLC_portti = 5002
Moottori_ohjaus_portti = 5003
Mevea_solver_portti = 5112

ninputs_plc = (moottorien_maara + 1)*10                                       # PLC:n lähettämä datan määrä. Moottorit + venttiilin ohjaus. Viimeisessä matriisi sarakkeessa on venttiili ohjaus
noutputs_plc = moottorien_maara + ceil(Int64,antureiden_maara/4)                          #Kuinka monta saraketta PLClle lähetetään. Moottorit + anturit.

mevea_rivi = 2
  #Mevea moottorien tiedon määrä: paikka ja nopeus
ninputs_mevea = moottorien_maara*mevea_rivi + 1 + antureiden_maara            # Mevea solverista tulevat outputit #Lisätään simulaation aika
noutputs_mevea = moottorien_maara*2 + 1                                       # Mevea solveriin menevät inputit

Tao = 0.005 #Moottoin reaktio nopeus Time Constant
PID_saadin = 1.0 # Jos PID säädin on päällä, on arvo 1, muuten 0.

pyorivat_moottorit = [9,16,19,20] #Mitkä moottorit ovat pyöriviä

pyorivan_moottorin_kehapituus = 2*pi*[30,42.5,42.5,45] # Pyörivän moottorin kehapituus
