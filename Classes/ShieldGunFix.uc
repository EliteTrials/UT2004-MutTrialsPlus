//==============================================================================
// ShieldGunFix.uc
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class ShieldGunFix Extends ShieldGunAntiTFA;

var color ClientWColor, BotRandomColor, LastUsedColorC;
var bool bColorHasBeenSet, bBotChosenColor;
var ColorModifier IconColorMaterial;
var ConstantColor ColorMaterial;
var Shader ShaderMaterial;
var texture AlphaTex;
var bool bUseFadeColor, bTranslucent;

var float RepeatTimer, LastColorTime;

var bool bAllowAltGlitch;

var bool bDrawUUDB;

var MNAFSavedData Options;

Replication
{
	reliable if( Role < ROLE_Authority )
		ServerApplyNewColor, ServerUpdateShieldTypes;

	reliable if( Role == ROLE_Authority )
		UpdateShieldTypes;
}

Simulated Function PostBeginPlay()
{
	Super.PostBeginPlay();
	if( Level.NetMode != NM_DedicatedServer )
	{
		Options = Class'MNAFSavedData'.Static.FindSavedData();

		AllocateColorMaterial();
		AllocateIconMaterial();
	}
}

Simulated Function PostNetBeginPlay()
{
	Super.PostNetBeginPlay();

	if( Instigator != None )
		Instigator.SwitchWeapon( 1 );
}

Function AttachToPawn(Pawn P)
{
	Super.AttachToPawn(P);
	ServerApplyNewColor( ClientWColor );
}

Simulated Exec Function ShieldGunMenu()
{
	if( Instigator != None && PlayerController(Instigator.Controller) != None )
		PlayerController(Instigator.Controller).ClientOpenMenu( string( Class'MNAF_Menu' ) );
}

Simulated Exec Function MNAFMenu()
{
	if( Instigator != None && PlayerController(Instigator.Controller) != None )
		PlayerController(Instigator.Controller).ClientOpenMenu( string( Class'MNAF_Menu' ) );
}

Simulated Exec Function ShieldMenu()
{
	if( Instigator != None && PlayerController(Instigator.Controller) != None )
		PlayerController(Instigator.Controller).ClientOpenMenu( string( Class'MNAF_Menu' ) );
}

Simulated Exec Function SGMenu()
{
	if( Instigator != None && PlayerController(Instigator.Controller) != None )
		PlayerController(Instigator.Controller).ClientOpenMenu( string( Class'MNAF_Menu' ) );
}

Simulated Function bool IsAdmin()
{
	return (Level.NetMode==NM_StandAlone || (Instigator!=None && Instigator.PlayerReplicationInfo!=None && Instigator.PlayerReplicationInfo.bAdmin));
}

Function AdjustPlayerDamage( out int Damage, Pawn InstigatedBy, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType )
{
	local int Drain;
	local vector Reflect;
	local vector HitNormal;
	local float DamageMax;

	DamageMax = 100.0;
	if( DamageType == class'Fell' )
		DamageMax = 20.0;
	else if( !bAllowAltGlitch && (!DamageType.default.bArmorStops || DamageType == Class'DamTypeShieldFireFix') )
		return;

	if( CheckReflect(HitLocation, HitNormal, 0) )
	{
		Drain = Min( AmmoAmount(1)*2, Damage );
		Drain = Min(Drain,DamageMax);
		Reflect = MirrorVectorByNormal( Normal(Location - HitLocation), Vector(Instigator.Rotation) );
		Damage -= Drain;
		Momentum *= 1.25;

		// Only the enemie or yourself can pass this
		//if( InstigatedBy.GetTeamNum() != Instigator.GetTeamNum() || (InstigatedBy == Instigator && InstigatedBy != None) )	// New
		//{
			if( (Instigator != None) && (Instigator.PlayerReplicationInfo != None) && (Instigator.PlayerReplicationInfo.HasFlag != None) )
			{
				Drain = Min(AmmoAmount(1), Drain);
				ConsumeAmmo(1,Drain);
				DoReflectEffect(Drain);
			}
			else
			{
				ConsumeAmmo(1,Drain/2);
				DoReflectEffect(Drain/2);
			}
		//}
	}
}

