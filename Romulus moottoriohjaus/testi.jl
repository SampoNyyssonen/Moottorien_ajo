server_raute_plc = listen(IPv4(0),2000)
conn_raute_plc = accept(server_raute_plc)

while isopen(conn_raute_plc)
  println("auki")
  input = read(conn_raute_plc,Float64,863)
  println(input)
end
