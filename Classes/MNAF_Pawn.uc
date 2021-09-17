//==============================================================================
// MNAF_Pawn.uc
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
class MNAF_Pawn extends xPawn;

#exec obj load file="MutNoAF.utx" package="MutTrialsPlus"

const MaxSuicideMsgLen = 255;

struct AnimActionRepType
{
	var name AnimName;
	var byte AnimCounter;
};
var AnimActionRepType ActionAnimRep;

var protected bool
	bMayUpdateAction,
	bTeamMatesFading,
	bAppliedPRI,
	bSkinsAreLoaded,
	bShouldUseFadeSk,
	bDidDodge,
	bDidJump,
	bPawnUpdated,
	bFadingSkin,
	bFadingSkinLoaded;

var float
	LastChangeTime,
	LastLandedTime;

var string OldCharacterName;
var PlayerController TheLocalPC;
var array<ColorModifier> ColSkinsM;
var array<Material> OrgSkins;
var int DrownDamage;
var vector LastTickLoc;

var protected ConstantColor FMat, FMat2;
var protected Shader SMat, SMat2;
var protected MNAFLinkedRep MLR;
var protected PinkRings_mini aPR;

var float LastJumpTime;
var() bool bDebugDodgeTiming;
var() const float DodgeResetTime;
var globalconfig int AntiMGDistance;

replication
{
	// Variables the server should send to the client.
	reliable if( bNetDirty && (Role == ROLE_Authority) && !bReplicateAnimations && !bNetOwner )
		ActionAnimRep;

	reliable if( Role == ROLE_Authority )
		PlayAnimOnClient;

	reliable if( Role < ROLE_Authority )
		ServerApplyNewMsg,
		ServerChangeHitMat,
		ServerRBS,
		ServerPR,
		ServerTimeDodge;
}

// 'SetAnimAction' where ALL anims will be played on client side.
// Fix by .:..:
simulated event SetAnimAction(name NewAction)
{
	super.SetAnimAction(NewAction);
	AnimAction = '';
	if( Level.NetMode!=NM_Client )
	{
		PlayAnimOnClient(NewAction);
		ActionAnimRep.AnimName = NewAction;
		ActionAnimRep.AnimCounter++;
		if( ActionAnimRep.AnimCounter>250 )
			ActionAnimRep.AnimCounter = 1;
	}
}

// Fix by .:..:
simulated function PlayAnimOnClient(name AnimName)
{
	if( Level.NetMode==NM_Client )
		SetAnimAction(AnimName);
}

simulated function PostNetBeginPlay()
{
	super.PostNetBeginPlay();
	bMayUpdateAction = true;
	ActionAnimRep.AnimCounter = 0;

	InitPawn();

	// FIXME: Nasty solution, forces the player to switch to the ShieldGun as opposed to the Assault Rifle.
	SwitchWeapon( 1 );	// ShieldGun
}

simulated function InitPawn()
{
	local string S;
	local MNAFSavedData MD;

	if( Controller != None )
	{
		bTeamMatesFading = False;
		bShouldUseFadeSk = False;
		if( PlayerReplicationInfo != None )
		{
			MLR = GetRep(PlayerReplicationInfo);
			// Send my configuration to the server, (Make sure only the local owner does this!)
			if( MLR != None && Level.NetMode != NM_DedicatedServer && TheLocalPC == Controller )
			{
				MD = Class'MNAFSavedData'.Static.FindSavedData();
				if( MD != None )
				{
					ServerChangeHitMat( MD.bEnhancedMaterials );
					ServerRBS( MD.bFadePlayerSkinAlong );
					ServerPR( MD.bPR );

					S = MD.MySuicideMsg;
					if( MLR.CustomScdMsg != S )
						ServerApplyNewMsg( S );
				}
			}
		}
	}
}

