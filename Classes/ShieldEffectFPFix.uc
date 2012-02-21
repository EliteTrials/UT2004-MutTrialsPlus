//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
class ShieldEffectFPFix extends ShieldEffect;

var ColorModifier ColorMaterial;
var bool bOnFlashTex,bOldFlashTex;
var color LastSetColor;

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( Level.NetMode!=NM_DedicatedServer )
		AllocateColorMaterial();
}
simulated function Destroyed()
{
	MallocColorMaterial();
	Super.Destroyed();
}
simulated function Flash(int Drain)
{
	Brightness = FMin(Brightness + Drain / 2, 250.0);
	bOnFlashTex = True;
	SetShieldColor(LastSetColor,False);
	SetTimer(0.2, false);
}
simulated function SetShieldColor( color Col, bool bIsFlashing )
{
	if( Col==LastSetColor && bOldFlashTex==bOnFlashTex )
	{
		if( bIsFlashing && ColorMaterial!=None )
		{
			ColorMaterial.Color = Class'ShieldGunFix'.Static.GetFlashColor(Level.TimeSeconds/Level.TimeDilation);
			ColorMaterial.Color.A = Col.A;
		}
		Return;
	}
	bOldFlashTex = bOnFlashTex;
	LastSetColor = Col;
	if( bIsFlashing )
	{
		Col = Class'ShieldGunFix'.Static.GetFlashColor(Level.TimeSeconds/Level.TimeDilation);
		Col.A = LastSetColor.A;
	}
	if( ColorMaterial==None ) Return;
	ColorMaterial.Color = Col;
	ColorMaterial.AlphaBlend = True;
	ColorMaterial.RenderTwoSided = True;
	if( !bOnFlashTex )
		ColorMaterial.Material = Default.Skins[0];
	else ColorMaterial.Material = Default.Skins[1];
}
simulated function Timer()
{
	bOnFlashTex = False;
	SetShieldColor(LastSetColor,False);
}
simulated function AllocateColorMaterial()
{
	if( ColorMaterial==None )
		ColorMaterial = ColorModifier(Level.ObjectPool.AllocateObject(Class'ColorModifier'));
	Skins[0] = ColorMaterial;
	SetShieldColor(Class'EnhShieldAttachment'.Default.ShieldGunColor,False);
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
}
