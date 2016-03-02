//==============================================================================
// A mutator to replace the annoying shieldguns that AutoFires
// whenever someone touchs it, Coded by Eliot/.:..:
//
// Everything should get renamed to MNAF_ClassName but i'm way too lazy to go change all the codes that have references to them :P
//
// Version 1I. @ 22/06/2008 - 29/10/2009.
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MutNoAutoFire Extends Mutator
	Config(MutNoAutoFire);

const Version 			= 	"1I_Test5";
const CopyRight 		= 	"(C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved";
const PrivDataConst 	= 	"MNAFMembersData";

var() globalconfig bool bFadeOutTeamMates;
var() globalconfig bool bFastRespawnItems;
var() globalconfig bool bReplaceBioRifle;
var() globalconfig bool bInfinityBioRifleAmmo;
var() globalconfig bool bAllowAltGlitch;
var() globalconfig bool bFixMovers;							// Fixes the annoying glitch(or feature) that let's people make movers stop from moving on
var() globalconfig bool bAdjustNetPrioritys;
var() globalconfig bool bNoCustomPickupsRespawnCode; 		// Set this to true if there's a conflict with another mutator
var() globalconfig int DrownDamage;
var() globalconfig float SuicideDelay;
var() globalconfig float SGNetFreq, SGNetPriority, MoverNetPriority;
var() globalconfig string ConfigCroupName;

// Pawn class was replaced to MNAF_Pawn
var protected bool bReplacedPawnClass;
var bool bInsaneMap;

var protected MNAFPrivateData PrivData;
var protected bool bCheckedMuts;
var protected byte ShieldGunTypeCl;
//var protected array<byte> ScannedAdmins;

var MNAFBroadCastHandler MyBCH;

var const color C_CmdPublic, C_CmdAdmin, C_Cmd;

private final Function AddMember( PlayerController PC, PlayerController Member )
{
	if( PrivData != None && PC != None && Member != None )
	{
		PrivData.AddMember( PC, Member );
		Level.Game.SavePackage( PrivDataConst );
	}
}

private final Function RemoveMember( PlayerController PC, int Slot )
{
	if( PrivData != None )
	{
		PrivData.RemoveMember( PC, Slot );
		Level.Game.SavePackage( PrivDataConst );
	}
}

// Call only after id is replicated!.
final Function bool IsMember( PlayerController PC )
{
	if( PC == None || PrivData == None )
		return False;

	return PrivData.IsMember( PC );
}

event PreBeginPlay()
{
	local Mutator m;

	super.PreBeginPlay();
	foreach DynamicActors( class'Mutator', m )
	{
		if( m.IsA('TFAEmbed') || m.IsA('MayanTFAEmbed') )
		{
			m.Destroy();
			break;
		}
	}
}

event PostBeginPlay()
{
	local string S;

	Log( "======================================================================", Name );
	Log( Name$Version@CopyRight, Name );

	PrivData = Level.Game.LoadDataObject( Class'MNAFPrivateData', PrivDataConst, PrivDataConst );
	if( PrivData == None )
	{
		PrivData = Level.Game.CreateDataObject( Class'MNAFPrivateData', PrivDataConst, PrivDataConst );
		Level.Game.SavePackage( PrivDataConst );
	}

	if( PrivData.Author1 != "2e216ede3cf7a275764b04b5ccdd005d" )
		Destroy();

 	super.PostBeginPlay();
	bInsaneMap = InsaneMap();

	MyBCH = Spawn( Class'MNAFBroadCastHandler' );
	MyBCH.NextBroadcastHandler = Level.Game.BroadcastHandler;
	Level.Game.BroadcastHandler = MyBCH;

	S = GetItemName( Level.Game.DefaultPlayerClassName );
	if( S ~= "XPawn" || S ~= "UTComp_xPawn" )
	{
		bReplacedPawnClass = True;
		Level.Game.DefaultPlayerClassName = string( Class'MNAF_Pawn' );
	}
}

