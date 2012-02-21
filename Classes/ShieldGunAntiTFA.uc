//=============================================================================
// Shield Gun to make tfa not find a shieldgun to replace.
// Not sure if this still is needed.
//=============================================================================
Class ShieldGunAntiTFA Extends Weapon
      HideDropDown;

var Sound       ShieldHitSound;
var String      ShieldHitForce;

replication
{
	reliable if (Role == ROLE_Authority)
		ClientTakeHit;
}

simulated function DoAutoSwitch()
{
}

simulated event RenderOverlays( Canvas Canvas )
{
	local int m;

	if ((Hand < -1.0) || (Hand > 1.0))
	{
		for (m = 0; m < NUM_FIRE_MODES; m++)
		{
			if (FireMode[m] != None)
				FireMode[m].DrawMuzzleFlash(Canvas);
		}
	}
	Super.RenderOverlays(Canvas);
}

// AI Interface
function GiveTo(Pawn Other, optional Pickup Pickup)
{
    Super.GiveTo(Other, Pickup);

    if ( Bot(Other.Controller) != None )
        Bot(Other.Controller).bHasImpactHammer = true;
}

function bool CanAttack(Actor Other)
{
    return true;
}

function FireHack(byte Mode)
{
    if ( Mode == 0 )
    {
        FireMode[0].PlayFiring();
        FireMode[0].FlashMuzzleFlash();
        FireMode[0].StartMuzzleSmoke();
        IncrementFlashCount(0);
    }
}

/* BestMode()
choose between regular or alt-fire
*/
function byte BestMode()
{
    local float EnemyDist;
    local bot B;

    B = Bot(Instigator.Controller);
    if ( (B == None) || (B.Enemy == None) )
        return 1;

    if ( B.bShieldSelf && B.ShouldKeepShielding() )
        return 1;

    EnemyDist = VSize(B.Enemy.Location - Instigator.Location);
    if ( EnemyDist > 4 * Instigator.GroundSpeed )
        return 1;
    if ( (B.MoveTarget != B.Enemy) && (B.IsRetreating() || (EnemyDist > 2 * Instigator.GroundSpeed)) )
        return 1;
    return 0;
}

// super desireable for bot waiting to impact jump
function float GetAIRating()
{
    local Bot B;
    local float EnemyDist;

    B = Bot(Instigator.Controller);
    if ( B == None )
        return AIRating;

    if ( B.bShieldSelf && B.ShouldKeepShielding() )
        return 9;

    if ( B.bPreparingMove && (B.ImpactTarget != None) )
        return 9;

    if ( B.PlayerReplicationInfo.HasFlag != None )
    {
        if ( Instigator.Health < 50 )
            return AIRating + 0.35;
        return AIRating + 0.25;
    }

    if ( B.Enemy == None )
        return AIRating;

    EnemyDist = VSize(B.Enemy.Location - Instigator.Location);
    if ( B.Stopped() && (EnemyDist > 100) )
        return 0.1;

    if ( (EnemyDist < 750) && (B.Skill <= 2) && !B.Enemy.IsA('Bot') && (ShieldGun(B.Enemy.Weapon) != None) )
        return FClamp(300/(EnemyDist + 1), 0.6, 0.75);

    if ( EnemyDist > 400 )
        return 0.1;
    if ( (Instigator.Weapon != self) && (EnemyDist < 120) )
        return 0.25;

    return ( FMin(0.6, 90/(EnemyDist + 1)) );
}

// End AI interface

function DoReflectEffect(int Drain)
{
	PlaySound(ShieldHitSound, SLOT_None);
	ShieldAltFire(FireMode[1]).TakeHit(Drain);
	ClientTakeHit(Drain);
}

simulated function ClientTakeHit(int Drain)
{
	ClientPlayForceFeedback(ShieldHitForce);
	ShieldAltFire(FireMode[1]).TakeHit(Drain);
}