simulated event Tick( float DeltaTime )
{
	local int i;
	local float D;
	local byte CA;
	local vector HR;

	super.Tick( DeltaTime );
	if( Level.NetMode != NM_DedicatedServer )
	{
		// Apply RainBowSkin
		if( bFadingSkin )															// Eliot
		{
			if( !bFadingSkinLoaded )
			{
				if( FMat == None )
					FMat = ConstantColor(Level.ObjectPool.AllocateObject( Class'ConstantColor' ));

				if( SMat == None )
					SMat = Shader(Level.ObjectPool.AllocateObject( Class'Shader' ));

				if( FMat2 == None )
					FMat2 = ConstantColor(Level.ObjectPool.AllocateObject( Class'ConstantColor' ));

				if( SMat2 == None )
					SMat2 = Shader(Level.ObjectPool.AllocateObject( Class'Shader' ));

				if( !bTeamMatesFading )
				{
					OrgSkins.Length = 2;
					OrgSkins[0] = Skins[0];
					OrgSkins[1] = Skins[1];
				}

				SMat.Diffuse = OrgSkins[0];
				SMat.Specular = FMat;
				Skins[0] = SMat;

				SMat2.Diffuse = OrgSkins[1];
				SMat2.Specular = FMat2;
				Skins[1] = SMat2;

				if( MLR != None && MLR.TransOn() )
				{
					SMat.OutputBlending = OB_Translucent;
					SMat2.OutputBlending = OB_Translucent;
				}
				bFadingSkinLoaded = True;
			}
			else
			{
				FMat.Color = Class'ShieldGunFix'.Static.GetFlashColor( Level.TimeSeconds/Level.TimeDilation );
				FMat2.Color = FMat.Color;
			}
		}
		// Ok not... then apply fading visibility skins
		else if( bTeamMatesFading && (Level.TimeSeconds-LastRenderTime)<2 ) 		// .:..:
		{
			if( !bSkinsAreLoaded )
				bSkinsAreLoaded = True;
			D = VSize(TheLocalPC.CalcViewLocation-Location);
			if( D>1500 )
				D = 1;
			else D = D/1500;
			CA = byte(D*255.f);
			if( Skins.Length > ColSkinsM.Length )
				ColSkinsM.Length = Skins.Length;
			For( i=0; i<Skins.Length; i++ )
			{
				if( Skins[i]==None )
					Continue;
				if( ColSkinsM[i]==None )
				{
					ColSkinsM[i] = ColorModifier(Level.ObjectPool.AllocateObject(Class'ColorModifier'));
					ColSkinsM[i].RenderTwoSided = True;
				}
				if( Skins[i]!=ColSkinsM[i] )
				{
					if( OrgSkins.Length<=i )
						OrgSkins.Length = i+1;
					OrgSkins[i] = Skins[i];
					ColSkinsM[i].Material = Skins[i];
					ColSkinsM[i].Color = Class'Canvas'.Static.MakeColor(255,255,255);
					if( ColorModifier(Skins[i])!=None )
					{
						ColSkinsM[i].Material = ColorModifier(Skins[i]).Material;
						ColSkinsM[i].Color = ColorModifier(Skins[i]).Color;
					}
					Skins[i] = ColSkinsM[i];
				}
				ColSkinsM[i].Color.A = CA;
				ColSkinsM[i].AlphaBlend = (CA!=255);
			}
		}
		else if( !bTeamMatesFading && bSkinsAreLoaded )
		{
			bSkinsAreLoaded = False;
			UnloadSkins();
		}
	}

	// Don't check for mover exploit if user is in a vehicle of using the fly cheat nor should the client bother checking for the exploit :P
	if( Level.NetMode == NM_Client || DrivenVehicle != None || Physics == PHYS_Flying )
		return;

	if( VSize( LastTickLoc-Location ) > AntiMGDistance )
	{
		LastTickLoc = Location;
		return;
	}

	if( Mover(Trace( HR, HR, Location, LastTickLoc, True )) != None )
		Suicide();

	LastTickLoc = Location;
}

simulated function UnloadSkins()
{
	local int i;

	if( ColSkinsM.Length==0 )
		Return;
	Skins = OrgSkins;
	For( i=0; i<ColSkinsM.Length; i++ )
	{
		if( ColSkinsM[i]==None )
			Continue;
		ColSkinsM[i].Color = ColSkinsM[i].Default.Color;
		ColSkinsM[i].RenderTwoSided = ColSkinsM[i].Default.RenderTwoSided;
		ColSkinsM[i].AlphaBlend = ColSkinsM[i].Default.AlphaBlend;
		Level.ObjectPool.FreeObject(ColSkinsM[i]);
		ColSkinsM[i] = None;
	}
	ColSkinsM.Length = 0;
}

