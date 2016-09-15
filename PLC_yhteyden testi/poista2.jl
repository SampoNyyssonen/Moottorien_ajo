notwaiting = true
plc = zeros(10,2)
server = listen(5001)
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
            #println(plc)
            write(yhteys,reshape(plc,20))
            global notwaiting = true

        end
    end
    write(yhteys,reshape(plc,20))
    #println(plc)
    if plc[1,1] == -1.0
      close(server)
      break
    end
    sleep(0.001) # slow down the loop
end
close(server)
