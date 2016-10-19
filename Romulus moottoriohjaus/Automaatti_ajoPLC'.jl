function ajo_ohjelma()


  notwaiting = true
  moottorein_maara = 14
  plc = zeros(10,moottorein_maara+1)
  ins_plc2 = zeros(4,15)
  kaynnista = 0.0
  notwaiting = true

  server = listen(5002)
  yhteys = connect(5003)
  while true
      if notwaiting
          notwaiting = false
          @async begin
              sock = accept(server)
              moottori2 = read(sock, Float64, 1)
              if moottori2[1] == -1.0
                kaynnista = 1.0
              end
              notwaiting = true

          end
      end
      #println(notwaiting)
      if kaynnista == 1.0
        #println("Lähtö")
        aloita_ajo(ins_plc2,plc)
      end
      try
        #println(reshape(plc,30))
        write(yhteys,reshape(plc,(moottorein_maara +1 )*10))
        ins_plc2 = reshape(read(yhteys,Float64,60),4,15)

      catch e
        println("caught an error $e")
        close(server)
        break
      end


  end
  close(server)
end
function  aloita_ajo(run_plc_in::Array,run_plc_out::Array)
  maks_nopeus = 200
  Step_motor_end = [1.0,0.0,0.0,0.0,1.0,485.0,maks_nopeus,150.0,-100.0,0.0]

  if run_plc_out[1,1] == 1 #Stepfeeder
    run_plc_out[1,1] = 0
  elseif run_plc_in[1,15] == 1 && run_plc_in[2,15] == 0 && run_plc_in[3,1] < 1.0
    run_plc_out[:,1] = Step_motor_end
  elseif run_plc_in[1,1] == 1.0 && run_plc_in[3,1] > 484.5
    run_plc_out[:,1] = [1.0,0.0,0.0,0.0,1.0,0.0,maks_nopeus,150.0,-100.0,0.0]
  elseif (run_plc_in[3,2] > 399.0 && run_plc_in[2,15] == 1 && run_plc_in[3,1] < 1.0 && run_plc_in[3,2] > 400.0 && run_plc_in[1,15] == 1 && run_plc_in[1,1] == 1)
    run_plc_out[:,1] = Step_motor_end
  end

  Linear_feeder_start = [1.0,0.0,0.0,0.0,1.0,401.0,maks_nopeus,150.0,-50.0,0.0]
  Linear_feeder_end =   [1.0,0.0,0.0,0.0,1.0,680.0,maks_nopeus,150.0,-50.0,0.0]
  if run_plc_out[1,2] == 1 #linearfeeder
    run_plc_out[1,2] = 0
  elseif run_plc_in[3,2] < 1.0
    run_plc_out[:,2] = Linear_feeder_start
  elseif run_plc_in[3,2] > 397.0 && run_plc_in[1,15] == 0 && run_plc_in[3,1] < 0.05 && run_plc_in[1,1] == 1 && run_plc_in[3,2] < 401.0 && run_plc_in[3,4] < 205.0
    run_plc_out[:,2]= Linear_feeder_end
  elseif run_plc_in[3,7] > 229.0 && run_plc_in[4,7] < 0.1 && run_plc_in[3,4] < 161.0
    run_plc_out[:,2] = Linear_feeder_start
  end
  x_carraige_start =   [1.0,0.0,0.0,0.0,1.0,170.0,maks_nopeus,150.0,-50.0,0.0]
  x_carraige_end =   [1.0,0.0,0.0,0.0,1.0,965.0,maks_nopeus,150.0,-50.0,0.0]
  #x-carraige
  if run_plc_out[1,3] == 1 || run_plc_out[1,5] == 1#x-carraige
    run_plc_out[1,3] = 0
    run_plc_out[1,5] = 0
  elseif run_plc_in[3,2] > 678.5 && run_plc_in[1,2] == 1 && run_plc_in[3,3] == 0
    run_plc_out[:,3] = x_carraige_start
    run_plc_out[:,5] = x_carraige_start
  elseif run_plc_in[3,9] > 357.0 && run_plc_in[4,9] < 0.05 && run_plc_in[3,4] > 348.0 && run_plc_in[3,3] < 171.0 && run_plc_in[4,3] < 0.05
    run_plc_out[:,3] = x_carraige_end
    run_plc_out[:,5] = x_carraige_end

  end

  #Pöllin  tasaajat
  if run_plc_in[2,15] == 1 && run_plc_in[3,1] < 26.0 && run_plc_in[4,1] < 0.0#Pöllin  tasaajat
      run_plc_out[2,15] = 0
      run_plc_out[1,15] = 1
  elseif run_plc_in[4,1] >= 0.0 && run_plc_in[3,1] < 26.0
      run_plc_out[1,15] = 0
      run_plc_out[2,15] = 1
  else
      run_plc_out[1,15] = 0
      run_plc_out[2,15] = 0
  end

  y_carraige_start =   [1.0,0.0,0.0,0.0,1.0,150.0,0.6*maks_nopeus,100.0,-50.0,0.0]
  y_carraige_up =   [1.0,0.0,0.0,0.0,1.0,350.0,0.6*maks_nopeus,100.0,-50.0,0.0]
  #y-carraige
  if run_plc_out[1,4] == 1 || run_plc_out[1,6] == 1#y-carraige
      run_plc_out[1,4] = 0
      run_plc_out[1,6] = 0
  elseif run_plc_in[3,2] > 678.5 && run_plc_in[1,2] == 1 && run_plc_in[3,3] == 0
      run_plc_out[:,4] = y_carraige_start
      run_plc_out[:,6] = y_carraige_start
  elseif run_plc_in[3,7] > 229.0 && run_plc_in[4,7] < 0.1 && run_plc_in[3,4] < 161.0
    run_plc_out[:,4] = y_carraige_up
    run_plc_out[:,6] = y_carraige_up

  end

  #Charger spindle
  Charger_spindle_start =   [1.0,0.0,0.0,0.0,1.0,250.0,0.5*maks_nopeus,100.0,-50.0,0.0]
  Charger_spindle_out =   [1.0,0.0,0.0,0.0,1.0,0.0,0.5*maks_nopeus,100.0,-50.0,0.0]
  if run_plc_out[1,7] == 1 || run_plc_out[1,8] == 1#Charger spindle
      run_plc_out[1,7] = 0
      run_plc_out[1,8] = 0
  elseif run_plc_in[3,3] > 169.5 && run_plc_in[1,3] == 1 && run_plc_in[3,7] == 0 && run_plc_in[3,3] < 500.0
      run_plc_out[:,7] = Charger_spindle_start
      run_plc_out[:,8] = Charger_spindle_start
    elseif run_plc_in[3,10] < 270.0 && run_plc_in[4,10] < 0.05  && run_plc_in[3,7] > 225.0
        run_plc_out[:,7] = Charger_spindle_out
        run_plc_out[:,8] = Charger_spindle_out
  end

  #Charger shaft L
  Charger_shaftL_start =   [1.0,0.0,0.0,0.0,1.0,358.0,100.0,10.0,-10.0,0.0]
  if run_plc_out[1,9] == 1
      run_plc_out[1,9] = 0
  elseif run_plc_in[4,7] < 0.1 && run_plc_in[3,4] < 351.0 && run_plc_in[1,4] == 1 && run_plc_in[3,9] < 0.1 && run_plc_in[3,4] > 348.0
      run_plc_out[:,9] = Charger_shaftL_start
  end
  # 12.ArmSlider
  ArmSlider_RL_start =   [1.0,0.0,0.0,0.0,1.0,30.0,maks_nopeus,100.0,-50.0,0.0]
  ArmSlider_RL_down =   [1.0,0.0,0.0,0.0,1.0,1190.0,maks_nopeus,100.0,-50.0,0.0]
  if run_plc_out[1,12] == 1
    run_plc_out[1,12] = 0
  elseif run_plc_in[3,3] > 964.0 && run_plc_in[3,3] < 967.0 && run_plc_in[3,12] > 1115.5 && run_plc_in[3,10] > 480.0
    run_plc_out[:,12] = ArmSlider_RL_start
  elseif run_plc_in[4,10] < 0.05 && run_plc_in[3,10] < 270.0 && run_plc_in[3,7] < 100.0  && run_plc_in[3,12] < 32.0
    run_plc_out[:,12] = ArmSlider_RL_down
  end

    # 10.Clamp L & 11.Clamp R
  Clamp_in =  [1.0,0.0,0.0,0.0,1.0,264.0,maks_nopeus,100.0,-50.0,0.0]
  Clamp_out = [1.0,0.0,0.0,0.0,1.0,490.0,maks_nopeus,100.0,-50.0,0.0]
  if run_plc_out[1,10] == 1 || run_plc_out[1,11] == 1
    run_plc_out[1,10] = 0
    run_plc_out[1,11] = 0
  elseif run_plc_in[3,12] < 32.0 && run_plc_in[4,12] < 0.05
    run_plc_out[:,10] = Clamp_in
    run_plc_out[:,11] = Clamp_in
  elseif run_plc_in[3,12] > 1190.0 && run_plc_in[4,12] < 0.0 && run_plc_in[3,13] > 315.0 && run_plc_in[4,13] < 0.05
    run_plc_out[:,10] = Clamp_out
    run_plc_out[:,11] = Clamp_out
  end

  # 13.Lathe spindle L && 14.Lathe spindle R
  Lathe_spindle_start =  [1.0,0.0,0.0,0.0,1.0,320.0,maks_nopeus,100.0,-50.0,0.0]

  if run_plc_out[1,13] == 1 || run_plc_out[1,14] == 1
    run_plc_out[1,13] = 0
    run_plc_out[1,14] = 0
  elseif run_plc_in[3,12] > 1190.0 && run_plc_in[4,12] < 0.0 && run_plc_in[3,13] < 3.0
    run_plc_out[:,13] = Lathe_spindle_start
    run_plc_out[:,14] = Lathe_spindle_start
  end

end