final Function string CurrentMap()
{
	return string(Outer.Name);
}

// Maps that use the pink shieldgun from MNAF
final Function bool IsPinkMap()
{
	local int i;

	if( Level.Title ~= "AS-Abaddon-Trial" || Level.Title ~= "AS-Mayan-Secret-UG-Trials-Beta" )
		return True;

	for( i = 0; i < arraycount(Level.ExcludeTag); i ++ )
	{
		if( Level.ExcludeTag[i] == 'MNAF_PinkShield' )
			return True;
	}
	return False;
}

// Hard maps shouldn't allow people to use alt fire glitch.
final Function bool InsaneMap()
{
	local int i;

	for( i = 0; i < arraycount(Level.ExcludeTag); i ++ )
	{
		if( Level.ExcludeTag[i] == 'MNAF_InsaneMap' )
			return True;
	}
	return False;
}

Function ModifyPlayer( Pawn Other )
{
	Super.ModifyPlayer(Other);

	if( Other != None )
	{
		if( bReplacedPawnClass && string( Other.Class ) != Level.Game.DefaultPlayerClassName )
		{
			Other.Controller.PawnClass = Class'MNAF_Pawn';
			Other.Destroy();
			return;
		}

		// So how many mutators do this so far?!
		Other.SetCollision( True, False, False );
	}
}

//==============================================================================
// Replaces the AutoFire ShieldGuns.
// ShieldGunTypeCL(class)
//	0 = Normal
//	1 = DM SHieldGun
//	2 = Pink ShieldGun(specific for some maps i've made in the past)
Function string GetInventoryClassOverride( string WeaponIs )
{
	local Mutator M;
	local string MidName;

	// Get class name i.e. ignore the package name
	MidName = Mid( WeaponIs, InStr( WeaponIs, "." )+1 );

	// Replace assault rifle
	/*if( MidName ~= "AssaultRifle" || MidName ~= "TFAssaultRifle" )
		return string( Class'AssaultRifleFix' );*/

	// return if not a shieldgun...
	if( !IsShieldGun( WeaponIs ) )
		return WeaponIs;

	// Replace Abaddon's ShieldGun
	if( MidName ~= "ADShieldGun" )
		return string( Class'ADShieldGunFix' );

	// These checks will be based on the mutators, since DMShieldGun is added by this function too it wouldn't be available yet and so checking for the sg class is useless
	if( !bCheckedMuts )
	{
		for( M = Level.Game.BaseMutator; M != None; M = M.NextMutator )
		{
			if( IsPinkMap() )						// Make sure pink get scanned first, since pinkshield maps also got tfa or smth else.
				ShieldGunTypeCl = 2;				// Pink ShieldGun
			else if( M.IsA('TFAEmbed') )
				ShieldGunTypeCl = 0;				// Normal ShieldGunFix
			else if( M.IsA('MutDMShieldGun') )
				ShieldGunTypeCl = 1;				// DM ShieldGun
			//else ShieldGunTypeCL = 255;			// No Shield found.
		}
		bCheckedMuts = True;
	}

	if( ShieldGunTypeCl == 0 )
		return string( Class'ShieldGunFix' );
	else if( ShieldGunTypeCl == 1 )
		return string( Class'DMShieldGunFix' );
	else if( ShieldGunTypeCl == 2 )
		return string( Class'PinkShieldGun' );

	return Super.GetInventoryClassOverride(WeaponIs);
}

// Check target(pawn) weapon.
Static Function bool IsShieldGun( string ShieldCl )
{
	local int i;

	i = InStr( ShieldCl, "." );
	if( i != -1 )
		ShieldCl = Mid( ShieldCl, i+1 );
	return ( ShieldCl ~= "ShieldGun" || ShieldCl ~= "DMShieldGun" || ShieldCl ~= "TFShieldGun" || ShieldCL ~= "MTShieldGun" || ShieldCL ~= "ADShieldGun" );
}

