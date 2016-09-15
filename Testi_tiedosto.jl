#Mevea yhteyden testi teidosto


function Mevea_raute_plc_yhteydet_testaus()
  println("Waiting for connection")
  server = listen(5112) # Avataan Modelerissa asetettu portti #listen(ip"127.0.0.1",2000)

  conn = accept(server)

  ninputs = 29 # Mevea solverista tulevat outputit
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


  println("Connection established")
  while isopen(conn) #Kommunikointi

    try
      ins_mevea = round(read(conn,Float64,ninputs),4)
      #Mevea

      #AI 1.Motor_position  [mm]         = Voimakomponentin pituus
      #AI 2.Motor_speed     [mm/s]       = Voimakomponentin nopeus
      #AI 3.Simulation time [s]          = Simuloinnissa juokseva aika

      #AO 1.Motor_speed   [rad/s]      = Moottorin kierrosnopeus

      ins_matrix_mevea=reshape(round(ins_mevea[1:28],1),2,14)    #PLC:ltä tulevat yhteydet
      println(ins_matrix_mevea)



    #  write(conn,outs_mevea)
    catch e
      println("caught an error $e")
      break
    end
  end

  println("Connection closed")
  close(conn)
  close(server)
end
