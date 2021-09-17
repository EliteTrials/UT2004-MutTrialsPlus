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

var() array<struct sNewInventoryClass{
	var string ClassName;
	var class<Inventory> NewClass;
}> NewInventoryClasses;

var() enum EShieldGunMode{
	SGM_None,
	SGM_Default,
	SGM_DM,
	SGM_Pink
} ShieldGunMode;

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

event MatchStarting()
{
	local Mutator mut;

	super.MatchStarting();
	if( ShieldGunMode == EShieldGunMode.SGM_None )
	{
		ShieldGunMode = EShieldGunMode.SGM_Default;
		if( IsPinkMap() )
		{
			ShieldGunMode = EShieldGunMode.SGM_Pink;
		}
		for( mut = Level.Game.BaseMutator; mut != none; mut = mut.NextMutator )
		{
			if( mut.IsA('MutDMShieldGun') )
			{
				ShieldGunMode = EShieldGunMode.SGM_DM;
				break;
			}
		}
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

event ModifyPlayer( Pawn Other )
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

final function class<Inventory> GetNewInventoryClass( string inventoryClassName )
{
	local int i;
	local string realClassName;

	realClassName = Mid( inventoryClassName, InStr( inventoryClassName, "." ) + 1 );
	for( i = 0; i < NewInventoryClasses.Length; ++ i )
	{
		// Log( NewInventoryClasses[i].ClassName @ "==" @ inventoryClassName );
		if( NewInventoryClasses[i].ClassName ~= inventoryClassName || NewInventoryClasses[i].ClassName ~= realClassName )
		{
			// Log( "Overriding class with" @ NewInventoryClasses[i].NewClass );
			return NewInventoryClasses[i].NewClass;
		}
	}
	return none;
}

event string GetInventoryClassOverride( string inventoryClassName )
{
	local class<Inventory> newInvClass;

	// Get class name i.e. ignore the package name
	newInvClass = GetNewInventoryClass( inventoryClassName );
	if( newInvClass == none )
		return super.GetInventoryClassOverride( inventoryClassName );

	if( newInvClass == class'ShieldGunFix' )
	{
		// Log("Overriding a ShieldGun class!");
		switch( ShieldGunMode )
		{
			case EShieldGunMode.SGM_DM:
				newInvClass = class'DMShieldGunFix';
				break;

			case EShieldGunMode.SGM_Pink:
				newInvClass = class'PinkShieldGun';
				break;
		}
	}
	// Log("Class will be overriden with" @ newInvClass);
	return string(newInvClass);
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

event bool CheckReplacement( Actor other, out byte bSuperRelevant )
{
	local MNAFLinkedRep MR;
	local TeleResetActor TA;
	local MNAF_PickupHandler PH;

	if( xWeaponBase(other) != none )
	{
		if( xWeaponBase(other).WeaponType != none )
		{
			xWeaponBase(other).WeaponType = class<Weapon>(Level.Game.BaseMutator.GetInventoryClass( string(xWeaponBase(other).WeaponType) ));
		}
		// else if( xWeaponBase(other).PowerUp != none )
		// {
		// 	xWeaponBase(other).WeaponType = Level.Game.BaseMutator.GetInventoryClass( string(xWeaponBase(other).PowerUp.InventoryType) );
		// 	xWeaponBase(other).PowerUp = none;
		// }
		return true;
	}
	else if( WeaponPickup(other) != none )
	{
		WeaponPickup(other).InventoryType = Level.Game.BaseMutator.GetInventoryClass( string(WeaponPickup(other).InventoryType) );
	}
	else if( WeaponLocker(other) != none )
	{
		ReplaceWeaponLocker( WeaponLocker(other) );
		return true;
	}
	else if( other.IsA('TPWeaponVolume') )
	{
		ReplaceVolumeWeapons( Volume(other) );
		return true;
	}
	else if( BioRifleFix(other) != none )
	{
		BioRifleFix(other).bInfinityAmmo = bInfinityBioRifleAmmo;
		return true;
	}
	else if( ShieldGunFix(other) != none )
	{
		if( bAdjustNetPrioritys )
		{
			other.NetPriority = SGNetPriority;
			other.NetUpdateFrequency = SGNetFreq;
		}

		if( bAllowAltGlitch && !bInsaneMap )
			ShieldGunFix(other).bAllowAltGlitch = true;

		return true;
	}
	else if( PlayerReplicationInfo(other) != none && PlayerController(other.Owner) != none && MessagingSpectator(other.Owner) == none )
	{
		MR = Spawn(Class'MNAFLinkedRep',other.Owner);
		MR.NextReplicationInfo = PlayerReplicationInfo(other).CustomReplicationInfo;
		PlayerReplicationInfo(other).CustomReplicationInfo = MR;
		MR.bFadeOutTeamMates = bFadeOutTeamMates;
		MR.MNAF = self;
		return true;
	}
	else if( MNAF_Pawn(other) != none )
	{
		MNAF_Pawn(other).DrownDamage = DrownDamage;
		return true;
	}
	// Fixes the monsters to stop teleporting to the player spawn(important fix)
	else if( Monster(other) != none )	// XMonController was written by .:..:
	{
		if( Monster(other).ControllerClass == Class'Monstercontroller' )
			Monster(other).ControllerClass = Class'XMonController';

		return true;
	}
	// Fixes teleporters to reset when a new round starts(important fix)
	else if( Teleporter(other) != none )
	{
		// Only on startup to avoid editing spawned teleporters later ingame.
		if( Level.bStartUp  )
		{
			TA = Spawn( Class'TeleResetActor' );
			TA.TeleActor = Teleporter(other);
			TA.bWasEnabled = TA.TeleActor.bEnabled;
		}
		return true;
	}
	else if( Pickup(other) != none )
	{
		if( bFastRespawnItems )
		{
			if( TournamentPickup(other) != none )
			{
			 	// Mega fast respawning pickups hack
			 	if( !bNoCustomPickupsRespawnCode )
			 	{
				 	PH = Spawn( Class'MNAF_PickupHandler', other,, other.Location, other.Rotation );
			 		if( PH != none )
			 		{
			 			PH.myPickup = TournamentPickup(other);

			 			other.SetCollision( false, false, false );
			 			PH.SetCollisionSize( other.CollisionRadius, other.CollisionHeight );
			 		}
			 	}

				// Force everything to give max Health
				if( TournamentHealth(other) != none )
				{
		 			if( TournamentHealth(other).bSuperHeal || other.IsA('SuperHealthPack') )
						TournamentHealth(other).Default.HealingAmount = Class'xPawn'.Default.SuperHealthMax;
					else TournamentHealth(other).Default.HealingAmount = Class'xPawn'.Default.HealthMax;
					return true;
				}
		 		return true;
			}
			else if( xPickupBase(other) != none )
			{
				// We don't want to wait a minute for our pickups zzz...
				xPickupBase(other).bDelayedSpawn = false;
				return true;
			}
		}
		return true;
	}
	else if( Mover(other) != none )
	{
		if( bFixMovers )
		{
			if( Mover(other).MoverEncroachType == ME_ReturnWhenEncroach )		// Fix's the movers from stopping on encroach, old bug from 2005 xD
				Mover(other).MoverEncroachType = ME_IgnoreWhenEncroach;

			if( bAdjustNetPrioritys )
				Mover(other).NetPriority = MoverNetPriority;	// IDK if that's of any help...
		}
		return true;
	}
	// TFAMap.u is no longer relevant, we should make sure all such instances are removed from the game.
	// TFAEmbed does also not call the NextMutator events which may break mutators that are dependant on such events.
	else if( other.IsA('TFAEmbed') || other.IsA('MayanTFAEmbed') )
	{
		return false;
	}
	return super.CheckReplacement(other,bSuperRelevant);
}

final function ReplaceWeaponLocker( WeaponLocker weaponLocker )
{
	local int i;

	for( i = 0; i < weaponLocker.Weapons.Length; ++ i )
	{
		weaponLocker.Weapons[i].WeaponClass = class<Weapon>(Level.Game.BaseMutator.GetInventoryClass( string(weaponLocker.Weapons[i].WeaponClass) ));
	}
}

// Evil hack to replace unloaded volumes.
final function ReplaceVolumeWeapons( Volume Other )
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

function GetServerDetails( out GameInfo.ServerResponseLine ServerState )
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
static function FillPlayInfo( PlayInfo Info )
{
	super.FillPlayInfo(Info);
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
static event string GetDescriptionText( string PropName )
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
	return super.GetDescriptionText(PropName);
}

defaultproperties
{
	FriendlyName="Trials Plus"
	Description="Replaces those annoying ShieldGun's that auto fire when coming near a player of your team, Note:Replaces the pawn class if it is xPawn or UTComp_Pawn, will not function properly if other mutators replacing the pawn class are running!. Created by Eliot/.:..: 2006-2009"
	RulesGroup="TrialsPlus"
	Group="TrialsPlus"

	bFastRespawnItems=true
	bInfinityBioRifleAmmo=true
	bAllowAltGlitch=true
	bFadeOutTeamMates=true
	bFixMovers=true
	bAdjustNetPrioritys=true

	SuicideDelay=1.5
	DrownDamage=5

	NewInventoryClasses(0)=(ClassName="XWeapons.ShieldGun",NewClass=class'ShieldGunFix')
	NewInventoryClasses(1)=(ClassName="MutDMShieldGun.DMShieldGun",NewClass=class'DMShieldGunFix')
	NewInventoryClasses(2)=(ClassName="MutDMShieldGunFix.DMShieldGun",NewClass=class'DMShieldGunFix')
	NewInventoryClasses(3)=(ClassName="AbaddonShield.ADShieldGun",NewClass=class'ADShieldGunFix')
	NewInventoryClasses(4)=(ClassName="MayanShieldGun",NewClass=class'PinkShieldGun')
	NewInventoryClasses(5)=(ClassName="TFShieldGun",NewClass=class'ShieldGunFix')
	NewInventoryClasses(6)=(ClassName="MTShieldGun",NewClass=class'ShieldGunFix')
	NewInventoryClasses(7)=(ClassName="XWeapons.BioRifle",NewClass=class'BioRifleFix')
	NewInventoryClasses(8)=(ClassName="XWeapons.AssaultRifle",NewClass=class'AssaultRifleFix')

	bAddToServerPackages=true
	ConfigCroupName="MNAF_Save_Data"

	C_CmdPublic=(R=0,G=255,B=0,A=255)
	C_CmdAdmin=(R=255,G=0,B=0,A=255)
	C_Cmd=(R=50,G=50,B=100,A=255)

	SGNetPriority=12
	SGNetFreq=4
	MoverNetPriority=10
}
