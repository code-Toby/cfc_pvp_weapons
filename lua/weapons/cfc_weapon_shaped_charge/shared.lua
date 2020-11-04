SWEP.Author			= "Redox"
SWEP.Contact		= ""
SWEP.Instructions	= "Left click while looking at a prop to spawn a shaped explosive"

game.AddAmmoType( {
	name = "shapedCharge",
	dmgtype = DMG_BULLET
} )

SWEP.Spawnable      = true

SWEP.ViewModel      = "models/weapons/v_c4.mdl"
SWEP.WorldModel     = "models/weapons/w_c4.mdl"

SWEP.Primary.ClipSize		= 1
SWEP.Primary.Delay          = 3
SWEP.Primary.DefaultClip	= 1
SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo		    = "shapedCharge"

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

CreateConVar( "cfc_shaped_charge_chargehealth", 100, FCVAR_REPLICATED, "Health of placed charges.", 0 )
CreateConVar( "cfc_shaped_charge_maxcharges", 1, FCVAR_REPLICATED, "Maxmium amount of charges active per person at once.", 0 )
CreateConVar( "cfc_shaped_charge_timer", 10, FCVAR_REPLICATED, "The time it takes for a charges to detonate.", 0 )
CreateConVar( "cfc_shaped_charge_blastdamage", 0, FCVAR_REPLICATED, "The damage the explosive does to players when it explodes.", 0 )
CreateConVar( "cfc_shaped_charge_blastrange", 100, FCVAR_REPLICATED, "The damage range the explosion has.", 0 )
CreateConVar( "cfc_shaped_charge_tracerange", 100, FCVAR_REPLICATED, "The range the prop breaking explosion has.", 0 )

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
    
    if hitWorld or hasMaxCharges then
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
    return
end