//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
class BioRifleFix extends BioRifle;

var bool bInfinityAmmo;

replication
{
	reliable if( bNetDirty && (Role==ROLE_Authority) && bNetOwner )
		bInfinityAmmo;
}

simulated function float ChargeBar()
{
    return FMin(1,FireMode[1].HoldTime/(BioChargedFire(FireMode[1]).GoopUpRate*BioChargedFire(FireMode[1]).MaxGoopLoad));
}
simulated function bool HasAmmo()
{
	if( bInfinityAmmo )
		Return True;
	Return Super.HasAmmo();
}
simulated function bool NeedAmmo(int mode)
{
	if( bInfinityAmmo )
		Return False;
	Return Super.NeedAmmo(mode);
}
simulated function CheckOutOfAmmo()
{
	if( !bInfinityAmmo )
		Super.CheckOutOfAmmo();
}
simulated function bool ConsumeAmmo(int Mode, float load, optional bool bAmountNeededIsMax)
{
	if( bInfinityAmmo )
		Return True;
	Return Super.ConsumeAmmo(Mode,load,bAmountNeededIsMax);
}
simulated function float AmmoStatus(optional int Mode)
{
	if( bInfinityAmmo )
		Return 1;
	Return Super.AmmoStatus(Mode);
}

defaultproperties
{
	FireModeClass(0)=BioFireFix
	FireModeClass(1)=BioChargedFireFix
	PickupClass=Class'BioRifleFixPick'
	bShowChargingBar=True
}