Function DoReflectEffect( int Drain )
{
	MakeNoise( 0.2 );	// New

	// Change = bNoOverride = TRUE
	PlaySound( ShieldHitSound, SLOT_None, 1.1*TransientSoundVolume, True );
	ShieldAltFire(FireMode[1]).TakeHit( Drain );
	ClientTakeHit( Drain );
}

Simulated Function bool CanUseUniqueColor()
{
	local LinkedReplicationInfo L;

	if( Instigator == None || Instigator.PlayerReplicationInfo == None )
		return False;

	for( L = Instigator.PlayerReplicationInfo.CustomReplicationInfo; L != None; L = L.NextReplicationInfo )
	{
		if( MNAFLinkedRep(L) != None )
			return MNAFLinkedRep(L).IsUnique();
	}
	return False;
}

simulated exec function SetShieldColor( optional color NewShieldColor )
{
	if( RepeatTimer > Level.TimeSeconds )
		return;

	RepeatTimer = Level.TimeSeconds+1.5;

	if( NewShieldColor.A == 0 )
		NewShieldColor.A = Options.ClientChosenColor.A;

	if( NewShieldColor.R == 0 )
		NewShieldColor.R = Options.ClientChosenColor.R;

	if( NewShieldColor.G == 0 )
		NewShieldColor.G = Options.ClientChosenColor.G;

	if( NewShieldColor.B == 0 )
		NewShieldColor.B = Options.ClientChosenColor.B;

	Options.ClientChosenColor = NewShieldColor;
	ClientWColor = NewShieldColor;
	ServerApplyNewColor(NewShieldColor);
	SetUpColor(NewShieldColor);
	ApplyIconMaterialColor();
	Options.SaveConfig();
}

simulated exec function ToggleCrosshairColor()
{
	Options.bDisableCustomCrossHairColor = !Options.bDisableCustomCrossHairColor;
	Options.SaveConfig();
}

function ServerApplyNewColor( Color NewC )
{
	ClientWColor = NewC;
	SetUpColor(NewC);
	if( EnhShieldAttachment(ThirdPersonActor) != None )
		EnhShieldAttachment(ThirdPersonActor).SetShieldGunColor(NewC);
}

simulated function SetUpColor( color C )
{
	if( ColorMaterial!=None )
	{
		ColorMaterial.Color = C;

		if( IconColorMaterial != None )
			IconColorMaterial.Color = C;
	}
}

simulated function WeaponTick( float Delta )
{
	local byte A;
	local vector HitL;

	Super.WeaponTick(Delta);
	if( Level.NetMode != NM_DedicatedServer )
	{
		if( CanUseUniqueColor() && (ColorMaterial != None && IconColorMaterial != None) )
		{
			// Updates the fading color
			if( bUseFadeColor )
			{
				ColorMaterial.Color = GetFlashColor(Level.TimeSeconds/Level.TimeDilation);
				IconColorMaterial.Color = ColorMaterial.Color;
				ColorMaterial.Color.A = ClientWColor.A;
				IconColorMaterial.Color.A = 255;
				HUDColor = ColorMaterial.Color;
				CustomCrossHairColor = ColorMaterial.Color;
			}
		}

		if( Options.bDisableCustomCrossHairColor )
			return;

		A = CustomCrossHairColor.A;

		// Can fire?
		if( ReadyToFire( 0 ) && ClientState == WS_ReadyToFire && FireMode[0].HoldTime == 0.0f )
			CustomCrossHairColor = Class'HUD'.Default.GoldColor;
		else CustomCrossHairColor = Class'HUD'.Default.WhiteColor;

		// Will hit?
		if( ShieldFireFix(FireMode[0]).GetHitTarget( HitL ) != None )
			CustomCrossHairColor.A = A;
		else CustomCrossHairColor.A = A*0.75;
	}
}

exec function DrawUUDB( bool bDraw )
{
	bDrawUUDB = bDraw;
}

simulated event RenderOverlays( Canvas C )
{
	local string S;
	local float XL, YL;

	Super.RenderOverlays(C);

	if( bDrawUUDB )
	{
		S = "UU Distance Boost:"$int(ShieldFireFix(FireMode[0]).PredictMomentum());

		C.StrLen( S, XL, YL );

		C.SetPos( (C.ClipX*0.5)-(XL*0.5), C.ClipY*0.55 );

		C.DrawColor = Class'HUD'.Default.GrayColor;
		C.Font = C.Default.Font;
		C.DrawText( S, True );
	}
}

