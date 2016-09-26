#=function position_control_timestep(now_position::Float64,wanted_position::Float64,start_position::Float64,
                          start_time::Float64,now_time::Float64,time_step::Float64,
                          speed::Float64,wanted_speed::Float64,wanted_acceleration::Float64,wanted_breaking::Float64)

  passed_travel   = abs(start_position - now_position)
  whole_travel      = abs(wanted_position - start_position)
  accelerating_journey = abs(0.5*wanted_acceleration*(wanted_speed/wanted_acceleration)^2)
  break_travel  = abs(0.5*wanted_breaking*(speed/wanted_breaking)^2)
  direction          = sign(wanted_position - start_position)
  println("Passed travel:",passed_travel," mm. Whole travel:",whole_travel," mm. accelerating journey:",accelerating_journey,"mm. Break travel:",break_travel,"mm. direction:",direction)

  if(whole_travel > 0)
    if (abs(speed) < abs(wanted_speed) && abs(wanted_position-now_position) > break_travel)
      println("accelerating")
      #return direction*abs(wanted_acceleration*(now_time-start_time))
      return direction*engine_speeddif(speed,time_step,wanted_acceleration)

    elseif (abs(wanted_position-now_position) <= break_travel && passed_travel < whole_travel)
      println("breakingta")
      #return -1*direction*abs(wanted_breaking*(now_time-start_time))
      return -1*direction*engine_speeddif(speed,time_step,wanted_breaking)

    elseif (abs(speed) >= abs(wanted_speed) && abs(wanted_position-now_position) > break_travel)
      println("run")
      return direction*abs(wanted_speed)

    elseif now_position == wanted_position
      println("reached")
      return 0

    end
  end


end

function position_control(now_position::Float64,wanted_position::Float64,start_position::Float64,
                          start_time::Float64,now_time::Float64,
                          speed::Float64,wanted_speed::Float64,wanted_acceleration::Float64,wanted_breaking::Float64)

  passed_travel   = abs(start_position - now_position)
  whole_travel      = abs(wanted_position - start_position)
  accelerating_journey = abs(0.5*wanted_acceleration*(wanted_speed/wanted_acceleration)^2)
  break_travel  = abs(0.5*wanted_breaking*(speed/wanted_breaking)^2)
  direction          = sign(wanted_position - start_position)
  println("Passed travel:",passed_travel," mm. Whole travel:",whole_travel," mm. accelerating journey:",accelerating_journey,"mm. Break travel:",break_travel,"mm. direction:",direction)

  if(whole_travel > 0)
    if (abs(speed) < abs(wanted_speed) && abs(wanted_position-now_position) > break_travel)
      println("accelerating")
      return direction*abs(wanted_acceleration*(now_time-start_time))
      #return direction*engine_speeddif(speed,time_step,wanted_acceleration)

    elseif (abs(wanted_position-now_position) <= break_travel && passed_travel < whole_travel)
      println("breakingta")
      return -1*direction*abs(wanted_breaking*(now_time-start_time))
      #return direction*engine_speeddif(speed,time_step,wanted_breaking)

    elseif (abs(speed) >= abs(wanted_speed) && abs(wanted_position-now_position) > break_travel)
      println("run")
      return direction*abs(wanted_speed)

    elseif now_position == wanted_position
      println("reached")
      return 0

    end
  end


end

function speed_profile_phase(now_position::Float64,wanted_position::Float64,start_position::Float64,
                                speed::Float64,wanted_speed::Float64,wanted_breaking::Float64)

  passed_travel   = abs(start_position - now_position)
  whole_travel      = abs(wanted_position - start_position)
  break_travel  = abs(0.5*wanted_breaking*(speed/wanted_breaking)^2)
  direction          = sign(wanted_position - start_position)


  if(whole_travel > 0)
    if (abs(speed) < abs(wanted_speed) && abs(wanted_position-now_position) > break_travel)
      println("accelerating")
      return 1

    elseif (abs(wanted_position-now_position) <= break_travel && passed_travel < whole_travel)
      println("breaking")
      return 2

    elseif (abs(speed) >= abs(wanted_speed) && abs(wanted_position-now_position) > break_travel)
      println("run")
      return 3

    elseif now_position == wanted_position
      println("reached")
      return 0

    end
  end
