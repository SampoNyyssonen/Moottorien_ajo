include("testi_functio.jl")

println("Waiting for connection")
server = listen(5111) # Avataan Modelerissa asetettu portti

conn = accept(server)

ninputs = 24 # Mevea solverista tulevat outputit
noutputs = 1  # Mevea solveriin menevät inputit

params=Array{Int32}(3)
params2=Array{Int32}(3)
params[1]=1
params[2]=noutputs
params[3]=ninputs
params2 = read(conn,Int32,3) #Tarksitetaan että Ratkaisiassa ja Juliassa on sama määrä out-ja inputteja.

write(conn,params)

ins=Array{Float64}(ninputs)
outs=Array{Float64}(noutputs)
Rotation_matrix_1=Array{Float64}(3,3)


println("Connection established")
while isopen(conn) #Kommunikointi

  try
    ins = round(read(conn,Float64,ninputs),3)

    #ins[1] Simulation time [s]
    #ins[2] Knife bar blade angle [deg(90,-90)]
    #ins[3] Knife bar blade center Global location x [m]
    #ins[4] Knife bar blade center Global location y [m]
    #ins[5] Log global location x [m]
    #ins[6] Log global location y [m]
    #ins[7] Log global location z [m]
    #ins[8] Log euler parameter e0
    #ins[9] Log euler parameter e1
    #ins[10] Log euler parameter e2
    #ins[11] Log euler parameter e3
    #ins[12] Lathe spindle R Global location z [m]
    #ins[13] Lathe spindle L Global location z [m]
    #ins[14] Lathe spindle R orientation z [deg[90,-90]]
    #ins[15] Lathe spindle L orientation z [deg[90,-90]]
    #ins[16] Lathe spindle R angular velocity z [rad/s]
    #ins[17] Lathe spindle L angular velocity z [rad/s]
    #ins[18] Round bar center Global location x [m]
    #ins[19] Round bar center Global location y [m]
    #ins[20] Back up roll1 Global location x [m]
    #ins[21] Back up roll1 Global location y [m]
    #ins[22] Back up roll2 Global location x [m]
    #ins[23] Back up roll2 Global location y [m]
    #ins[24] testi [m]
    #=e0=ins[8]
    e1=ins[9]
    e2=ins[10]
    e3=ins[11]

    Rotation_matrix_1[1,1]=1 - 2 * e2^2 - 2 * e3^2
    Rotation_matrix_1[1,2]=2*(e1 * e2 - e0 * e3)
    Rotation_matrix_1[1,3]=2*(e1 * e3 + e0 * e2)

    Rotation_matrix_1[2,1]=2*(e1 * e2 + e0 * e3)
    Rotation_matrix_1[2,2]=1 - 2 * e1^2 - 2 * e3^2
    Rotation_matrix_1[2,3]=2*(e2 * e3 - e0 * e1)

    Rotation_matrix_1[3,1]=2*(e1 * e3 - e0 * e2)
    Rotation_matrix_1[3,2]=2*(e2 * e3 + e0 * e1)
    Rotation_matrix_1[3,3]=1 - 2 * e1^2 - 2 * e2^2
=#

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
