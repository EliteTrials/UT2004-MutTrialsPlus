//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class DMShieldGunFix Extends ShieldGunFix;

DefaultProperties
{
	FireModeClass(0)=Class'DMShieldFireFix'
	Description="DM ShieldGun"
	ItemName="DM ShieldGun"
	PickupClass=Class'DMShieldGunFixPick'

	Priority=7
}
