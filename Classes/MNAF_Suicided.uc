//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAF_Suicided Extends Suicided;

Static Function string SuicideMessage( PlayerReplicationInfo Victim )
{
	local LinkedReplicationInfo L;
	local string S;
	local color c;

	if( Victim != None )
	{
		for( L = Victim.CustomReplicationInfo; L != None; L = L.NextReplicationInfo )
		{
			if( MNAFLinkedRep(L) != None && MNAFLinkedRep(L).CustomScdMsg != "" )
			{
				S = MNAFLinkedRep(L).CustomScdMsg;
				/*if( (InStr( S, "%UTCOMP" )) != -1 )
				{
					for( ExL = Victim.CustomReplicationInfo; ExL != None; ExL = ExL.NextReplicationInfo )
					{
						if( ExL.IsA('UTComp_PRI') )
						{
							S = Repl( S, "%o", ExL.GetPropertyText( "ColoredName" ) );
							break;
						}
					}
				}*/

				S = Repl( S, "%d", "("$int(Victim.Deaths)$")" );
				S = Repl( S, "%l", "("$Victim.GetLocationName()$")" );
				S = Repl( S, "%m", "("$Victim.Outer.Name$")" );
				S = Repl( S, "%pl", "("$Victim.PacketLoss$")" );
				S = Repl( S, "%p", "("$Min( 999, 4*Victim.Ping )$")" );
				S = Repl( S, "%red", Class'MNAFLinkedRep'.Static.ExMakeColorCode( Class'HUD'.Default.RedColor ) );
				S = Repl( S, "%green", Class'MNAFLinkedRep'.Static.ExMakeColorCode( Class'HUD'.Default.GreenColor ) );
				S = Repl( S, "%blue", Class'MNAFLinkedRep'.Static.ExMakeColorCode( Class'HUD'.Default.BlueColor ) );

				if( (InStr( S, "%rand" )) != -1 )
				{
 					c.r = Rand( 255 );
 					c.g = Rand( 255 );
 					c.b = Rand( 255 );
 					c.a = 255;
					S = Repl( S, "%rand", Class'MNAFLinkedRep'.Static.ExMakeColorCode( c ) );
				}

				/*if( (InStr( S, "%s" )) != -1 )
				{
					if( Victim.bIsFemale )
						S = Repl( S, "%s", "she" );
					else S = Repl( S, "%s", "he" );
				}*/
				return S;
			}
		}
	}
	return Default.DeathString;
}

