//==============================================================================
// MNAFLinkedRep.uc
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAFLinkedRep Extends LinkedReplicationInfo;

var string CustomScdMsg;
var bool bFadeOutTeamMates;
var protected bool bIsUnique, bRainBow, bTranslucent, bRBS, bPinkRings;
var MutNoAutoFire MNAF;

Replication
{
	reliable if( bNetDirty && (Role == Role_Authority) )
		CustomScdMsg, bRainBow, bTranslucent, bRBS, bPinkRings;

	reliable if( bNetDirty && (Role == Role_Authority) && bNetOwner )
		bFadeOutTeamMates;

	reliable if( bNetDirty && (Role == ROLE_Authority) && bNetInitial && bNetOwner )
		bIsUnique;
}

Simulated Final Function bool IsUnique()
{
	return bIsUnique;
}

Simulated Final Function bool FadingOn()
{
	return bRainBow;
}

Simulated Final Function bool TransOn()
{
	return bTranslucent;
}

Simulated Final Function bool RBSOn()
{
	return bRBS;
}

Simulated Final Function  bool UsingPR()
{
	return bPinkRings;
}

Function Final PR( bool b )
{
	if( IsUnique() )
	{
		bPinkRings = b;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
}

Function Final RBS( bool b )
{
	if( IsUnique() )
	{
		bRBS = b;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
}

Function Final SetShieldTypes( bool A, bool B )
{
	if( IsUnique() )
	{
		bRainBow = A;
		bTranslucent = B;
		NetUpdateTime = Level.TimeSeconds - 1;
	}
}

Function Tick( float dt )
{
	Super.Tick(dt);

	if( Level.NetMode == NM_Client )
	{
		Disable( 'Tick' );
		return;
	}

	// by then id should of been replicated duh :>.
	if( MNAF != None && !bNetInitial )
	{
		bIsUnique = MNAF.IsMember( PlayerController(Owner) );
		NetUpdateTime = Level.TimeSeconds - 1;
//		Log( "bIsUnique:"$bIsUnique, Self.Name );
		Disable( 'Tick' );
		return;
	}
}

// by .:..:
// from GameInfo, but tweaked
static function string ExMakeColorCode( color NewColor )
{
	// Text colours use 1 as 0.
	if(NewColor.R == 0)
		NewColor.R = 1;
	else if(NewColor.R == 10)
		NewColor.R = 11;
	else if(NewColor.R == 127)
		NewColor.R = 128;

	if(NewColor.G == 0)
		NewColor.G = 1;
	else if(NewColor.G == 10)
		NewColor.G = 11;
	else if(NewColor.G == 127)
		NewColor.G = 128;

	if(NewColor.B == 0)
		NewColor.B = 1;
	else if(NewColor.B == 10)
		NewColor.B = 11;
	else if(NewColor.B == 127)
		NewColor.B = 128;

	return Chr(0x1B)$Chr(NewColor.R)$Chr(NewColor.G)$Chr(NewColor.B);
}

// Coded by .:..:
Static Function string ReplaceWithTags( string OrginalStr )
{
	local int i,j;
	local string S,F;
	local Color C;

	While( True )
	{
		i = InStr(OrginalStr,"{");
		if( i==-1 )
			Return F$OrginalStr;
		F = F$Left(OrginalStr,i);
		S = Mid(OrginalStr,i+1);
		j = InStr(S,"}");
		if( j==-1 )
			OrginalStr = S;
		else
		{
			OrginalStr = Mid(S,j+1);
			S = Left(S,j);
			C.R = 0;
			C.G = 0;
			C.B = 0;
			i = InStr(S,",");
			if( i==-1 )
				C.R = byte(S);
			else
			{
				C.R = byte(Left(S,i));
				S = Mid(S,i+1);
				i = InStr(S,",");
				if( i==-1 )
					C.G = byte(S);
				else
				{
					C.G = byte(Left(S,i));
					C.B = byte(Mid(S,i+1));
				}
			}
			F = F$ExMakeColorCode(C);
		}
	}
}

function PostBeginPlay()
{
	SetTimer( 1, True );
}

function Timer()
{
	if( Owner == None )
		Destroy();
}

DefaultProperties
{
}