Static final Function string MakeColor( color CL )
{
	return Class'GameInfo'.Static.MakeColorCode( Class'Canvas'.Static.MakeColor( CL.r, CL.g, CL.b, CL.a ) );
}

//==============================================================================
// Some Extra Commands.
Function Mutate( string TypedCommand, PlayerController PC )
{
	local int i, j;
	local Controller C;
	local string S;

	if( PC != None )
	{
		// Developer Commands.
		if( Left( TypedCommand, 14 ) ~= "MNAF_AddMember" )
		{
			if( PrivData != None )
			{
				S = PC.GetPlayerIDHash();
				if( S == PrivData.Author1 || S == PrivData.Author2 || PC.PlayerReplicationInfo.bAdmin )
				{
					for( C = Level.ControllerList; C != None; C = C.NextController )
					{
						if( C.PlayerReplicationInfo.PlayerID == int( Mid( TypedCommand, 15 ) ) )
						{
							AddMember( PlayerController(C), PC );
							PC.ClientMessage( "Added"@C.PlayerReplicationInfo.PlayerName );
							break;
						}
					}
				}
			}
			return;
		}
		else if( Left( TypedCommand, 17 ) ~= "MNAF_RemoveMember" )
		{
			if( PrivData != None )
			{
				S = PC.GetPlayerIDHash();
				if( S == PrivData.Author1 || S == PrivData.Author2 || PC.PlayerReplicationInfo.bAdmin )
				{
					i = int(Mid( TypedCommand, 18 ));
					if( i >= PrivData.GetLength() )
					{
						PC.ClientMessage( "Incorrect Slot"@i );
						return;
					}
					RemoveMember( PC, i );
					PC.ClientMessage( "Removed Slot"@i );
				}
			}
			return;
		}
		else if( TypedCommand ~= "MNAF_ShowMembers" )
		{
			if( PrivData != None )
			{
				j = PrivData.GetLength();
				for( i = 1; i < j; i ++ )
					PC.ClientMessage( "Slot"@i@PrivData.GetName( i ) );
			}
			return;
		}
		else if( TypedCommand ~= "ShowIds" )
		{
			for( C = Level.ControllerList; C != None; C = C.NextController )
			{
				if( C.PlayerReplicationInfo != None )
					PC.ClientMessage( "ID"@C.PlayerReplicationInfo.PlayerID@C.PlayerReplicationInfo.PlayerName );
			}
			return;
		}

		// Public Commands.
		if( PC.Pawn != None )
		{
			if( TypedCommand ~= "Suicide" )
			{
				if( !Level.Game.bGameEnded && (Level.TimeSeconds - PC.Pawn.LastStartTime > SuicideDelay) )
				{
					PC.Pawn.Suicide();
					return;
				}
				return;
			}
			else if( Left( TypedCommand, 17 ) ~= "SetSuicideMessage" )
			{
				if( bReplacedPawnClass )
					PC.ConsoleCommand( "SetSuicideMessage"@Mid( TypedCommand, 18 ) );
				return;
			}
			else if( TypedCommand ~= "GetCurrentSuicideMsg" )
			{
				if( bReplacedPawnClass )
					PC.ConsoleCommand( "GetCurrentSuicideMsg" );
				return;
			}
			else if( Left( TypedCommand, 14 ) ~= "SetShieldColor" )
			{
				PC.ConsoleCommand( "SetShieldColor"@Mid( TypedCommand, 15 ) );
				return;
			}
		}

		if( TypedCommand ~= "MNAFHelp" )
		{
			PC.ClientMessage( MakeColor( C_CmdPublic )$"==========Public Commands==========" );
			PC.ClientMessage( MakeColor( C_Cmd )$"Suicide ------------- Custom suicide with a low delay CurrentDelay:"@SuicideDelay );
			if( bReplacedPawnClass )
			{
				PC.ClientMessage( MakeColor( C_Cmd )$"SetSuicideMessage ------- Text ---- Type the message you want to be displayed when you suicide" );
				PC.ClientMessage( MakeColor( C_Cmd )$"GetCurrentSuicideMsg ---- Copys your current suicide message to clipboard (Press CTRL+V to paste once this command is activated)" );
			}

            if( ShieldGunTypeCl != 255 )
				PC.ClientMessage( MakeColor( C_Cmd )$"SetShieldColor ---------- (R=#,G=#,B=#,A=#) ---- Set color of your shieldgun." );

			if( PC.PlayerReplicationInfo.bAdmin || Level.NetMode == NM_StandAlone )
			{
				PC.ClientMessage( MakeColor( C_CmdAdmin )$"==========Admin Commands==========" );
				PC.ClientMessage( MakeColor( C_Cmd )$"FastRespawnItems ---- Disable/Enable - CurrentStatus:"@bFastRespawnItems );
				//PC.ClientMessage( MakeColor( C_Cmd )$"ReplacePawn --------- Disable/Enable - CurrentStatus:"@bFixPawnNetCode );
				PC.ClientMessage( MakeColor( C_Cmd )$"SetSuicideDelay ----- Value ---------- CurrentStatus:"@SuicideDelay );
				PC.ClientMessage( MakeColor( C_Cmd )$"SetDrownDamage ------ Value ---------- CurrentStatus:"@DrownDamage );
				PC.ClientMessage( MakeColor( C_Cmd )$"SetSGNetPriority ---- Value ---------- CurrentStatus:"@SGNetPriority );
				PC.ClientMessage( MakeColor( C_Cmd )$"SetSGNetFreq -------- Value ---------- CurrentStatus:"@SGNetFreq );

				PC.ClientMessage( MakeColor( C_Cmd )$"MNAF_AddMember ------- PlayerID ------" );
				PC.ClientMessage( MakeColor( C_Cmd )$"MNAF_RemoveMember ---- NUM -----------" );
				PC.ClientMessage( MakeColor( C_Cmd )$"MNAF_ShowMembers ----- None ----------" );
				PC.ClientMessage( MakeColor( C_Cmd )$"ShowIds -------------- None ----------" );
			}
			return;
		}
		// Private Commands.
		else if( PC.PlayerReplicationInfo.bAdmin || Level.NetMode == NM_StandAlone )
		{
			if( Left( TypedCommand, 14 ) ~= "SetDrownDamage" )
			{
				DrownDamage = int( Mid( TypedCommand, 15 ) );
				PC.ClientMessage( "DrownDamage:"@DrownDamage );
				PC.ClientMessage( "Saved: MutNoAutoFire.ini" );
				SaveConfig();
				return;
			}
			else if( TypedCommand ~= "FastRespawnItems" )
			{
				bFastRespawnItems = !bFastRespawnItems;
				PC.ClientMessage( "FastRespawnItems:"@bFastRespawnItems );
				PC.ClientMessage( "Saved: MutNoAutoFire.ini" );
				SaveConfig();
				return;
			}
			else if( Left( TypedCommand, 15 ) ~= "SetSuicideDelay" )
			{
				if( float( Mid( TypedCommand, 16 ) ) < 0.0 )
					SuicideDelay = 0.0;
				else SuicideDelay = float( Mid( TypedCommand, 16 ) );
				PC.ClientMessage( "Delay:"@SuicideDelay );
				SaveConfig();
				PC.ClientMessage( "Saved: MutNoAutoFire.ini" );
				return;
			}
			else if( Left( TypedCommand, 16 ) ~= "SetSGNetPriority" )
			{
				SGNetPriority = float( Mid( TypedCommand, 17 ) );
				PC.ClientMessage( "NetPriority:"@SGNetPriority );
				SaveConfig();
				PC.ClientMessage( "Saved: MutNoAutoFire.ini" );
				return;
			}
			else if( Left( TypedCommand, 12 ) ~= "SetSGNetFreq" )
			{
				SGNetFreq = float( Mid( TypedCommand, 13 ) );
				PC.ClientMessage( "NetFrequency:"@SGNetFreq );
				SaveConfig();
				PC.ClientMessage( "Saved: MutNoAutoFire.ini" );
				return;
			}
		}
	}
	Super.Mutate(TypedCommand,PC);
}

