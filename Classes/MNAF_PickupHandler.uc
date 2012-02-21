//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAF_PickupHandler Extends Actor;

var Pickup myPickup;

var int CurToucher, NumTouchers;

Function Touch( Actor Other )
{
	if( xPawn(Other) != None )
	{
		if( myPickup == None )
		{
			Destroy();
			return;
		}

		myPickup.Touch( Other );
		if( !myPickup.IsInState( 'Pickup' ) )
		{
			myPickup.GotoState( 'Pickup', 'Begin' );
			myPickup.RespawnEffect();
		}
		GotoState( 'RePickup', 'Begin' );
		return;
	}
}

State RePickup
{
Begin:
	Sleep( 0.1 );
	NumTouchers = Touching.Length;
	for( CurToucher = 0; CurToucher < NumTouchers; CurToucher ++ )
		Global.Touch( Touching[CurToucher] );

	NumTouchers = 0;
	CurToucher = 0;
	GotoState( '' );
}

DefaultProperties
{
    bCollideActors=True
    bCollideWorld=True

	bNoDelete=False
	bStatic=False

	bHidden=True
}
