//=============================================================================
// ADShieldGun.
// Coded by Eliot.
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//=============================================================================
Class ADShieldGunFix Extends ShieldGunFix;

DefaultProperties
{
	Description="Abaddon's ShieldGun"
	ItemName="Abaddon's ShieldGun"

	FireModeClass(0)=Class'ADShieldFireFix'
	PickupClass=Class'ADShieldGunFixPick'

	Priority=9
}