simulated function float AmmoStatus(optional int Mode) // returns float value for ammo amount
{
	if ( Instigator == None || Instigator.Weapon != self )
	{
		if ( (FireMode[1].TimerInterval != 0.f) && (FireMode[1].NextTimerPop < Level.TimeSeconds) )
		{
			FireMode[1].Timer();
			if ( FireMode[1].bTimerLoop )
				FireMode[1].NextTimerPop = FireMode[1].NextTimerPop + FireMode[1].TimerInterval;
			else FireMode[1].TimerInterval = 0.f;
		}
	}
	return Super.AmmoStatus(Mode);
}


function bool CheckReflect( Vector HitLocation, out Vector RefNormal, int AmmoDrain )
{
	local Vector HitDir;
	local Vector FaceDir;

	if (!FireMode[1].bIsFiring || AmmoAmount(0) == 0) return false;

	FaceDir = Vector(Instigator.Controller.Rotation);
	HitDir = Normal(Instigator.Location - HitLocation + Vect(0,0,8));
	//Log(self@"HitDir"@(FaceDir dot HitDir));

	RefNormal = FaceDir;

	if ( FaceDir dot HitDir < -0.37 ) // 68 degree protection arc
	{
		if (AmmoDrain > 0)
			ConsumeAmmo(0,AmmoDrain);
		return true;
	}
	return false;
}

function AnimEnd(int channel)
{
    if (FireMode[0].bIsFiring)
    {
        LoopAnim('Charged');
    }
    else if (!FireMode[1].bIsFiring)
    {
        Super.AnimEnd(channel);
    }
}

function float SuggestAttackStyle()
{
    return 0.8;
}

function float SuggestDefenseStyle()
{
    return -0.8;
}

simulated function float ChargeBar()
{
    return FMin(1,FireMode[0].HoldTime/ShieldFire(FireMode[0]).FullyChargedTime);
}

defaultproperties
{
     ShieldHitSound=ProceduralSound'WeaponSounds.ShieldGun.ShieldReflection'
     ShieldHitForce="ShieldReflection"

     PutDownAnim="PutDown"
     SelectSound=Sound'WeaponSounds.Misc.shieldgun_change'
     SelectForce="ShieldGun_change"
     AIRating=0.350000
     CurrentRating=0.350000
     bMeleeWeapon=True
     bShowChargingBar=True
     bCanThrow=False
     Description="The Kemphler DD280 Riot Control Device has the ability to resist and reflect incoming projectiles and energy beams. The plasma wave inflicts massive damage, rupturing tissue, pulverizing organs, and flooding the bloodstream with dangerous gas bubbles.||This weapon may be intended for combat at close range, but when wielded properly should be considered as dangerous as any other armament in your arsenal."
     EffectOffset=(X=15.000000,Y=5.500000,Z=2.000000)
     DisplayFOV=60.000000
     Priority=2
     HudColor=(B=121,G=188)
     SmallViewOffset=(X=10.000000,Y=3.300000,Z=-6.700000)
     CenteredOffsetY=-9.000000
     CenteredRoll=1000
     CustomCrosshair=6
     CustomCrossHairColor=(B=121,G=188)
     CustomCrossHairTextureName="Crosshairs.Hud.Crosshair_Pointer"
     PickupClass=Class'XWeapons.ShieldGunPickup'
     PlayerViewOffset=(X=2.000000,Y=-0.700000,Z=-2.700000)
     PlayerViewPivot=(Pitch=500,Yaw=500)
     BobDamping=2.200000
     IconMaterial=Texture'HUDContent.Generic.HUD'
     IconCoords=(X1=169,Y1=39,X2=241,Y2=77)
     ItemName="ShieldGun"
     Mesh=SkeletalMesh'Weapons.ShieldGun_1st'
     DrawScale=0.400000
     HighDetailOverlay=Combiner'UT2004Weapons.WeaponSpecMap2'
}
