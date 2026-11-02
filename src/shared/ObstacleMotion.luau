-- Shared deterministic motion. The server validates hazards; clients render
-- the same phase at native frame rate and supply grounded surface velocity.
local Motion={}
function Motion.sample(kind,base,elapsed,period,phase,distance)
    local rate=math.pi*2/(period or 7)
    local t=elapsed*rate+(phase or 0)
    local position=Vector3.zero
    local velocity=Vector3.zero
    local rotation=CFrame.identity
    if kind=="MovingPlatform" then
        position=Vector3.new(math.sin(t)*(distance or 4),0,0)
        velocity=Vector3.new(math.cos(t)*rate*(distance or 4),0,0)
    elseif kind=="Elevator" then
        position=Vector3.new(0,(math.sin(t)+1)*3,0)
        velocity=Vector3.new(0,math.cos(t)*rate*3,0)
    elseif kind=="Spinner" then rotation=CFrame.Angles(0,t,0)
    elseif kind=="RotatingBeam" then rotation=CFrame.Angles(0,t,0)
    elseif kind=="PushWall" then position=Vector3.new(-8*(math.sin(t)+1),0,0)
    elseif kind=="Crusher" then position=Vector3.new(-9*(math.sin(t)+1),math.cos(t)*2,0)
    elseif kind=="SwingHammer" then position=Vector3.new(math.sin(t)*12,math.abs(math.sin(t))*3,0)
    elseif kind=="RollingBall" then position=Vector3.new(math.sin(t)*12,0,0);rotation=CFrame.Angles(0,0,t)
    end
    return base*CFrame.new(position)*rotation,base:VectorToWorldSpace(velocity),math.sin(t)>0.25
end
return Motion
