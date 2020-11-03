AddCSLuaFile( "cl_init.lua" ) -- Make sure clientside
AddCSLuaFile( "shared.lua" )  -- and shared scripts are sent.
include( 'shared.lua' )

local bombHealth
local maxBombs
local bombTimer
local blastDamage
local blaseRange
local explodeTime
local spawnTime
local bombLight
 
function ENT:Initialize()  

    local owner = self.Owner
    owner.plantedCharges = owner.plantedCharges or 0
    owner.plantedCharges = owner.plantedCharges + 1

    bombHealth  = GetConVar( "cfc_shaped_charge_chargehealth" ):GetInt()
    maxBombs    = GetConVar( "cfc_shaped_charge_maxcharges" ):GetInt()
    bombTimer   = GetConVar( "cfc_shaped_charge_timer" ):GetInt()
    blastDamage = GetConVar( "cfc_shaped_charge_blastdamage" ):GetInt()
    blastRange  = GetConVar( "cfc_shaped_charge_blastrange" ):GetInt()

    if not IsValid( owner ) then
        self:Remove()
        return
    end

    self:SetModel( "models/weapons/w_c4_planted.mdl" )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    bombLight = ents.Create( "light_dynamic" )
    bombLight:SetPos( self:GetPos() )
    bombLight:SetKeyValue( "_light", 255, 0, 0, 200 )
    bombLight:SetKeyValue( "style", 0 )
    bombLight:SetKeyValue( "distance", 255 )
    bombLight:SetKeyValue( "brightness", 0 )
    bombLight:SetParent( self )
    bombLight:Spawn()

    self.bombHealth = bombHealth
    explodeTime = CurTime() + bombTimer

    self:EmitSound( "weapons/c4/c4_initiate.wav", 100, 100, 1, CHAN_WEAPON )

    self:SetNWFloat( "bombInitiated", CurTime() )

    spawnTime = CurTime()
    self:bombVisualsTimer()
end

function ENT:OnTakeDamage ( dmg )
    self.bombHealth = ( self.bombHealth ) - dmg:GetDamage()
    if self.bombHealth <= 0 then

        if not IsValid( self ) then return end

        local effectdata = EffectData()
            effectdata:SetOrigin( self:GetPos() )
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

function ENT:Think()
    if not IsValid( self ) then return end

    if explodeTime <= CurTime() then
        self:Explode()
    end
end

function ENT:Explode()
    local props = ents.FindAlongRay( self:GetPos(), self:GetPos() + 100 * -self:GetUp() )
    
    for _, prop in pairs( props ) do
        if IsValid( prop ) and prop:MapCreationID() == -1 then
            local shouldDestroy = hook.Call( "CFC_SWEP_Shaped_Charge", entityToDestroy )
            if shouldDestroy ~= false then 
                prop:Remove()
            end
        end
    end
    
    util.BlastDamage( self, self.Owner, self:GetPos(), blastRange, blastDamage )
    
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    util.Effect( "Explosion", effectdata )
        
    self:Remove()
end

function ENT:soundLight()
    bombLight:SetKeyValue( "brightness", 2 )
    timer.Simple(0.2,function()
        if not IsValid(self) then return end
        bombLight:SetKeyValue( "brightness", 0 )
    end)
    
    self:EmitSound( "weapons/c4/c4_beep1.wav", 85, 100, 1, CHAN_STATIC )
    self:bombVisualsTimer()
end

function ENT:bombVisualsTimer()
    local timePassed = CurTime() - spawnTime
    local timerDelay = math.Clamp( bombTimer / timePassed - 1, 0.13, 1 )
    
    timer.Simple( timerDelay, function()
        if not IsValid( self ) then return end
        if not IsValid( self.Entity ) then return end
        self:soundLight() 
    end)
end