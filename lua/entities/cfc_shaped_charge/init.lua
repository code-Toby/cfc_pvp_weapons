AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
include('shared.lua')

    local bombHealth = 1
    local maxBombs   = 1
    local bombTimer  = 1
    local blastDamage = 1
    local blaseRange = 1
 
function ENT:Initialize()

    local owner = self.Owner
    owner.plantedCharges = owner.plantedCharges or 0
    owner.plantedCharges = owner.plantedCharges + 1

    bombHealth = GetConVar("cfc_shaped_charge_chargehealth"):GetInt()
    maxBombs   = GetConVar("cfc_shaped_charge_maxcharges"):GetInt()
    bombTimer  = GetConVar("cfc_shaped_charge_timer"):GetInt()
    blastDamage  = GetConVar("cfc_shaped_charge_blastdamage"):GetInt()
    blastRange  = GetConVar("cfc_shaped_charge_blastrange"):GetInt()
    
    self.timeLeft = bombTimer
    
    if not IsValid(self.Owner) then
		self.Entity:Remove()
		return
	end
        
	self:SetModel( "models/weapons/w_c4_planted.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
    self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
    self:PhysWake()
    
    self.bombHealth = bombHealth
    
    -- TODO change sound V to placing sound
    self.Entity:EmitSound( "npc/turret_floor/click1.wav", 100, 100, 1, CHAN_WEAPON )
    
    self:SetNWFloat( "bombInitiated", CurTime() )
    self:SetNWFloat( "bombDelay", bombTimer )

    timer.Create( "bombAlarm", 1, bombTimer, function()
    
        if not IsValid(self) then return end
        
        self.Entity:EmitSound( "ambient/alarms/klaxon1.wav", 100, 100, 1, CHAN_WEAPON )
        
        if timer.RepsLeft( "bombAlarm" ) == 0 then
                            
            local Props = ents.FindAlongRay( self.Entity:GetPos(), self.Entity:GetPos() + 100 * -self.Entity:GetUp() )
            
            for _, Prop in pairs(Props) do
                if IsValid( Prop ) then
                    local shouldDestroy = hook.Call( "CFC_SWEP_Shaped_Charge", entityToDestroy )
                    if not shouldDestroy then return end
                    Prop:Remove()
                end
            end
            
            util.BlastDamage( self, self.Owner, self.Entity:GetPos(), blastRange, blastDamage )
            
            local effectdata = EffectData()
            
            effectdata:SetOrigin( self.Entity:GetPos() )
            util.Effect("Explosion", effectdata)
                
            self.Entity:Remove()
        end
    end)
end

-- TODO find bug in OnTakeDamage, sometimes doesnt register damage
function ENT:OnTakeDamage( dmg )
    self.bombHealth = ( self.bombHealth ) - dmg:GetDamage()
    if self.bombHealth <= 0 then
    
            if not IsValid(self) then return end
    
            local effectdata = EffectData()
                effectdata:SetOrigin( self.Entity:GetPos() )
                effectdata:SetMagnitude( 8 )
                effectdata:SetScale( 1 )
                effectdata:SetRadius( 16 )
                
            util.Effect( "Sparks", effectdata )
            
            self:Remove()
    end
end

function ENT:OnRemove()
    local owner = self.Owner
    owner.plantedCharges = owner.plantedCharges or 0
    owner.plantedCharges = owner.plantedCharges - 1
    if owner.plantedCharges <= 0 then
        owner.plantedCharges = nil
    end
end
