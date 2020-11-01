include('shared.lua')
 
language.Add("cfc_shaped_charge")

function ENT:Draw()
    self.Entity:DrawModel()
    self.Entity:DrawShadow( false )

	local FixAngles = self.Entity:GetAngles()
	local FixRotation = Vector(0, 270, 0)

	FixAngles:RotateAroundAxis(FixAngles:Right(), FixRotation.x)
	FixAngles:RotateAroundAxis(FixAngles:Up(), FixRotation.y)
	FixAngles:RotateAroundAxis(FixAngles:Forward(), FixRotation.z)

 	local TargetPos = self.Entity:GetPos() + self.Entity:GetUp() * 9
    
    local startedAt = self:GetNWFloat( "bombInitiated" )
    local delay = self:GetNWFloat( "bombDelay" )
    local timeLeft = ( startedAt + delay ) - CurTime() 
    
    local m, s = self:FormatTime( timeLeft )
	self.Text = string.format( "%02d", m ) .. ":" .. string.format( "%02d", s )
	
	cam.Start3D2D(TargetPos, FixAngles, 0.10)
		draw.SimpleText( self.Text, "Trebuchet24", 45, -30, Color(165, 0, 0, 255), 1, 1 )
	cam.End3D2D()
end

function ENT:FormatTime(seconds)

	local m = seconds % 604800 % 86400 % 3600 / 60
	local s = seconds % 604800 % 86400 % 3600 % 60

	return math.floor(m), math.floor(s)
end