simulated function vector CenteredEffectStart()
{
	local Vector X,Y,Z;

	GetViewAxes(X, Y, Z);
	return (Instigator.Location + Instigator.CalcDrawOffset(self) + EffectOffset.X * X + EffectOffset.Z * Z);
}

simulated function BringUp(optional Weapon PrevWeapon)
{
	if( !bColorHasBeenSet && Instigator != None && Instigator.IsLocallyControlled() )
		SetUpInitialColor();

	Super.BringUp(PrevWeapon);

	// Normal ShieldGun Code
	if ( !AmmoMaxed(1) )
	{
		while ( (FireMode[1].NextTimerPop < Level.TimeSeconds) && (FireMode[1].TimerInterval > 0.f) )
		{
			FireMode[1].Timer();
			if ( FireMode[1].bTimerLoop )
				FireMode[1].NextTimerPop = FireMode[1].NextTimerPop + FireMode[1].TimerInterval;
			else FireMode[1].TimerInterval = 0.f;
		}
	}
}

simulated function AllocateColorMaterial()
{
	if( ColorMaterial == None )
		ColorMaterial = ConstantColor(Level.ObjectPool.AllocateObject( Class'ConstantColor' ));

	if( ShaderMaterial == None )
		ShaderMaterial = Shader(Level.ObjectPool.AllocateObject( Class'Shader' ) );

	ShaderMaterial.Diffuse = AlphaTex;			// Alpha Tex.
	ShaderMaterial.Specular = ColorMaterial;	// Constant Color.
	ShaderMaterial.SpecularityMask = AlphaTex;	// Alpha Tex.
	ShaderMaterial.Detail = Skins[0];			// Normal Tex.
	ShaderMaterial.DetailScale = 1.0;
	Skins[0] = ShaderMaterial;
	SetUpColor(Options.ClientChosenColor);
}

simulated function MallocColorMaterial()
{
	if( ColorMaterial != None )
	{
		ShaderMaterial.Diffuse = None;
		ShaderMaterial.Specular = None;
		ShaderMaterial.SpecularityMask = None;
		ShaderMaterial.Detail = None;
		ShaderMaterial.DetailScale = 8.0;
		ColorMaterial.Color = ColorMaterial.Default.Color;
		Level.ObjectPool.FreeObject( ColorMaterial );
		ColorMaterial = None;
	}

	if( ShaderMaterial == None )
		return;

	Level.ObjectPool.FreeObject( ShaderMaterial );
	ShaderMaterial = None;
	Skins = Default.Skins;
}

simulated function Destroyed()
{
	MallocColorMaterial();
	MallocIconMaterial();
	Super.Destroyed();
}

simulated function SetUpInitialColor()
{
	bColorHasBeenSet = True;
	if( Level.NetMode != NM_Client && PlayerController(Instigator.Controller) == None )
	{
		if( !bBotChosenColor )
		{
			bBotChosenColor = True;
			BotRandomColor.R = Rand(255);
			BotRandomColor.G = Rand(255);
			BotRandomColor.B = Rand(255);
			BotRandomColor.A = 128+Rand(128);
		}
		ClientWColor = BotRandomColor;
		HudColor = BotRandomColor;
		ServerApplyNewColor(BotRandomColor);
	}
	else
	{
		ClientWColor = Options.ClientChosenColor;
		HudColor = ClientWColor;
		ApplyIconMaterialColor();
		ServerApplyNewColor(ClientWColor);
		UpdateShieldTypes();
 		if( ShaderMaterial != None )
		{
			if( bTranslucent )
				ShaderMaterial.OutputBlending = OB_Translucent;
			else ShaderMaterial.OutputBlending = OB_Normal;
		}
	}
}

// Eliot.
Simulated Function AllocateIconMaterial()
{
	if( IconColorMaterial == None )
		IconColorMaterial = ColorModifier(Level.ObjectPool.AllocateObject( Class'ColorModifier' ));

	IconColorMaterial.Material = Texture'ShieldHud';
	IconMaterial = IconColorMaterial;
}

