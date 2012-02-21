//==============================================================================
// Coded by .:..:
// Latest updated @ v1I_Test5 by Eliot.
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class ShieldFireFix Extends ShieldFire;

Function bool IsFriendlyFire( Actor HitTarget )
{
	local Pawn P;

	P = Pawn(HitTarget);
	if( P == None || P.PlayerReplicationInfo == None || Instigator.PlayerReplicationInfo == None || P.PlayerReplicationInfo.Team == None || Instigator.PlayerReplicationInfo.Team == None )
		return False;
	if( P.PlayerReplicationInfo.Team==Instigator.PlayerReplicationInfo.Team )
		return True;
	return False;
}

Function Actor GetHitTarget( optional out vector HitLocation )
{
	local Vector HitNormal, StartTrace, EndTrace;
	local Rotator Aim;
	local Actor A;
	local byte HCount;

	StartTrace = Instigator.Location;
	Aim = AdjustAim( StartTrace, AimError );
	EndTrace = StartTrace + ShieldRange * Vector(Aim);
	ForEach Instigator.TraceActors( Class'Actor',A,HitLocation,HitNormal,EndTrace,StartTrace )
	{
		if( A != Instigator && (A==Level || (A.bCollideActors && (A.bProjTarget || A.bBlockActors)) || A.IsA('TerrainInfo')) && !IsFriendlyFire(A) )
			Return A;
		HCount++;
		if( HCount>=150 )
			Return None;
	}
	Return None;
}

function float PredictMomentum()
{
	local vector X, Y, Z;
	local float Scale, Force;

	Weapon.GetViewAxes( X, Y, Z );
	Scale = (FClamp(HoldTime, MinHoldTime, FullyChargedTime) - MinHoldTime) / (FullyChargedTime - MinHoldTime);
	Force = MinForce + Scale * (MaxForce - MinForce);

	Z = (-SelfForceScale*Force*X);

	// Predict what TakeDamage does
	Z.Z = FMax( Z.Z, 0.4 * VSize( Z ) );

	// Yes self hurt

	Z *= 0.6;

	Z /= Instigator.Mass;

	// Predict what AddVelocity does
	if( Instigator.Velocity.Z > 380 && Z.Z > 0 )
		Z.Z *= 0.5;

	return VSize( Instigator.Velocity+Z )*0.25/*UU*/;
}

Function DoFireEffect()
{
	local Vector X,Y,Z, HitLocation;
	local Actor Other;
	local float Scale, Damage, Force;

	Instigator.MakeNoise(1.0);
	Weapon.GetViewAxes(X,Y,Z);
	bAutoRelease = false;

	if( (AutoHitPawn != None) && (Level.TimeSeconds - AutoHitTime < 0.15) )
	{
		Other = AutoHitPawn;
		HitLocation = Other.Location;
		AutoHitPawn = None;
	}
	else Other = GetHitTarget(HitLocation); // Check target, if its friendly it will return.

	Scale = (FClamp(HoldTime, MinHoldTime, FullyChargedTime) - MinHoldTime) / (FullyChargedTime - MinHoldTime); // result 0 to 1
	Damage = MinDamage + Scale * (MaxDamage - MinDamage);
	Force = MinForce + Scale * (MaxForce - MinForce);

	Instigator.AmbientSound = None;
	Instigator.SoundVolume = Instigator.Default.SoundVolume;

	if( ChargingEmitter != None )
		ChargingEmitter.mRegenPause = true;

	if( Other != None && Other != Instigator )
	{
		if( Pawn(Other) != None || (Decoration(Other) != None && Decoration(Other).bDamageable) )
        	Other.TakeDamage(Damage, Instigator, HitLocation, Force*(X+vect(0,0,0.5)), DamageType);
		else
		{
			if( xPawn(Instigator).bBerserk )
				Force *= 2.0;
			Instigator.TakeDamage(MinSelfDamage+SelfDamageScale*Damage, Instigator, HitLocation, -SelfForceScale*Force*X, DamageType);
			if( DestroyableObjective(Other) != None )
		      	Other.TakeDamage(Damage, Instigator, HitLocation, Force*(X+vect(0,0,0.5)), DamageType);
		}
	}
	SetTimer(0, false);
}