simulated function Destroyed()
{
	UnloadSkins();

	bFadingSkin = False;
	if( FMat != None )
	{
		FMat.Color = FMat.Default.Color;
		Level.ObjectPool.FreeObject( FMat );
		FMat = None;
	}

	if( SMat != None )
	{
		SMat.Diffuse = SMat.Default.Diffuse;
		SMat.Specular = SMat.Default.Specular;
		SMat.OutputBlending = SMat.Default.OutputBlending;
		Level.ObjectPool.FreeObject( SMat );
		SMat = None;
	}

	if( FMat2 != None )
	{
		FMat2.Color = FMat2.Default.Color;
		Level.ObjectPool.FreeObject( FMat2 );
		FMat2 = None;
	}

	if( SMat2 != None )
	{
		SMat2.Diffuse = SMat2.Default.Diffuse;
		SMat2.Specular = SMat2.Default.Specular;
		SMat2.OutputBlending = SMat2.Default.OutputBlending;
		Level.ObjectPool.FreeObject( SMat2 );
		SMat2 = None;
	}
	super.Destroyed();
}

static function MNAFLinkedRep GetRep( PlayerReplicationInfo PRI )
{
	local LinkedReplicationInfo LRI;

	for( LRI = PRI.CustomReplicationInfo; LRI != none; LRI = LRI.NextReplicationInfo )
	{
		if( MNAFLinkedRep(LRI) != none )
		{
			return MNAFLinkedRep(LRI);
		}
	}
	return none;
}

simulated function InitEffects()
{
	if( PlayerReplicationInfo == None )
		return;

	MLR = GetRep( PlayerReplicationInfo );
	if( MLR != none && Level.NetMode != NM_DedicatedServer && !bPawnUpdated )
	{
		if( MLR.RBSOn() )
			bFadingSkin = True;

		if( MLR.UsingPR() )
		{
			aPR = Spawn( Class'PinkRings_mini', Self );
 			AttachToBone( aPR, 'lfarm' );
 			aPR = Spawn( Class'PinkRings_mini', Self );
 			AttachToBone( aPR, 'rfarm' );
		}
		bPawnUpdated = True;
	}

	if( !bFadingSkin )
	{
		if( !bAppliedPRI )
		{
			TheLocalPC = Level.GetLocalPlayerController();
			if( PlayerReplicationInfo!=none && TheLocalPC.PlayerReplicationInfo!=none
				&& PlayerReplicationInfo.Team!=none
				&& TheLocalPC.PlayerReplicationInfo.Team!=none )
			{
				bAppliedPRI = True;
				if( Controller==none && PlayerReplicationInfo.Team==TheLocalPC.PlayerReplicationInfo.Team )
				{
					if( MLR != none && MLR.bFadeOutTeamMates )
					{
						bTeamMatesFading = true;
						bShouldUseFadeSk = true;
					}
				}
			}
		}
		else if( bShouldUseFadeSk && PlayerReplicationInfo!=none && TheLocalPC.PlayerReplicationInfo!=none && PlayerReplicationInfo.Team!=none )
			bTeamMatesFading = (PlayerReplicationInfo.Team==TheLocalPC.PlayerReplicationInfo.Team);
	}
}

// Fix some things regarding characters
simulated function PostNetReceive()
{
	local string charName;

	InitEffects();
	if( bMayUpdateAction && ActionAnimRep.AnimCounter!=0 )
	{
		ActionAnimRep.AnimCounter = 0;
		SetAnimAction(ActionAnimRep.AnimName);
	}

	if ( PlayerReplicationInfo != None )
		charName = PlayerReplicationInfo.CharacterName;
	else if ( (DrivenVehicle != None) && (DrivenVehicle.PlayerReplicationInfo != None) )
		charName = DrivenVehicle.PlayerReplicationInfo.CharacterName;

	if( Len(charName)>0 && charName!=OldCharacterName )
	{
		OldCharacterName = charName;
		Setup( class'xUtil'.static.FindPlayerRecord( charName ) );
	}
}

simulated function bool ForceDefaultCharacter()
{
	if ( !class'DeathMatch'.default.bForceDefaultCharacter )
		return false;
	return true;
}