Simulated Function MallocIconMaterial()
{
	IconMaterial = Default.IconMaterial;

	if( IconColorMaterial == None )
		return;

	IconColorMaterial.Color = IconColorMaterial.Default.Color;
	IconColorMaterial.Material = IconColorMaterial.Default.Material;
	Level.ObjectPool.FreeObject( IconColorMaterial );
	IconColorMaterial = None;
}

Simulated Function ApplyIconMaterialColor()
{
	if( IconColorMaterial != None )
	{
		IconColorMaterial.Color = ClientWColor;
		IconColorMaterial.Color.A = 255;
	}
}

simulated function Timer()
{
	local Bot B;

	if( !bColorHasBeenSet && Instigator!=None && Instigator.IsLocallyControlled() )
		SetUpInitialColor();
	if (ClientState == WS_BringUp)
	{
		// Check if owner is bot, waiting to do impact jump.
		B = Bot(Instigator.Controller);
		if ( (B != None) && B.bPreparingMove && (B.ImpactTarget != None) )
		{
			B.ImpactJump();
			B = None;
		}
	}
	Super.Timer();
	if ( (B != None) && (B.Enemy != None) )
		BotFire(false);
}

simulated function ClientTakeHit(int Drain)
{
	ClientPlayForceFeedback(ShieldHitForce);
	if( Level.NetMode==NM_Client )
		ShieldAltFire(FireMode[1]).TakeHit(Drain);
}

// Extra color features.
static final simulated function color GetFlashColor( float TimeS )
{
	local Color C;

	if( Default.LastColorTime==TimeS )
		Return Default.LastUsedColorC;

	//C.A = 128+GetFacingCol(TimeS,2);
	C.R = GetFacingCol(TimeS,2.451);
	C.G = GetFacingCol(TimeS,1.252);
	C.B = GetFacingCol(TimeS,7.164);
	Default.LastColorTime = TimeS;
	Default.LastUsedColorC = C;
	Return C;
}

static final simulated function byte GetFacingCol( float TimeS, float Div )
{
	TimeS = (TimeS-int(TimeS/Div)*Div)/Div;
	if( TimeS<0.5 )
		Return byte(TimeS*510);
	else Return byte((1-TimeS)*510);
}

Simulated Function UpdateShieldTypes()
{
	if( CanUseUniqueColor() )
	{
		bUseFadeColor = Options.bUseFadeColor;
		bTranslucent = Options.bTranslucent;
		ServerUpdateShieldTypes( bUseFadeColor, bTranslucent );
	}
}

Function ServerUpdateShieldTypes( bool b, bool bb )
{
	local LinkedReplicationInfo L;

	if( Instigator == None || Instigator.PlayerReplicationInfo == None )
		return;

	if( CanUseUniqueColor() ) // Hack protection for if this func' is called directly.
	{
		for( L = Instigator.PlayerReplicationInfo.CustomReplicationInfo; L != None; L = L.NextReplicationInfo )
		{
			if( MNAFLinkedRep(L) != None )
			{
				MNAFLinkedRep(L).SetShieldTypes( b, bb );
				MNAFLinkedRep(L).NetUpdateTime = Level.TimeSeconds - 1;

				// Fading is replicated now update it...
				if( EnhShieldAttachment(ThirdPersonActor) != None )
					EnhShieldAttachment(ThirdPersonActor).SetShieldGunColor( ClientWColor );
				break;
			}
		}
	}
}

DefaultProperties
{
	FireModeClass(0)=Class'ShieldFireFix'
	FireModeClass(1)=Class'ShieldAltFireFix'

	Description="ShieldGun, Used by professional players to boost themself across the trial challenges."

	PickupClass=Class'ShieldGunFixPick'
	AttachmentClass=Class'EnhShieldAttachment'

	ClientWColor=(R=50,G=200,B=50,A=255)
	HudColor=(R=50,G=200,B=50,A=255)

	HighDetailOverlay=None
	Skins[0]=Texture'ShieldTex1'
	AlphaTex=Texture'ShieldTexAlpha'
	bAllowAltGlitch=False

	Priority=4
	AIRating=+1.0
	CurrentRating=+1.0
}
