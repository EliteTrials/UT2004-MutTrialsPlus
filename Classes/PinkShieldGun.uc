//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class PinkShieldGun Extends ShieldGunFix;

var xEmitter PinkRings;
var const color Pink;

Simulated Function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( Level.NetMode == NM_DedicatedServer )
		return;

	if( PinkRings == None )
		PinkRings = Spawn( Class'PinkRings', Self );
}

Simulated Exec Function SetShieldColor( optional color NewShieldColor )
{
	ClientWColor = Pink;
	ServerApplyNewColor( Pink );
	SetUpColor( Pink );
}

Simulated Function ClientWeaponThrown()
{
	Super.ClientWeaponThrown();
	if( PinkRings != None )
	{
		bDynamicLight = False;
		PinkRings.Destroy();
	}
}

Simulated Function bool PutDown()
{
	Super.PutDown();
	if( Level.NetMode == NM_DedicatedServer )
		return Super.PutDown();

	if( PinkRings != None )
	{
		bDynamicLight = False;
		PinkRings.Destroy();
	}
	return Super.PutDown();
}

Simulated Function BringUp( optional Weapon PrevWeapon )
{
	Super.Bringup(PrevWeapon);
	if( Level.NetMode == NM_DedicatedServer )
		return;

	bDynamicLight = True;
	if( PinkRings == None )
		PinkRings = Spawn( Class'PinkRings', Self );
}

Simulated Function Destroyed()
{
	Super.Destroyed();
	if( PinkRings != None )
		PinkRings.Destroy();
}

DefaultProperties
{
	Description="Pink ShieldGun"
	AttachmentClass=Class'PinkShieldAttachment'
	ItemName="Pink ShieldGun"
	LightType=LT_Steady
	LightEffect=LE_NonIncidence
	LightHue=213
	LightSaturation=60
	LightBrightness=150.0
	LightRadius=5.4
	LightPeriod=3
	bDynamicLight=True
	Skins[0]=None
	HighDetailOverlay=FinalBlend'UT2004Weapons.Shaders.PurpleShockFinal'
	Pink=(R=50,G=0,B=200,A=255)
	ClientWColor=(R=50,G=0,B=200,A=255)
}