function ServerPlayFiring()
{
	if( EnhShieldAttachment(Weapon.ThirdPersonActor) != None )
		EnhShieldAttachment(Weapon.ThirdPersonActor).SetPrimFire(False);
	Super.ServerPlayFiring();
}

function ModeHoldFire()
{
	if( EnhShieldAttachment(Weapon.ThirdPersonActor) != None )
		EnhShieldAttachment(Weapon.ThirdPersonActor).SetPrimFire(True);
	Super.ModeHoldFire();
}

// Overwritten to avoid AutoRelease when MaxHoldTime is used
Function ModeDoFire()
{
    if( !AllowFire() )
        return;

	if( MaxHoldTime > 0.0f )
		HoldTime = FMin( HoldTime, MaxHoldTime-0.005 );

	Super.ModeDoFire();
}

Function Timer()
{
	local Actor Other;
	local float Regen;
	local float ChargeScale;

	if( HoldTime > 0.0 && !bNowWaiting )
	{
		Other = GetHitTarget();
		if( (Pawn(Other) != None) && (Other != Instigator) && (!Other.IsA('Pickup')) )
		{
			bAutoRelease = True;
			bIsFiring = False;
			Instigator.AmbientSound = None;
			Instigator.SoundVolume = Instigator.Default.SoundVolume;
			AutoHitPawn = Pawn(Other);
			AutoHitTime = Level.TimeSeconds;
			if( ChargingEmitter != None )
				ChargingEmitter.mRegenPause = True;
		}
		else
		{
			Instigator.AmbientSound = ChargingSound;
			Instigator.SoundVolume = ChargingSoundVolume;

			ChargeScale = FMin(HoldTime, FullyChargedTime);
			if( ChargingEmitter != None )
			{
				ChargingEmitter.mRegenPause = False;
				Regen = ChargeScale * 10 + 20;
				ChargingEmitter.mRegenRange[0] = Regen;
				ChargingEmitter.mRegenRange[1] = Regen;
				ChargingEmitter.mSpeedRange[0] = ChargeScale * -15.0;
				ChargingEmitter.mSpeedRange[1] = ChargeScale * -15.0;
				Regen = FMax((ChargeScale / 30.0),0.20);
				ChargingEmitter.mLifeRange[0] = Regen;
				ChargingEmitter.mLifeRange[1] = Regen;
			}
			if( !bStartedChargingForce )
			{
				bStartedChargingForce = True;
				ClientPlayForceFeedback( ChargingForce );
			}
		}
	}
	else
	{
		if( Instigator.AmbientSound == ChargingSound )
		{
			Instigator.AmbientSound = None;
			Instigator.SoundVolume = Instigator.Default.SoundVolume;
		}
		SetTimer(0, False);
	}
}

function DrawMuzzleFlash(Canvas Canvas)
{
	local color C;

	if( ShieldGunFix(Weapon)!=None )
	{
		if( ShieldGunFix(Weapon).bUseFadeColor )
		{
			C = Class'ShieldGunFix'.Static.GetFlashColor(Level.TimeSeconds/Level.TimeDilation);
			C.A = ShieldGunFix(Weapon).ClientWColor.A;
		}
		else C = ShieldGunFix(Weapon).ClientWColor;

		if( ChargingEmitter!=None )
		{
			ChargingEmitter.mColorRange[0] = C;
			ChargingEmitter.mColorRange[1] = C;
		}

		if( FlashEmitter!=None )
		{
			FlashEmitter.mColorRange[0] = C;
			FlashEmitter.mColorRange[1] = C;
		}
	}
	Super.DrawMuzzleFlash(Canvas);
}

function PlayFiring()
{
	EnhShieldAttachment(Weapon.ThirdPersonActor).SetPrimFire(False);
	Super.PlayFiring();
}

DefaultProperties
{
	DamageType=Class'DamTypeShieldFireFix'
	TransientSoundVolume=160
	ChargingSoundVolume=220
}
