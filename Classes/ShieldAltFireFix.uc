//==============================================================================
// Coded by .:..:
// Latest updated @ 30/10/07 by Eliot.
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class ShieldAltFireFix Extends ShieldAltFire;

function StartBerserk()
{
	FireRate /= 2;
	BotRefireRate /= 2;
}

function StopBerserk()
{
	FireRate *= 2;
	BotRefireRate *= 2;
}

function DrawMuzzleFlash( Canvas Canvas )
{
	if( bIsFiring && Weapon.AmmoAmount( 1 ) > 0 )
	{
		if( ShieldEffect == None )
			ShieldEffect = Weapon.Spawn(class'ShieldEffectFPFix', Instigator );

		if( ShieldGunFix(Weapon) != None )
			ShieldEffectFPFix(ShieldEffect).SetShieldColor( ShieldGunFix(Weapon).ClientWColor,ShieldGunFix(Weapon).bUseFadeColor );

		if( ShieldEffect != None )
		{
			ShieldEffect.SetLocation( Weapon.GetEffectStart() );
			ShieldEffect.SetRotation( Instigator.GetViewRotation() );
			Canvas.DrawActor( ShieldEffect, false, false, Weapon.DisplayFOV );
	    }
		Super(ShieldAltFire).DrawMuzzleFlash(Canvas);
	}
}
function DoFireEffect()
{
	local EnhShieldAttachment Attachment;

	Attachment = EnhShieldAttachment(Weapon.ThirdPersonActor);
	Instigator.AmbientSound = ChargingSound;
	Instigator.SoundVolume = ShieldSoundVolume;

	if( Attachment != None )
		Attachment.SetThirdFX(True);

	SetTimer(AmmoRegenTime, true);
}
function StopFiring()
{
	local EnhShieldAttachment Attachment;

    bIsFiring = False;
	Attachment = EnhShieldAttachment(Weapon.ThirdPersonActor);
	Instigator.AmbientSound = None;
	Instigator.SoundVolume = Instigator.Default.SoundVolume;
	if( Attachment!=None )
	{
		Attachment.SetThirdFX(False);
		StopForceFeedback( "ShieldNoise" );  // jdf
	}
	SetTimer(AmmoRegenTime, true);
}
function PlayFiring()
{
	local EnhShieldAttachment Attachment;

	bIsFiring = True;
	Attachment = EnhShieldAttachment(Weapon.ThirdPersonActor);
	if( Attachment != None )
		Attachment.SetThirdFX(True);
	Super.PlayFiring();

	Weapon.PlayOwnedSound( FireSound, SLOT_Interact, TransientSoundVolume,, TransientSoundRadius, Default.FireAnimRate/FireAnimRate, False );
    FireCount ++;
}
function TakeHit(int Drain)
{
	local EnhShieldAttachment Attachment;

	Attachment = EnhShieldAttachment(Weapon.ThirdPersonActor);
	if( Attachment!=None )
		Attachment.MakeDamageFlashFX();
	if( ShieldEffect!=None )
		ShieldEffect.Flash(Drain);
	SetBrightness(true);
}

DefaultProperties
{
	TransientSoundVolume=200
	FireRate=0.75
	BotRefireRate=0.9
}
