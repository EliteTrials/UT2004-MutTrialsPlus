//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class ShieldEffectFix extends Actor;

var color LastSetColor;
var bool bOnFlashTex,bOldFlashTex;
var ColorModifier ColorMaterial;
var ShieldSparks Sparks;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( Level.NetMode!=NM_DedicatedServer )
		AllocateColorMaterial();
}
simulated function SetShieldColor( color Col )
{
	if( Col==LastSetColor && bOldFlashTex==bOnFlashTex )
		Return;
	bOldFlashTex = bOnFlashTex;
	LastSetColor = Col;
	if( ColorMaterial==None ) Return;
	ColorMaterial.Color = Col;
	ColorMaterial.AlphaBlend = True;
	ColorMaterial.RenderTwoSided = True;
	if( !bOnFlashTex )
		ColorMaterial.Material = Default.Skins[0];
	else ColorMaterial.Material = Default.Skins[1];
}
simulated function Flash()
{
	if (Sparks == None)
		Sparks = Spawn(class'ShieldSparks');

	Sparks.mColorRange[0] = LastSetColor;
	Sparks.mColorRange[1] = LastSetColor;
	Sparks.SetLocation(Location+VRand()*8.0);
	Sparks.SetRotation(Rotation);
	Sparks.mStartParticles = 16;
	bOnFlashTex = True;
	SetShieldColor(LastSetColor);
	SetTimer(0.2, false);
}
simulated function FPFlash()
{
	if (Sparks == None)
		Sparks = Spawn(class'ShieldSparks');

	Sparks.mColorRange[0] = LastSetColor;
	Sparks.mColorRange[1] = LastSetColor;
	Sparks.SetLocation(Instigator.Location+Vect(0,0,20)+VRand()*12.0);
	Sparks.SetRotation(Rotation);
	Sparks.mStartParticles = 16;
}
simulated function Destroyed()
{
	MallocColorMaterial();
	if( Sparks!=None )
		Sparks.Destroy();
	Super.Destroyed();
}
simulated function Timer()
{
	bOnFlashTex = False;
	SetShieldColor(LastSetColor);
}

simulated function AllocateColorMaterial()
{
	if( ColorMaterial==None )
		ColorMaterial = ColorModifier(Level.ObjectPool.AllocateObject(Class'ColorModifier'));
	Skins[0] = ColorMaterial;
	SetShieldColor(Class'EnhShieldAttachment'.Default.ShieldGunColor);
}
simulated function MallocColorMaterial()
{
	if( ColorMaterial==None )
		Return;
	ColorMaterial.Material = None;
	ColorMaterial.Color = ColorMaterial.Default.Color;
	ColorMaterial.AlphaBlend = ColorMaterial.Default.AlphaBlend;
	ColorMaterial.RenderTwoSided = ColorMaterial.Default.RenderTwoSided;
	Level.ObjectPool.FreeObject(ColorMaterial);
	Skins = Default.Skins;
	ColorMaterial = None;
}

defaultproperties
{
	Skins(0)=DDFinallyBlend
	Skins(1)=XXDDFinallBlendd
	bNetNotify=False
	RemoteRole=ROLE_None
	DrawType=DT_StaticMesh
	StaticMesh=StaticMesh'WeaponStaticMesh.Shield'
	DrawScale=3.2
	bUnlit=true
	bHidden=true
	AmbientGlow=250
}