// And some with the gibbing
simulated function PlayDyingAnimation(class<DamageType> DamageType, vector HitLoc)
{
	if( Level.NetMode==NM_Client && DamageType!=none && DamageType.default.bAlwaysGibs && !bGibbed )
		ChunkUp( Rotation, DamageType.default.GibPerterbation );
	else super.PlayDyingAnimation(DamageType,HitLoc);
}

function Suicide()
{
	Health = 0;
	Died( Controller, Class'MNAF_Suicided', Location );
}

function TakeDrowningDamage()
{
	if( DrownDamage > 0 )
		TakeDamage( DrownDamage, None, Location + CollisionHeight * vect(0,0,0.5)+ 0.7 * CollisionRadius * vector(Controller.Rotation), vect(0,0,0), Class'GamePlay.Drowned' );
}

simulated exec function SetSuicideMessage( string SuicideSTR )
{
	local MNAFSavedData MD;

	if( SuicideSTR=="" )
		return;

	if( Level.NetMode==NM_Client )
	{
		SuicideSTR = Left(SuicideSTR,MaxSuicideMsgLen);
		if( InStr(SuicideSTR,"%o")==-1 )
		{
			ClientMessage("Missing victim name '%o', example: %o died.");
			Return;
		}
		if( LastChangeTime>Level.TimeSeconds )
			Return;
		else LastChangeTime = Level.TimeSeconds+Level.TimeDilation*1.5;
	}
	MD = Class'MNAFSavedData'.Static.FindSavedData();
	MD.MySuicideMsg = SuicideSTR;
	MD.SaveConfig();
	ServerApplyNewMsg( SuicideSTR );
}

// New Custom Suicide Message
function ServerApplyNewMsg( string ScdMsg ) /* Eliot */
{
    if( PlayerReplicationInfo==None )
		return;

	if( LastChangeTime>Level.TimeSeconds )
		return;
	else LastChangeTime = Level.TimeSeconds+Level.TimeDilation*1.5;

	ScdMsg = Level.Game.StripColor( Left( ScdMsg, MaxSuicideMsgLen ) );
	if( InStr(ScdMsg,"%o") == -1 )
		return;

	MLR = GetRep(PlayerReplicationInfo);
	if( MLR == None )
		return;

	MLR.CustomScdMsg = MLR.ReplaceWithTags( ScdMsg );
}

simulated exec function GetCurrentSuicideMsg() /* Eliot */
{
	if( TheLocalPC != None )
		TheLocalPC.CopyToClipBoard( Class'MNAFSavedData'.Static.FindSavedData().MySuicideMsg );
}

// ShieldArmor hit material
function ServerChangeHitMat( bool bEnabled ) /* Eliot */
{
	MLR = GetRep(PlayerReplicationInfo);
	if( MLR == None )
		return;

	if( MLR.IsUnique() )
	{
		if( bEnabled )
			ShieldHitMat = Material'HitMePlease';
		else ShieldHitMat = Default.ShieldHitMat;
	}
}

// Rainbow Skin
function ServerRBS( bool bEnabled )
{
	MLR = GetRep(PlayerReplicationInfo);
	if( MLR == None )
		return;

	if( MLR.IsUnique() )
	{
		bFadingSkin = bEnabled;
		MLR.RBS( bEnabled );
	}
}

// Pink Rings
function ServerPR( bool bEnabled )
{
	MLR = GetRep(PlayerReplicationInfo);
	if( MLR == None )
		return;

	if( MLR.IsUnique() )
	{
		MLR.PR( bEnabled );
	}
}

// Make sure suicided is always using our custom suicided class for the custom suicide message feature!
function Died(Controller Killer, class<DamageType> DamageType, vector HitLocation) /* Eliot */
{
     if( DamageType == Class'Suicided' )
          DamageType = Class'MNAF_Suicided';
     super.Died(Killer,DamageType,HitLocation);
}

