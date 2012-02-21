//=============================================================================
// XMonController.
// Fixed by .:..:
// Used to be in BTimesMute, But removed since version 2.92
//=============================================================================
class XMonController extends MonsterController;

function bool FindNewEnemy()
{
	Return false;
}
function FightEnemy(bool bCanCharge)
{
	local vector X,Y,Z;
	local float enemyDist;
	local float AdjustedCombatStyle, Aggression;
	local bool bFarAway, bOldForcedCharge;

	if( Pawn==None ) Return;
	Pawn.DeactivateSpawnProtection();
	if ( (Enemy == None) || (Pawn == None) )
		log("HERE 3 Enemy "$Enemy$" pawn "$Pawn);

	if ( (Enemy == FailedHuntEnemy) && (Level.TimeSeconds == FailedHuntTime) )
	{
		if ( !Enemy.Controller.bIsPlayer )
			FindNewEnemy();

		if ( Enemy == FailedHuntEnemy )
		{
			GoalString = "FAILED HUNT - HANG OUT";
			if ( EnemyVisible() )
				bCanCharge = false;
			if ( !EnemyVisible() )
			{
				WanderOrCamp(true);
				return;
			}
		}
	}

	bOldForcedCharge = bMustCharge;
	bMustCharge = false;
	enemyDist = VSize(Pawn.Location - Enemy.Location);
	AdjustedCombatStyle = CombatStyle;
	Aggression = 1.5 * FRand() - 0.8 + 2 * AdjustedCombatStyle
				+ FRand() * (Normal(Enemy.Velocity - Pawn.Velocity) Dot Normal(Enemy.Location - Pawn.Location));
	if ( Enemy.Weapon != None )
		Aggression += 2 * Enemy.Weapon.SuggestDefenseStyle();
	if ( enemyDist > MAXSTAKEOUTDIST )
		Aggression += 0.5;
	if ( (Pawn.Physics == PHYS_Walking) || (Pawn.Physics == PHYS_Falling) )
	{
		if (Pawn.Location.Z > Enemy.Location.Z + TACTICALHEIGHTADVANTAGE)
			Aggression = FMax(0.0, Aggression - 1.0 + AdjustedCombatStyle);
		else if ( (Skill < 4) && (enemyDist > 0.65 * MAXSTAKEOUTDIST) )
		{
			bFarAway = true;
			Aggression += 0.5;
		}
		else if (Pawn.Location.Z < Enemy.Location.Z - Pawn.CollisionHeight) // below enemy
			Aggression += CombatStyle;
	}

	if ( !EnemyVisible() )
	{
		GoalString = "Enemy not visible";
		if ( !bCanCharge )
		{
			GoalString = "Stake Out";
			DoStakeOut();
		}
		else
		{
			GoalString = "Hunt";
			GotoState('Hunting');
		}
		return;
	}

	// see enemy - decide whether to charge it or strafe around/stand and fire
	Target = Enemy;
	if( Monster(Pawn).PreferMelee() || (bCanCharge && bOldForcedCharge) )
	{
		GoalString = "Charge";
		DoCharge();
		return;
	}

	if ( bCanCharge && (Skill < 5) && bFarAway && (Aggression > 1) && (FRand() < 0.5) )
	{
		GoalString = "Charge closer";
		DoCharge();
		return;
	}

	if ( !Monster(Pawn).PreferMelee() && (FRand() > 0.17 * (skill - 1)) && !DefendMelee(enemyDist) )
	{
		GoalString = "Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	if ( bCanCharge )
	{
		if ( Aggression > 1 )
		{
			GoalString = "Charge 2";
			DoCharge();
			return;
		}
	}

	if ( !Pawn.bCanStrafe )
	{
		GoalString = "Ranged Attack";
		DoRangedAttackOn(Enemy);
		return;
	}

	GoalString = "Do tactical move";
	if ( !Monster(Pawn).RecommendSplashDamage() && Monster(Pawn).bCanDodge && (FRand() < 0.7) && (FRand()*Skill > 3) )
	{
		GetAxes(Pawn.Rotation,X,Y,Z);
		GoalString = "Try to Duck ";
		if ( FRand() < 0.5 )
		{
			Y *= -1;
			TryToDuck(Y, true);
		}
		else
			TryToDuck(Y, false);
	}
	DoTacticalMove();
}
state RestFormation
{
	ignores EnemyNotVisible;

	function CancelCampFor(Controller C)
	{
		DirectedWander(Normal(Pawn.Location - C.Pawn.Location));
	}

	function bool Formation()
	{
		return true;
	}

	function Timer()
	{
		SetCombatTimer();
		enable('NotifyBump');
	}


	function PickDestination()
	{
		if ( TestDirection(VRand(),Destination) )
			return;
		TestDirection(VRand(),Destination);
	}

	function BeginState()
	{
		Enemy = None;
		Pawn.bCanJump = false;
		Pawn.bAvoidLedges = true;
		Pawn.bStopAtLedges = true;
		Pawn.SetWalking(true);
		MinHitWall += 0.15;
	}

	function EndState()
	{
		MonitoredPawn = None;
		MinHitWall -= 0.15;
		if ( Pawn != None )
		{
			Pawn.bStopAtLedges = false;
			Pawn.bAvoidLedges = false;
			Pawn.SetWalking(false);
			if (Pawn.JumpZ > 0)
				Pawn.bCanJump = true;
		}
	}

	event MonitoredPawnAlert()
	{
		WhatToDoNext(6);
	}

Begin:
	WaitForLanding();
	if( Enemy==None )
	{
		Pawn.Acceleration = vect(0,0,0);
		Focus = None;
		FocalPoint = vector(Pawn.Rotation)*100+Pawn.Location;
		Stop;
	}
Camping:
	Pawn.Acceleration = vect(0,0,0);
	Focus = None;
	FocalPoint = VRand();
	NearWall(MINVIEWDIST);
	FinishRotation();
	Sleep(3 + FRand());
Moving:
	WaitForLanding();
	PickDestination();
WaitForAnim:
	if ( Monster(Pawn).bShotAnim )
	{
		Sleep(0.5);
		Goto('WaitForAnim');
	}
	MoveTo(Destination,,true);
	if ( Pawn.bCanFly && (Physics == PHYS_Walking) )
		SetPhysics(PHYS_Flying);
	WhatToDoNext(8);
	Goto('Begin');
}
function ResetSkill()
{
	local float AdjustedYaw;

	Skill = FClamp((Level.Game.NumPlayers+2), 0, 7);
	bLeadTarget = ( Skill >= 4 );
	SetCombatTimer();
	SetPeripheralVision();
	if ( Skill + ReactionTime > 7 )
		RotationRate.Yaw = 90000;
	else if ( Skill + ReactionTime >= 4 )
		RotationRate.Yaw = 20000 + 7000 * (skill + ReactionTime);
	else
		RotationRate.Yaw = 30000 + 4000 * (skill + ReactionTime);
    AdjustedYaw = (0.75 + 0.05 * ReactionTime) * RotationRate.Yaw;
	AcquisitionYawRate = AdjustedYaw;
	SetMaxDesiredSpeed();
}
function SetPeripheralVision()
{
	if ( Pawn == None )
		return;
	Pawn.PeripheralVision = 0.8;
	Pawn.SightRadius = Pawn.Default.SightRadius*1.2;
}

defaultproperties
{
}
