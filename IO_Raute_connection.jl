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


println("Connection established")
while isopen(conn) #Kommunikointi

  try
    ins = round(read(conn,Float64,ninputs),3)

    ins_matrix=reshape(ins,12,?)
    paalla_eteen=find(x->(x==1), ins_matrix[1,:])
    paalla_taakse=find(x->(x==1), ins_matrix[2,:])
    paalla=sort(union(paalla_eteen,paalla,taakse))
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
