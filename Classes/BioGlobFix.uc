//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
class BioGlobFix extends BioGlob;

var struct HitFloorType
{
	var vector LandingPos,LandingNormal;
	var Actor BaseActor;
} RepHitFloor;
var bool bClientAllowHit;
var byte GooLevel,OlGooSize;

replication
{
	reliable if( Role == ROLE_Authority )
		RepHitFloor,GooLevel;
}

simulated function PostNetBeginPlay();

simulated function PostNetReceive()
{
	if( RepHitFloor.LandingPos!=vect(0,0,0) )
	{
		SetLocation(RepHitFloor.LandingPos);
		bClientAllowHit = True;
		if( !IsInState('Flying') )
			GoToState('Flying');
		Landed(RepHitFloor.LandingNormal/100);
		SetBase(RepHitFloor.BaseActor);
		RepHitFloor.LandingPos = vect(0,0,0);
		bHidden = False;
	}
	if( OlGooSize!=GooLevel )
	{
		OlGooSize = GooLevel;
		SetGoopLevel(GooLevel);
	}
}

auto state Flying
{
	simulated function Landed( Vector HitNormal )
	{
		local Rotator NewRot;
		local int CoreGoopLevel;

		if( Level.NetMode==NM_Client && !bClientAllowHit )
		{
			SetPhysics(PHYS_None);
			bHidden = True;
			Return;
		}
		else if( Level.NetMode!=NM_Client )
		{
			RepHitFloor.LandingPos = Location;
			RepHitFloor.LandingNormal = HitNormal*100;
			if( Base!=None )
				RepHitFloor.BaseActor = Base;
		}
		if ( Level.NetMode != NM_DedicatedServer )
			PlaySound(ImpactSound, SLOT_Misc);

		SurfaceNormal = HitNormal;

		// spawn globlings
		if( Level.NetMode!=NM_Client )
		{
			CoreGoopLevel = Rand3 + MaxGoopLevel - 3;
			if (GoopLevel > CoreGoopLevel)
			{
				if (Role == ROLE_Authority)
					SplashGlobs(GoopLevel - CoreGoopLevel);
				SetGoopLevel(CoreGoopLevel);
			}
		}
		spawn(class'BioDecal',,,, rotator(-HitNormal));

		bCollideWorld = false;
		SetCollisionSize(GoopVolume*10.0, GoopVolume*10.0);
		bProjTarget = true;

		NewRot = Rotator(HitNormal);
		NewRot.Roll += 32768;
		SetRotation(NewRot);
		SetPhysics(PHYS_None);
		bCheckedsurface = false;
		if ( Level.Game!=None )
			Fear = Spawn(class'AvoidMarker');
		GotoState('OnGround');
	}
	simulated function ProcessTouch(Actor Other, Vector HitLocation)
	{
		local BioGlob Glob;

		if( Level.NetMode==NM_Client ) Return; // Not a code for clients!
		Glob = BioGlob(Other);
		if ( Glob != None )
		{
			if (Glob.Owner == None || (Glob.Owner != Owner && Glob.Owner != self))
			{
				if (bMergeGlobs)
				{
					Glob.MergeWithGlob(GoopLevel); // balancing on the brink of infinite recursion
					bNoFX = true;
					Destroy();
				}
				else BlowUp( HitLocation );
			}
		}
		else if (Other != Instigator && (Other.IsA('Pawn') || Other.IsA('DestroyableObjective') || Other.bProjTarget))
			BlowUp( HitLocation );
		else if ( Other != Instigator && Other.bBlockActors )
			HitWall( Normal(HitLocation-Location), Other );
	}
}
state OnGround
{
	function MergeWithGlob(int AdditionalGoopLevel)
	{
		local int NewGoopLevel, ExtraSplash;

		if( Level.NetMode==NM_Client ) Return;
		NewGoopLevel = AdditionalGoopLevel + GoopLevel;
		if (NewGoopLevel > MaxGoopLevel)
		{
			Rand3 = (Rand3 + 1) % 3;
			ExtraSplash = Rand3;
			SplashGlobs(NewGoopLevel - MaxGoopLevel + ExtraSplash);
			NewGoopLevel = MaxGoopLevel - ExtraSplash;
		}
		SetGoopLevel(NewGoopLevel);
		SetCollisionSize(GoopVolume*10.0, GoopVolume*10.0);
		PlaySound(ImpactSound, SLOT_Misc);
		PlayAnim('hit');
		bCheckedSurface = false;
		SetTimer(RestTime*(DrawScale/2+0.5), false);
	}
	simulated function SetGoopLevel( int NewGoopLevel )
	{
		PlaySound(ImpactSound, SLOT_Misc);
		PlayAnim('hit');
		Global.SetGoopLevel(NewGoopLevel);
		SetCollisionSize(GoopVolume*10.0, GoopVolume*10.0);
	}
}
function BlowUp(Vector HitLocation)
{
	if( Level.NetMode!=NM_Client )
		Super.BlowUp(HitLocation);
}
simulated function SetGoopLevel( int NewGoopLevel )
{
	Super.SetGoopLevel(NewGoopLevel);
	GooLevel = NewGoopLevel;
}

defaultproperties
{
	bNetNotify=True
	RestTime=3
}