end


function speed_profile_acceleration(engine_profile::Array,phase,
                      time_step::Float64,
                      now_speed::Float64)
  real_acceleration = (now_speed - engine_profile[10]) / time_step
  if phase == 1 #accelerating

    println("ny: ",now_speed, "mm/s, ed: ",engine_profile[10],"mm/s, ha_ki: ",abs(engine_profile[5]),"mm/s2, tod_ki:  ",real_acceleration,"mm/s2, time_step: ", time_step)
    acceleration = pid_controller(engine_profile,engine_profile[5],real_acceleration,time_step)
    println("PID_ki: ",acceleration,"mm/s2.")
    return now_speed+acceleration*time_step

  elseif phase == 2 #breaking

    breaking = pid_controller(engine_profile,engine_profile[6],real_acceleration,time_step)
    return now_speed+breaking*time_step

  elseif phase == 3 #run
    return pid_controller(engine_profile,0,real_acceleration,time_step)
    #return now_speed

  elseif phase == 0
     return 0


  end


end
=#
function speed_profile(engine_profile,
                      now_time::Float64, time_step_profile::Float64,
                      now_position::Float64,
                      now_speed::Float64)

  passed_travel   = abs(engine_profile[7]- now_position)
  whole_travel      = abs(engine_profile[3] - engine_profile[7])
  break_travel  = abs(0.5*engine_profile[6]*(engine_profile[10]/engine_profile[6])^2)
  direction          = sign(engine_profile[3] - engine_profile[7])
println("Passed travel:",passed_travel," mm. Whole travel:",whole_travel," mm. Break travel: ",break_travel,"mm. direction:",direction)
  if (abs(engine_profile[3]-now_position) <= break_travel && passed_travel < whole_travel)
    println("breaking")
    engine_profile[10] += engine_profile[6]*time_step_profile

  elseif (engine_profile[5]*(now_time-engine_profile[8]) < engine_profile[4])
    println("accelerating")
    engine_profile[10] += engine_profile[5]*time_step_profile

  elseif (engine_profile[5]*(now_time-engine_profile[8]) >= engine_profile[4])
    println("run")
    engine_profile[10] = engine_profile[4]
  end

    println("profil speed: ",engine_profile[10],"mm/s")
    return pid_controller_speed(engine_profile,engine_profile[10],now_speed,time_step_profile),engine_profile[10]

end


function mm_speed_rotation_speed(speed::Float64,rise::Float64)
  return ((speed/rise)*2*pi)
end



function pid_controller(engine_PID,wanted_PID::Float64,now_PID::Float64,time_step_PID::Float64)

  Kp = 1
  Ki = 1
  Kd = 0

  differens = wanted_PID - now_PID
  engine_PID[11] += (differens*time_step_PID)
  Derivative =(differens-engine_PID[12])/time_step_PID
  speed = Kp*differens+Ki*engine_PID[11]+Kd*Derivative
  engine_PID[12] = differens

  return speed
end

function pid_controller_speed(engine_PID_speed,wanted_PID_speed::Float64,now_PID_speed::Float64,time_step_PID_speed::Float64)

  Kp = 0.5
  Ki = 0.2
  Kd = 0

  differens_speed = wanted_PID_speed - now_PID_speed
  differens_dif_speed = (differens_speed-engine_PID_speed[12])
  speed_return = engine_PID_speed[9] + Kp*differens_dif_speed + Ki*differens_speed*time_step_PID_speed + Kd*((differens_speed - 2*engine_PID_speed[12] + engine_PID_speed[13])/time_step_PID_speed)
  engine_PID_speed[13] = engine_PID_speed[12]
  engine_PID_speed[12] = differens_speed

  return speed_return
end