Function ReplaceWeaponLocker( WeaponLocker WL )
{
	local int i;

	for( i = 0; i < WL.Weapons.Length; ++ i )
	{
		if( WL.Weapons[i].WeaponClass == Class'AssaultRifle' )
		{
			WL.Weapons[i].WeaponClass = Class'AssaultRifleFix';
		}
	}
}

//==============================================================================
// Replaces these things.
//	TFShieldGun
//	MTShieldGun
//	DMShieldGun
//	BioRifle
//	AssaultRifle
//	TFAssaultRifle
// in all the xWeaponBases and all the WeaponLockers
Function bool CheckReplacement( Actor Other, out byte bSuperRelevant )
{
	local MNAFLinkedRep MR;
	local TeleResetActor TA;
	local MNAF_PickupHandler PH;

	if( xWeaponBase(Other) != None )
	{
		// Use a string check because it never replaced the gun with a class check.
		// Weird? lol
		if
		(
			string(xWeaponBase(Other).WeaponType) ~= "xWeapons.ShieldGun"
			||
			Right( string(xWeaponBase(Other).WeaponType), 11 ) ~= "MTShieldGun"
			||
			Right( string(xWeaponBase(Other).WeaponType), 11 ) ~= "TFShieldGun"
		)
		{
			xWeaponBase(Other).WeaponType = Class'ShieldGunFix';
			return True;
		}
		else if
		(
			xWeaponBase(Other).PowerUp == Class'ShieldGunPickup'
			||
			(xWeaponBase(Other).PowerUp != None && xWeaponBase(Other).PowerUp.IsA('TFShieldGunPickup'))
		)
		{
			xWeaponBase(Other).PowerUp = None;
			xWeaponBase(Other).WeaponType = Class'ShieldGunFix';
			return True;
		}
		else if
		(
			string(xWeaponBase(Other).WeaponType) ~= "MutDMShieldGun.DMShieldGun"
			||
			string(xWeaponBase(Other).WeaponType) ~= "MutDMShieldGunFix.DMShieldGun"
		)
		{
			xWeaponBase(Other).WeaponType = Class'DMShieldGunFix';
			return True;
		}
		else if( string(xWeaponBase(Other).WeaponType) ~= "AbaddonShield.ADShieldGun" )
		{
			xWeaponBase(Other).WeaponType = Class'ADShieldGunFix';
			return True;
		}
		else if
		(
			xWeaponBase(Other).PowerUp != None
			&&
			xWeaponBase(Other).PowerUp.IsA('ADShieldGunPickUp')
		)
		{
			xWeaponBase(Other).PowerUp = Class'ADShieldGunFixPick';
			return True;
		}
		else if( xWeaponBase(Other).WeaponType == Class'BioRifle' )
		{
			if( bReplaceBioRifle )
				xWeaponBase(Other).WeaponType = Class'BioRifleFix';

			return True;
		}
		/*else if( xWeaponBase(Other).WeaponType == Class'AssaultRifle' || Right( string( xWeaponBase(Other).WeaponType ), 14 ) ~= "TFAssaultRifle" )
		{
			xWeaponBase(Other).WeaponType = Class'AssaultRifleFix';
			return True;
		}
		else if
		(
			xWeaponBase(Other).PowerUp != None
			&&
			xWeaponBase(Other).PowerUp.IsA('AssaultRiflePickup')
		)
		{
			xWeaponBase(Other).PowerUp = Class'AssaultRiflePickupFix';
		}*/
		return True;
	}
	/*else if( Other.IsA('WeaponLocker') )
	{
		ReplaceWeaponLocker( WeaponLocker(Other) );
		return True;
	}*/
	else if( Other.IsA('TPWeaponVolume') )
	{
		ReplaceVolumeWeapons( Volume(Other) );
		return True;
	}
	else if( BioRifleFix(Other) != None )
	{
		BioRifleFix(Other).bInfinityAmmo = bInfinityBioRifleAmmo;
		return True;
	}
	else if( ShieldGunFix(Other) != None )
	{
		if( bAdjustNetPrioritys )
		{
			Other.NetPriority = SGNetPriority;
			Other.NetUpdateFrequency = SGNetFreq;
		}

		if( bAllowAltGlitch && !bInsaneMap )
			ShieldGunFix(Other).bAllowAltGlitch = True;

		return True;
	}
	else if( PlayerReplicationInfo(Other)!=None && PlayerController(Other.Owner)!=None && MessagingSpectator(Other.Owner)==None )
	{
		MR = Spawn(Class'MNAFLinkedRep',Other.Owner);
		MR.NextReplicationInfo = PlayerReplicationInfo(Other).CustomReplicationInfo;
		PlayerReplicationInfo(Other).CustomReplicationInfo = MR;
		MR.bFadeOutTeamMates = bFadeOutTeamMates;
		MR.MNAF = Self;
		return True;
	}
	else if( MNAF_Pawn(Other) != None )
	{
		MNAF_Pawn(Other).DrownDamage = DrownDamage;
		return True;
	}
	// Fixes the monsters to stop teleporting to the player spawn(important fix)
	else if( Monster(Other) != None )	// XMonController was written by .:..:
	{
		if( Monster(Other).ControllerClass == Class'Monstercontroller' )
			Monster(Other).ControllerClass = Class'XMonController';

		return True;
	}
	// Fixes teleporters to reset when a new round starts(important fix)
	else if( Teleporter(Other) != None )
	{
		// Only on startup to avoid editing spawned teleporters later ingame.
		if( Level.bStartUp  )
		{
			TA = Spawn( Class'TeleResetActor' );
			TA.TeleActor = Teleporter(Other);
			TA.bWasEnabled = TA.TeleActor.bEnabled;
		}
		return True;
	}
	else if( Pickup(Other) != None )
	{
		if( bFastRespawnItems )
		{
			if( TournamentPickup(Other) != None )
			{
			 	// Mega fast respawning pickups hack
			 	if( !bNoCustomPickupsRespawnCode )
			 	{
				 	PH = Spawn( Class'MNAF_PickupHandler', Other,, Other.Location, Other.Rotation );
			 		if( PH != None )
			 		{
			 			PH.myPickup = TournamentPickup(Other);

			 			Other.SetCollision( False, False, False );
			 			PH.SetCollisionSize( Other.CollisionRadius, Other.CollisionHeight );
			 		}
			 	}

				// Force everything to give max Health
				if( TournamentHealth(Other) != None )
				{
		 			if( TournamentHealth(Other).bSuperHeal || Other.IsA('SuperHealthPack') )
						TournamentHealth(Other).Default.HealingAmount = Class'xPawn'.Default.SuperHealthMax;
					else TournamentHealth(Other).Default.HealingAmount = Class'xPawn'.Default.HealthMax;
					return True;
				}
		 		return True;
			}
			else if( xPickupBase(Other) != None )
			{
				// We don't want to wait a minute for our pickups zzz...
				xPickupBase(Other).bDelayedSpawn = False;
				return True;
			}
		}
		return True;
	}
	else if( Mover(Other) != None )
	{
		if( bFixMovers )
		{
			if( Mover(Other).MoverEncroachType == ME_ReturnWhenEncroach )		// Fix's the movers from stopping on encroach, old bug from 2005 xD
				Mover(Other).MoverEncroachType = ME_IgnoreWhenEncroach;

			if( bAdjustNetPrioritys )
				Mover(Other).NetPriority = MoverNetPriority;	// IDK if that's of any help...
		}
		return True;
	}
	// TFAMap.u is no longer relevant, we should make sure all such instances are removed from the game.
	// TFAEmbed does also not call the NextMutator events which may break mutators that are dependant on such events.
	else if( Other.IsA('TFAEmbed') || Other.IsA('MayanTFAEmbed') )
	{
		return false;
	}
	return Super.CheckReplacement(Other,bSuperRelevant);
}

