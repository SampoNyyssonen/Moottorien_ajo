include("Lähtöarvot.jl")

notwaiting = true
plc = zeros(10,noutputs_plc)
server = listen(PLC_portti)
yhteys = connect(Moottori_ohjaus_portti)

while true
    if notwaiting
        notwaiting = false
        # Runs accept async (does not block the main thread)
        @async begin
            sock = accept(server)
            moottori2 = read(sock, Float64, 11)
            if moottori2[1] <= moottorien_maara
              plc[:,convert(Int64,moottori2[1])] = moottori2[2:11]
            elseif moottori2[1] > moottorien_maara
              plc[(convert(Int64,moottori2[1])-moottorien_maara),15] = moottori2[2]
            end
            #println(moottori2)
            #println(plc[1,:])
            write(yhteys,reshape(plc,(moottorien_maara+1)*10))
            global notwaiting = true

        end
    end
    try
      #println(reshape(plc,30))
      write(yhteys,reshape(plc,(moottorien_maara +1 )*10))
      ins_plc2 = read(yhteys,Float64,noutputs_plc*4)
      #println(ins_plc2[1:4])
    catch e
      println("caught an error $e")
      close(server)
      close(server)
      break
    end
    #sleep(0.0001) # slow down the loop
end
close(server)
