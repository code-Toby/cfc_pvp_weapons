AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

local swingSound = "weapons/bat_draw_swoosh2.wav"
local hitSound = "weapons/demo_charge_hit_world2.wav"

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()

    local tr = util.TraceLine( {
        start = ply:EyePos(),
        endpos = ply:EyePos() + ply:EyeAngles():Forward() * 70,
        filter = ply,
        mask = MASK_ALL
    } )

    local ent = tr.Entity

    if IsValid( ent ) then
        local entPhys = ent:GetPhysicsObject()
        self:SendWeaponAnim( ACT_VM_HITCENTER );

        ply:SetAnimation( PLAYER_ATTACK1 );
        ply:EmitSound( hitSound )

        if ent:IsPlayer() || ent:IsNPC() then
            ent:SetVelocity( ply:EyeAngles():Forward() * 450 )
            ply:SetVelocity( ply:EyeAngles():Forward() * -250 )
        end
        if not ent:IsWorld() && not ent:IsPlayer() && not ent:IsNPC() then
            entPhys:ApplyForceCenter( ply:EyeAngles():Forward() * 200 * entPhys:GetMass() )
            ply:SetVelocity( ply:EyeAngles():Forward() * -130)
        end

        ent:TakeDamage(20, ply, self)
    elseif not IsValid( ent ) && not ent:IsWorld() then
        self:SendWeaponAnim( ACT_VM_HITCENTER );

        ply:SetAnimation( PLAYER_ATTACK1 );
        ply:EmitSound( swingSound )
    elseif not IsValid( ent ) && ent:IsWorld() then
        self:SendWeaponAnim( ACT_VM_HITCENTER );

        ply:SetAnimation( PLAYER_ATTACK1 );
        ply:EmitSound( hitSound )

        ply:SetVelocity( ply:EyeAngles():Forward() * -250 )
    end

    self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
end

function SWEP:SecondaryAttack()
end