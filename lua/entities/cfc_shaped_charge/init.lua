AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" )
 
function ENT:Initialize()  

    local owner = self.bombOwner

    if not IsValid( owner ) then
        self:Remove()
        return
    end

    owner.plantedCharges = owner.plantedCharges or 0
    owner.plantedCharges = owner.plantedCharges + 1

    self.bombHealth  = GetConVar( "cfc_shaped_charge_chargehealth" ):GetInt()
    self.bombTimer   = GetConVar( "cfc_shaped_charge_timer" ):GetInt()
    self.blastDamage = GetConVar( "cfc_shaped_charge_blastdamage" ):GetInt()
    self.blastRange  = GetConVar( "cfc_shaped_charge_blastrange" ):GetInt()
    self.traceRange  = GetConVar( "cfc_shaped_charge_tracerange" ):GetInt()

    self:SetModel( "models/weapons/w_c4_planted.mdl" )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:DrawShadow( false )
    self:SetCollisionGroup( COLLISION_GROUP_WEAPON )

    self:PhysWake()

    self:CreateLight()

    explodeTime = CurTime() + self.bombTimer

    self:EmitSound( "items/ammocrate_close.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "npc/roller/blade_cut.wav", 100, 100, 1, CHAN_STATIC )

    self:SetNWFloat( "bombInitiated", CurTime() )

    spawnTime = CurTime()
    self:bombVisualsTimer()
end

function ENT:OnTakeDamage ( dmg )
    self.bombHealth = self.bombHealth - dmg:GetDamage()
    if self.bombHealth <= 0 then

        if not IsValid( self ) then return end

        local effectdata = EffectData()
        effectdata:SetOrigin( self:GetPos() )
        effectdata:SetMagnitude( 8 )
        effectdata:SetScale( 1 )
        effectdata:SetRadius( 16 )
            
        util.Effect( "Sparks", effectdata )
        
        self:EmitSound( "npc/manhack/bat_away.wav", 100, 100, 1, CHAN_STATIC )
        self:EmitSound( "doors/vent_open1.wav", 100, 100, 1, CHAN_STATIC )

        self:Remove()
    end
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetScale( 0.5 )
    effectdata:SetMagnitude( 1 )
        
    util.Effect( "Sparks", effectdata )
    
    self:EmitSound( "Plastic_Box.Break", 100, 100, 1, CHAN_WEAPON )
    self:EmitSound( "npc/roller/code2.wav", 100, 100, 1, CHAN_WEAPON )
    
end

function ENT:OnRemove()
    local owner = self.bombOwner
    
    if not IsValid( owner ) then
        self:Remove()
        return
    end
    
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
    local props = ents.FindAlongRay( self:GetPos(), self:GetPos() + self.traceRange * -self:GetUp() )
    
    for _, prop in pairs( props ) do
        if self:CanDestroyProp( prop ) then
            prop:Remove()
        end
    end
    
    util.BlastDamage( self, self.bombOwner, self:GetPos(), self.blastRange, self.blastDamage )
    
    local effectdata = EffectData()
    effectdata:SetOrigin( self:GetPos() )
    effectdata:SetNormal( -self:GetUp())
    effectdata:SetRadius( 3 )

    util.Effect( "AR2Explosion", effectdata )
    util.Effect( "Explosion", effectdata )
    
    self:EmitSound( "npc/strider/strider_step4.wav", 100, 100, 1, CHAN_STATIC )
    self:EmitSound( "weapons/mortar/mortar_explode2.wav", 500, 100, 1, CHAN_WEAPON )
        
    self:Remove()
end

function ENT:RunCountdownEffects()
    self.bombLight:SetKeyValue( "brightness", 2 )
    timer.Simple( 0.2, function()
        if not IsValid( self ) then return end
        
        self.bombLight:SetKeyValue( "brightness", 0 )
    end)
    
    self:EmitSound( "weapons/c4/c4_beep1.wav", 85, 100, 1, CHAN_STATIC )
    self:bombVisualsTimer()
end

function ENT:bombVisualsTimer()
    local timePassed = CurTime() - spawnTime
    local timerDelay = math.Clamp( self.bombTimer / timePassed - 1, 0.13, 1 )
    
    timer.Simple( timerDelay, function()
        if not IsValid( self ) then return end
        self:RunCountdownEffects() 
    end)
end

function ENT:CreateLight()
    self.bombLight = ents.Create( "light_dynamic" )
    self.bombLight:SetPos( self:GetPos() + self:GetUp() * 10 )
    self.bombLight:SetKeyValue( "_light", 255, 0, 0, 200 )
    self.bombLight:SetKeyValue( "style", 0 )
    self.bombLight:SetKeyValue( "distance", 255 )
    self.bombLight:SetKeyValue( "brightness", 0 )
    self.bombLight:SetParent( self )
    self.bombLight:Spawn()
end

function ENT:CanDestroyProp( prop )
    if IsValid( prop ) and prop:MapCreationID() == -1 then
        local shouldDestroy = hook.Call( "CFC_SWEP_Shaped_Charge", entityToDestroy )
        
        if shouldDestroy ~= false then 
            return true
        end
    end
    return false
end
