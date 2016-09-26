notwaiting = true
moottorein_maara = 14
plc = zeros(10,moottorein_maara)
server = listen(5002)
yhteys=connect(5003)
#server2 = listen(5001)
#sock2 = accept(server2)
while true
    if notwaiting
        notwaiting = false
        # Runs accept async (does not block the main thread)
        @async begin
            sock = accept(server)
            moottori2 = read(sock, Float64, 11)
            plc[:,convert(Int64,moottori2[1])] = moottori2[2:11]
            #println(moottori2)
            #println(plc[1,:])
            write(yhteys,reshape(plc,moottorein_maara*10))
            global notwaiting = true

        end
    end
    try
      #println(reshape(plc,30))
      write(yhteys,reshape(plc,moottorein_maara*10))
    catch e
      println("caught an error $e")
      close(server)
      close(server)
      break
    end
    #sleep(0.0001) # slow down the loop
end
close(server)
