AddCSLuaFile( 'cl_init.lua' )
AddCSLuaFile( 'shared.lua' )

include( 'shared.lua' )

function SWEP:PrimaryAttack()

    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
    
    if self:CanPrimaryAttack() == false then
        local ammo = self.Owner:GetAmmoCount( "shapedCharge" )
        
        if ammo == 0 then
            self.Owner:StripWeapon( "cfc_weapon_shaped_charge" )
            return
        end
        
        self.Owner:SetAmmo( ammo-1, "shapedCharge" )
        self:SetClip1( 1 )
    end
    
    local viewTrace = {}
	viewTrace.start = self.Owner:GetShootPos()
	viewTrace.endpos = self.Owner:GetShootPos() + 100 * self.Owner:GetAimVector()
	viewTrace.filter = {self.Owner}
	local trace = util.TraceLine( viewTrace )
        
    local hitWorld = trace.HitNonWorld == false
    local maxCharges = GetConVar( "cfc_shaped_charge_maxcharges" ):GetInt()
    local hasMaxCharges = ( self.Owner.plantedCharges or 0 ) >= maxCharges
    local isPlayer = trace.Entity:IsPlayer()
    local isNPC = trace.Entity:IsNPC()
    
    if hitWorld or hasMaxCharges or isPlayer or isNPC then
        self.Owner:EmitSound( "common/wpn_denyselect.wav", 100, 100, 1, CHAN_WEAPON )
        return
    end
    
    if trace.Entity:IsValid() then
        local bomb = ents.Create( "cfc_shaped_charge" )
		bomb:SetPos( trace.HitPos )
        
        local FixAngles = trace.HitNormal:Angle()
        local FixRotation = Vector( 270, 180, 0 )

        FixAngles:RotateAroundAxis(FixAngles:Right(), FixRotation.x)
        FixAngles:RotateAroundAxis(FixAngles:Up(), FixRotation.y)
        FixAngles:RotateAroundAxis(FixAngles:Forward(), FixRotation.z)
        
        bomb:SetAngles( FixAngles )
		bomb.Owner = self.Owner
        bomb:SetParent( trace.Entity )
		bomb:Spawn()
        
        self:TakePrimaryAmmo( 1 )
    end

    if self.Owner:GetAmmoCount( "shapedCharge" ) <= 0 then
        self.Owner:StripWeapon( "cfc_weapon_shaped_charge" )
    end
    
end

function SWEP:SecondaryAttack()
    self:PrimaryAttack()
    self:SetNextSecondaryFire( CurTime() + self.Primary.Delay )
end
