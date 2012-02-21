//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
// Designed for abaddon, Mayan, keep this shieldgun pink
//==============================================================================
Class PinkShieldAttachment Extends EnhShieldAttachment;

var const color Pink;

simulated function AllocateColorMaterial();
simulated function MallocColorMaterial();

Simulated Function PostBeginPlay()
{
	Super(ShieldAttachment).PostBeginPlay();
}

Simulated Function PostNetReceive()
{
	Super(ShieldAttachment).PostNetReceive();
	if( OldUsedColor!=ShieldGunColor )
		SetShieldgunColor(Pink);
	if( bHoldingAltFire!=bClientAltFiring )
		SetThirdFX(bHoldingAltFire);
	if( bPressingPriFire!=bClientFiring )
		SetPrimFire(bPressingPriFire);
	if( ThidShldDmgFlash!=0 )
		MakeDamageFlashFX();
}

Simulated Function SetShieldgunColor( color NewColor )
{
	if( ThirdShieldFX != None )
		ThirdShieldFX.SetShieldColor( Pink );
	BeaconColor = Pink;
	ShieldGunColor = Pink;
	OldUsedColor = Pink;
	if( ChargeEmitter != None )
	{
		ChargeEmitter.mColorRange[0] = Pink;
		ChargeEmitter.mColorRange[1] = Pink;
	}
}

Simulated Function SetThirdFX( bool bEnabledNow )
{
	Super.SetThirdFX(bEnabledNow);
	if( ThirdShieldFX != None )
		ThirdShieldFX.SetShieldColor( Pink );
}

Simulated Function Tick( float Delta )
{
	local float Regen;
	local float ChargeScale;

	Super(ShieldAttachment).Tick(Delta);
	if( bClientFiring )
	{
		ChargeScale = FMin((Level.TimeSeconds-PrimFireBeginTime),Class'ShieldFireFix'.Default.FullyChargedTime);
		Regen = ChargeScale * 10 + 20;
		ChargeEmitter.mRegenRange[0] = Regen;
		ChargeEmitter.mRegenRange[1] = Regen;
		ChargeEmitter.mSpeedRange[0] = ChargeScale * -15.0 * ThirdPersonChargeScal;
		ChargeEmitter.mSpeedRange[1] = ChargeScale * -15.0 * ThirdPersonChargeScal;
		Regen = FMax((ChargeScale / 30.0),0.20);
		ChargeEmitter.mLifeRange[0] = Regen;
		ChargeEmitter.mLifeRange[1] = Regen;
	}
}

DefaultProperties
{
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightHue=213
	LightSaturation=60
	LightBrightness=150.000000
	LightRadius=5.400000
	LightPeriod=3
	bDynamicLight=False
	Skins[0]=FinalBlend'UT2004Weapons.Shaders.PurpleShockFinal'
	//HighDetailOverlay=FinalBlend'UT2004Weapons.Shaders.PurpleShockFinal'

	Pink=(R=50,G=0,B=200,A=255)
	ShieldGunColor=(R=50,G=0,B=200,A=255)
}
