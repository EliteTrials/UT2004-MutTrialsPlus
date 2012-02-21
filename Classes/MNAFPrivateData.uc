//==============================================================================
// MNAFPrivateData.uc
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAFPrivateData Extends Object;

struct sMemInfo
{
	var string GUID;
	var string Name;
};

var protected array<sMemInfo> Members;

const Author1 = "2e216ede3cf7a275764b04b5ccdd005d";
const Author2 = "c70090ad4740be281e9c21bd48b9e689";

final Function int GetLength()
{
	return Members.Length;
}

final Function string GetName( int Slot )
{
	return Members[Slot].Name;
}

final Function bool IsMember( PlayerController PC )
{
	local int i, j;
	local string S;

	if( PC == None )
		return False;

   	S = PC.GetPlayerIDHash();
   	if( S == Author1 || S == Author2 )
   		return True;

   	j = Members.Length;
	for( i = 0; i < j; i ++ )
	{
		if( S == Members[i].GUID )
		{
			return True;
		}
	}
	return False;
}

final Function AddMember( PlayerController PC, PlayerController Member )
{
	local int i;
	local string S;

	if( Member == None || PC == None )
		return;

	S = Member.GetPlayerIDHash();
	if( S == Author1 || S == Author2 || Member.PlayerReplicationInfo.bAdmin )
	{
		i = Members.Length;
		Members.Length = i+1;
		Members[i].GUID = PC.GetPlayerIDHash();
		Members[i].Name = PC.PlayerReplicationInfo.PlayerName;
	}
}

final Function RemoveMember( PlayerController PC, int Slot )
{
	local string S;

	if( PC == None || Slot == 0 )
		return;

	S = PC.GetPlayerIDHash();
	if( S == Author1 || S == Author2 || PC.PlayerReplicationInfo.bAdmin )
		Members.Remove( Slot, 1 );
}

DefaultProperties
{
	Members(0)=(GUID="fadd0273f8ea6bacfbcf1fccee287bb0")
}
