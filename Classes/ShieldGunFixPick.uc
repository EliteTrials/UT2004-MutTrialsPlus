//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class ShieldGunFixPick Extends UTWeaponPickup
	HideDropDown;

DefaultProperties
{
	InventoryType=Class'ShieldGunFix'
	PickupMessage="You got the ShieldGun"
	PickupSound=Sound'PickupSounds.ShieldGunPickup'
	PickupForce="ShieldGunFixPick"
	StaticMesh=StaticMesh'WeaponStaticMesh.ShieldGunPickup'
	DrawType=DT_StaticMesh
	DrawScale=0.5
}