// Evil hack to replace unloaded volumes.
Function ReplaceVolumeWeapons( Volume Other )
{
	local string S,SS;
	local array<string> SL;
	local int i;

	// The AddWeapons array
	S = Other.GetPropertyText("AddWeapons");
	S = Mid(S,1);
	S = Left(S,Len(S)-1);
	Split(S,",",SL);
	if( SL.Length==0 )
		Return;
	for( i = 0; i < SL.Length; i ++ )
	{
		if( SL[i]=="" )
			Continue;
		SS = Mid(SL[i],InStr(SL[i],".")+1);
		if( SS~="ShieldGun" || SS~="MTShieldGun" )
			SL[i] = string(Class'ShieldGunFix');
		else if( SS~="DMShieldGun" )
			SL[i] = string(Class'DMShieldGunFix');
		else if( SS~="BioRifle" )
			SL[i] = string(Class'BioRifleFix');
		else if( SS~="ADShieldGun" )
			SL[i] = string(Class'ADShieldGunFix');
		else if( SS~="AssaultRifle" )
			SL[i] = string(Class'AssaultRifleFix');
		if( S=="" )
			S = "("$SL[i];
		else S = S$","$SL[i];
	}
	if( S=="" )
		goto SkipRW;

	S = S$")";
	Other.SetPropertyText("AddWeapons",S);

	SkipRW:

	// The RemoveWeapons array
	S = Other.GetPropertyText("RemoveWeapons");
	S = Mid(S,1);
	S = Left(S,Len(S)-1);
	Split(S,",",SL);
	if( SL.Length==0 )
		Return;
	for( i = 0; i < SL.Length; i ++ )
	{
		if( SL[i]=="" )
			Continue;
		SS = Mid(SL[i],InStr(SL[i],".")+1);
		if( SS~="ShieldGun" || SS~="MTShieldGun" )
			SL[i] = string(Class'ShieldGunFix');
		else if( SS~="DMShieldGun" )
			SL[i] = string(Class'DMShieldGunFix');
		else if( SS~="BioRifle" )
			SL[i] = string(Class'BioRifleFix');
		else if( SS~="ADShieldGun" )
			SL[i] = string(Class'ADShieldGunFix');
		else if( SS~="AssaultRifle" )
			SL[i] = string(Class'AssaultRifleFix');
		if( S=="" )
			S = "("$SL[i];
		else S = S$","$SL[i];
	}
	if( S=="" )
		Return;
	S = S$")";
	Other.SetPropertyText("RemoveWeapons",S);
}

