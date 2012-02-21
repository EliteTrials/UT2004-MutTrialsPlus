//==============================================================================
// MNAFBroadCastHandler.uc
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAFBroadCastHandler Extends BroadcastHandler;

// Get rid of the spam from noobs... :)
Function BroadcastText( PlayerReplicationInfo SenderPRI, PlayerController Receiver, coerce string Msg, optional name Type )
{
	local string TempMsg;
	local LinkedReplicationInfo L;

 	TempMsg = Caps( Msg );
 	if( SenderPRI != None && PlayerController(SenderPRI.Owner) != None && Type == 'Say' )
 	{
 		for( L = SenderPRI.CustomReplicationInfo; L != None; L = L.NextReplicationInfo )
		{
			if( MNAFLinkedRep(L) != None )
			{
				Msg = MNAFLinkedRep(L).ReplaceWithTags( Level.Game.StripColor( Msg ) );
				break;
			}
		}

		if(  (InStr( TempMsg, "SHIELD" ) != -1 && InStr( TempMsg, "COLOR" ) != -1 && InStr( TempMsg, "HOW" ) != -1 && !(InStr( TempMsg, "TYPE" ) != -1)) )
			PlayerController(SenderPRI.Owner).ClientMessage( "Please type 'Mutate MNAFHelp' in the console to get a list of commands." );
	}
	Super.BroadcastText(SenderPRI,Receiver,Msg,Type);
}
