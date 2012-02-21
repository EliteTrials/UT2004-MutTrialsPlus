//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class TeleResetActor extends Info
	NotPlaceable;

var Teleporter TeleActor;
var bool bWasEnabled;

function Reset()
{
	if( TeleActor==None )
		Destroy();
	else TeleActor.bEnabled = bWasEnabled;
}
