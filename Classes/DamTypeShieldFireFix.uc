//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class DamTypeShieldFireFix Extends DamTypeShieldImpact;

Static Function string SuicideMessage( PlayerReplicationInfo Victim )
{
	if( Victim != None )
	{
		if( Victim.bIsFemale )
			return Repl( Default.FemaleSuicide, "%d", "("$int(Victim.Deaths)$")" );
		else return Repl( Default.MaleSuicide, "%d", "("$int(Victim.Deaths)$")" );
	}
}

DefaultProperties
{
	FemaleSuicide="%o %d fired her ShieldGun once to much."
	MaleSuicide="%o %d fired his ShieldGun once to much."
	bCausesBlood=True
}