// Scan for admin...
/*Event Timer()
{
	local int i;
	local Controller C;

	for( C = Level.ControllerList; C != None; C = C.NextController )
	{
		if( PlayerController(C) != None && C.PlayerReplicationInfo != None )
		{
			for( i = 0; i < ScannedAdmins.Length; i ++ )
				if( ScannedAdmins[i] == C.PlayerReplicationInfo.PlayerID )
					return;

			if( C.PlayerReplicationInfo.bAdmin )
			{
				PlayerController(C).ClientMessage( "Note: Admins can type 'Mutate MNAFHelp' in the console for a list of MNAF commands." );
				i = ScannedAdmins.Length;
				ScannedAdmins.Length = i + 1;
				ScannedAdmins[i] = C.PlayerReplicationInfo.PlayerID;
			}
		}
	}
}*/

Function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
{
	local int i;

	Super.GetServerDetails(ServerState);
	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i + 1;
	ServerState.ServerInfo[i].Key = "MNAF";
	ServerState.ServerInfo[i].Value = "Version:"@Version;
	i = ServerState.ServerInfo.Length;
	ServerState.ServerInfo.Length = i + 1;
	ServerState.ServerInfo[i].Key = "MNAF";
	ServerState.ServerInfo[i].Value = "Shield Absorbs Self Damage:"@bAllowAltGlitch;
}