// Anti-TeamSwitch team killing!
function PlayerChangedTeam() /* Eliot */
{
	local Inventory Inv;
	local Projectile Proj;

	// Fixes weapon firing while holding the fire button and switch team at the same moment
	if( Weapon != None )
	{
		Weapon.ClientStopFire( 0 );
		Weapon.ClientStopFire( 1 );
	}

	// Fixes weapon firing while holding the fire button and switch team at the same moment
	if( Inventory != None )
	{
		for( Inv = Inventory; Inv != None; Inv = Inv.Inventory )
				Inv.Destroy();
	}

	// Fixes team killing!
	ForEach DynamicActors( Class'Projectile', Proj )
	{
		if( Proj.Owner == Self )
			Proj.Destroy();
	}

	super.PlayerChangedTeam();
}

exec function TimeDodge()
{
	bDebugDodgeTiming = !bDebugDodgeTiming;
	ServerTimeDodge( bDebugDodgeTiming );
}

exec function ServerTimeDodge( bool bTime )
{
	bDebugDodgeTiming = bTime;
}

// Anti-MultiDodge hack
function bool Dodge( eDoubleClickDir DoubleClickMove ) /* Eliot */
{
	local float time;

	time = (Level.TimeSeconds - LastLandedTime)/Level.TimeDilation;
	if( bDebugDodgeTiming )
	{
		ClientMessage(
			"Dodge Time"
			@ GetEnum( enum'ENetMode', Level.Netmode )
			@ time*100f
			@ GetEnum( enum'EDoubleClickDir', PlayerController(Controller).DoubleClickDir )
		);
	}

	// MultiDodge Check
	if( PlayerController(Controller).DoubleClickDir == DCLICK_Active || (PlayerController(Controller).DoubleClickDir != DCLICK_None && time < DodgeResetTime) )
	{
    	return false;
	}

    bDidDodge = true;
	PlayerController(Controller).DoubleClickDir = DoubleClickMove;
	return super.Dodge(DoubleClickMove);
}

function bool DoJump( bool bUpdating )
{
	if( super.DoJump( bUpdating ) )
	{
		return true;
	}
	else LastJumpTime = Level.TimeSeconds;
}

/**
 * This parent overwrite, solves the following issues:
 * - Set a LastLandedTime so that we can block dodge cheats, this let's measure whether a dodge is valid on the server's side.
 * - The landing sound was not always played, and because players use this sound to time their next dodge move, we had ensure that it is always being played.
 */
event Landed( Vector v )
{
	super(UnrealPawn).Landed(v);
    MultiJumpRemaining = MaxMultiJump;

	if( bDidDodge )
	{
		LastLandedTime = Level.TimeSeconds;
		bDidDodge = False;
	}

 	if( Health <= 0 || bHidden )
 		return;

 	// Change: Overwrite sound TRUE (so that landing sound will always be played!)
    PlayOwnedSound( GetSound( EST_Land ), SLOT_Interact, FMin( 1, -0.3 * Velocity.Z / JumpZ ), True );
}

function PlayMoverHitSound()
{
	PlaySound( SoundGroupClass.Static.GetHitSound(), SLOT_Interact, 1.0*TransientSoundVolume, True );
}

simulated exec function TogglePlayDirectionalHit()
{
	local MNAFSavedData MD;

	MD = Class'MNAFSavedData'.Static.FindSavedData();
	if( MD != None )
	{
		MD.bPlayDirectionalHits = !MD.bPlayDirectionalHits;
		MD.SaveConfig();
	}
}

simulated function PlayDirectionalHit( Vector HitLoc )
{
	local MNAFSavedData MD;

	MD = Class'MNAFSavedData'.Static.FindSavedData();
	if( MD != None && MD.bPlayDirectionalHits )
		super.PlayDirectionalHit(HitLoc);
}

// Copy from UnrealPawn, Reason:Remove ClientSwitchToBestWeapon();
function AddDefaultInventory()
{
	local int i;

    Level.Game.AddGameSpecificInventory( Self );

	for ( i = 15; i >= 0; -- i )
		if ( (SelectedEquipment[i] == 1) && (OptionalEquipment[i] != "") )
			CreateInventory( OptionalEquipment[i] );

	for ( i = 15; i >= 0; -- i )
		if ( RequiredEquipment[i] != "" )
			CreateInventory( RequiredEquipment[i] );

	// HACK FIXME
	if ( inventory != None )
		inventory.OwnerEvent( 'LoadOut' );

	SwitchWeapon( 1 );	// ShieldGun
}

defaultproperties
{
	DodgeResetTime=0.40
	AntiMGDistance=30
}
