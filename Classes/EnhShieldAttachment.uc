//==============================================================================
// EnhShieldAttachment.uc
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
class EnhShieldAttachment extends ShieldAttachment;

var color ShieldGunColor,OldUsedColor;
var ConstantColor ColorMaterial;
var Shader ShaderMaterial;
var texture AlphaTex;
var bool bPressingPriFire,bClientFiring,bHoldingAltFire,bClientAltFiring;
var float PrimFireBeginTime;
var ShieldCharge ChargeEmitter;
var ShieldEffectFix ThirdShieldFX;
var byte ThidShldDmgFlash;
const ThirdPersonChargeScal=2;
var protected bool bFlashColor;
var MNAFLinkedRep myLPRI;

replication
{
	reliable if( bNetDirty && (Role==ROLE_Authority) )
		ShieldGunColor;

	reliable if( bNetDirty && !bNetOwner && (Role==ROLE_Authority) )
		bPressingPriFire,bHoldingAltFire,ThidShldDmgFlash;
}

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( Level.NetMode!=NM_DedicatedServer )
		AllocateColorMaterial();
}
// Charged fire state change.
simulated function SetPrimFire( bool bFiring )
{
	bPressingPriFire = bFiring;
	if( Level.NetMode==NM_DedicatedServer )
		Return;
	bClientFiring = bFiring;
	if( !bFiring )
	{
		if( ChargeEmitter!=None )
			ChargeEmitter.mRegenPause = true;
		Return;
	}
	PrimFireBeginTime = Level.TimeSeconds;
	if( ChargeEmitter==None )
	{
		ChargeEmitter = Spawn(Class'ShieldCharge',Self);
		if( ChargeEmitter==None )
		{
			bClientFiring = False;
			Return;
		}
		if( ChargeEmitter != None )
		{
			ChargeEmitter.bOnlyOwnerSee = False;
			AttachToBone(ChargeEmitter, 'tip');
			ChargeEmitter.mColorRange[0] = ShieldGunColor;
			ChargeEmitter.mColorRange[1] = ShieldGunColor;
			ChargeEmitter.mSizeRange[0]*=ThirdPersonChargeScal;
			ChargeEmitter.mSizeRange[1]*=ThirdPersonChargeScal;
			ChargeEmitter.mPosDev*=ThirdPersonChargeScal;
			ChargeEmitter.mSpawnVecB*=ThirdPersonChargeScal;
		}
	}
	ChargeEmitter.mRegenPause = False;
}
// Activate third person shield FX.
simulated function SetThirdFX( bool bEnabledNow )
{
	bHoldingAltFire = bEnabledNow;
	if( Level.NetMode==NM_DedicatedServer || bClientAltFiring==bEnabledNow )
		Return;
	bClientAltFiring = bEnabledNow;
	if( ThirdShieldFX==None )
	{
		ThirdShieldFX = Spawn(Class'ShieldEffectFix',Self);
		AttachToBone(ThirdShieldFX, 'tip');
		ThirdShieldFX.SetShieldColor(ShieldGunColor);
	}
	ThirdShieldFX.bHidden = !bEnabledNow;
}
simulated function Destroyed()
{
	MallocColorMaterial();
	if( ChargeEmitter!=None )
		ChargeEmitter.Destroy();
	if( ThirdShieldFX!=None )
		ThirdShieldFX.Destroy();
	Super.Destroyed();
}
simulated function Tick( float Delta )
{
	local float Regen;
	local float ChargeScale;
	local color C;

	Super.Tick(Delta);
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

	if( ((myLPRI != None && myLPRI.FadingOn()) || bFlashColor) && Level.TimeSeconds-LastRenderTime<1.5 )
	{
		C = Class'ShieldGunFix'.Static.GetFlashColor(Level.TimeSeconds/Level.TimeDilation);
		C.A = ShieldGunColor.A;

		BeaconColor = C;
		if( ColorMaterial!=None )
			ColorMaterial.Color = C;
		if( ChargeEmitter!=None )
		{
			ChargeEmitter.mColorRange[0] = C;
			ChargeEmitter.mColorRange[1] = C;
		}
		if( ThirdShieldFX!=None && ThirdShieldFX.ColorMaterial!=None )
			ThirdShieldFX.ColorMaterial.Color = C;
		if( ForceRing3rd!=None )
		{
			ForceRing3rd.mColorRange[0] = C;
			ForceRing3rd.mColorRange[1] = C;
		}
	}
}
simulated function SetShieldgunColor( color NewColor )
{
	local LinkedReplicationInfo L;

	ShieldGunColor = NewColor;
	OldUsedColor = NewColor;

	if( Instigator == None || Instigator.PlayerReplicationInfo == None )
		return;

    for( L = Instigator.PlayerReplicationInfo.CustomReplicationInfo; L != None; L = L.NextReplicationInfo )
    {
		if( MNAFLinkedRep(L) != None )
		{
			myLPRI = MNAFLinkedRep(L);
			bFlashColor = (Level.NetMode!=NM_DedicatedServer && MNAFLinkedRep(L).FadingOn()); // Left in for other shield components :x to lazy to update.
			break;
		}
	}

	if( bFlashColor )
	{
		NewColor = Class'ShieldGunFix'.Static.GetFlashColor(Level.TimeSeconds/Level.TimeDilation);
		NewColor.A = ShieldGunColor.A;
	}

	BeaconColor = NewColor;
	if( ThirdShieldFX!=None )
		ThirdShieldFX.SetShieldColor(NewColor);

	if( ColorMaterial!=None )
	{
		ColorMaterial.Color = NewColor;

		if( myLPRI != None && myLPRI.TransOn() )
			ShaderMaterial.OutputBlending = OB_Translucent;
		else ShaderMaterial.OutputBlending = OB_Normal;
	}

	if( ChargeEmitter!=None )
	{
		ChargeEmitter.mColorRange[0] = NewColor;
		ChargeEmitter.mColorRange[1] = NewColor;
	}
}
function InitFor(Inventory I)
{
	Super(xWeaponAttachment).InitFor(I);
}
simulated function PostNetReceive()
{
	if( OldUsedColor!=ShieldGunColor )
		SetShieldgunColor(ShieldGunColor);
	if( bHoldingAltFire!=bClientAltFiring )
		SetThirdFX(bHoldingAltFire);
	if( bPressingPriFire!=bClientFiring )
		SetPrimFire(bPressingPriFire);
	if( ThidShldDmgFlash!=0 )
		MakeDamageFlashFX();
	Super.PostNetReceive();
}
simulated function MakeDamageFlashFX()
{
	if( Level.NetMode==NM_Client )
		ThidShldDmgFlash = 0;
	else if( ThidShldDmgFlash>=250 )
		ThidShldDmgFlash = 1;
	else ThidShldDmgFlash++;
	if( Level.NetMode!=NM_DedicatedServer && ThirdShieldFX!=None )
	{
		if( Instigator!=None && Instigator.IsFirstPerson() )
			ThirdShieldFX.FPFlash();
		else if( !ThirdShieldFX.bHidden && (Level.TimeSeconds-ThirdShieldFX.LastRenderTime)<0.5 )
			ThirdShieldFX.Flash();
	}
}
simulated function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();
	ThidShldDmgFlash = 0;
	if( ChargeEmitter!=None )
	{
		ChargeEmitter.mColorRange[0] = ShieldGunColor;
		ChargeEmitter.mColorRange[1] = ShieldGunColor;
	}
}
simulated function AllocateColorMaterial()
{
	if( ColorMaterial==None )
		ColorMaterial = ConstantColor(Level.ObjectPool.AllocateObject(Class'ConstantColor'));

	if( ShaderMaterial == None )
		ShaderMaterial = Shader(Level.ObjectPool.AllocateObject( Class'Shader' ) );

	ShaderMaterial.Diffuse = AlphaTex;			// Alpha Tex.
	ShaderMaterial.Specular = ColorMaterial;	// Constant Color.
	ShaderMaterial.SpecularityMask = AlphaTex;	// Alpha Tex.
	ShaderMaterial.Detail = Skins[0];			// Normal Tex.
	ShaderMaterial.DetailScale = 1.0;
	Skins[0] = ShaderMaterial;
	SetShieldgunColor(ShieldGunColor);
}
simulated function MallocColorMaterial()
{
	if( ColorMaterial==None && ShaderMaterial == None )
		return;

	ShaderMaterial.Diffuse = None;
	ShaderMaterial.Specular = None;
	ShaderMaterial.SpecularityMask = None;
	ShaderMaterial.Detail = None;
	ShaderMaterial.DetailScale = 8.0;
	Level.ObjectPool.FreeObject(ColorMaterial);
	ColorMaterial = None;
	Level.ObjectPool.FreeObject( ShaderMaterial );
	ShaderMaterial = None;
	Skins = Default.Skins;
}

Simulated Event ThirdPersonEffects()
{
	if( Level.NetMode != NM_DedicatedServer && FlashCount > 0 )
	{
		if( FiringMode == 0 )
		{
            ForceRing:
            if( ForceRing3rd != None )
            {
				ForceRing3rd.mColorRange[0] = ShieldGunColor;
				ForceRing3rd.mColorRange[1] = ShieldGunColor;
				ForceRing3rd.Fire();
			}
			else
			{
				ForceRing3rd = Spawn( Class'ForceRing' );
				AttachToBone( ForceRing3rd, 'tip' );
				Goto 'ForceRing';
            }
		}
	}
	Super(xWeaponAttachment).ThirdPersonEffects();
}

DefaultProperties
{
	ShieldGunColor=(R=50,G=255,B=50,A=255)
	bNetNotify=True
	Skins[0]=Texture'ShieldTex1'
	AlphaTex=Texture'ShieldTexAlpha'
	bMatchWeapons=True
	BeaconColor=(R=50,G=255,B=50,A=255)
	HighDetailOverlay=None
}
