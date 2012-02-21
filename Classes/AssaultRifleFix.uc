//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class AssaultRifleFix Extends AssaultRifle;

// Override to remove ClientSwitchToBestWeapon();
Simulated Function PostNetBeginPlay()
{
	Super(Weapon).PostNetBeginPlay();
}

DefaultProperties
{
	HudColor=(R=66,G=66,B=66,A=255)
	PickupClass=Class'AssaultRiflePickupFix
}