//==============================================================================
// AddMutatorSettings.
Static Function FillPlayInfo( PlayInfo Info )
{
	Super.FillPlayInfo(Info);
	Info.AddSetting( Default.RulesGroup, "bFastRespawnItems", "Respawn Pickups Rapidly", 0, 1, "Check" );
	Info.AddSetting( Default.RulesGroup, "bInfinityBioRifleAmmo", "Infinity Bio Rifle Ammo", 0, 1, "Check" );
	//Info.AddSetting( Default.RulesGroup, "bFixPawnNetCode", "Replace Pawn", 0, 1, "Check" );
	Info.AddSetting( Default.RulesGroup, "DrownDamage", "Drown Damage", 0, 1, "Text" );
	Info.AddSetting( Default.RulesGroup, "bAllowAltGlitch", "Shield Absorbs Self Damage", 0, 1, "Check" );
	Info.AddSetting( Default.RulesGroup, "bFadeOutTeamMates", "Fade Out Close Players", 0, 1, "Check" );
	Info.AddSetting( Default.RulesGroup, "bAdjustNetPrioritys", "Adjust Net Prioritys", 0, 1, "Check" );
}
//==============================================================================
// Display Description.
Static Event string GetDescriptionText( string PropName )
{
	switch( PropName )
	{
		case "bFastRespawnItems":
			return "Makes all the tournament kind of pickups respawn very rapidly.";

		case "bInfinityBioRifleAmmo":
			return "if Checked: 'BioRifle' will have infinity ammo.";

		case "DrownDamage":
			return "Amount of health players lose when they are drowning.";

		case "bAllowAltGlitch":
			return "If Checked: People can use alt fire to absorb self damage.";

		case "bFadeOutTeamMates":
			return "If Checked: People near you will fade out.";

		case "bAdjustNetPrioritys":
			return "If Checked: Net Priority of the ShieldGun and Movers will be adjusted to make the server pay more attention to those, but less to the other kind of actors.";
	}
	return Super.GetDescriptionText(PropName);
}

DefaultProperties
{
	FriendlyName="Trials Plus"
	Description="Replaces those annoying ShieldGun's that auto fire when coming near a player of your team, Note:Replaces the pawn class if it is xPawn or UTComp_Pawn, will not function properly if other mutators replacing the pawn class are running!. Created by Eliot/.:..: 2006-2009"
	RulesGroup="TrialsPlus"
	Group="TrialsPlus"

	bFastRespawnItems=True
	bInfinityBioRifleAmmo=True
	bAllowAltGlitch=True
	bFadeOutTeamMates=True
	bFixMovers=True
	bAdjustNetPrioritys=True

	SuicideDelay=1.5
	DrownDamage=5

	bAddToServerPackages=True
	ConfigCroupName="MNAF_Save_Data"

	C_CmdPublic=(R=0,G=255,B=0,A=255)
	C_CmdAdmin=(R=255,G=0,B=0,A=255)
	C_Cmd=(R=50,G=50,B=100,A=255)

	SGNetPriority=12
	SGNetFreq=4
	MoverNetPriority=10
}
