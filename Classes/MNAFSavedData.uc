//==============================================================================
// MNAFSavedData.uc
// All saved information MNAF has is stored in this class!
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAFSavedData extends Object
	Config(MutNoAutoFire)
	PerObjectConfig;

var MNAFSavedData OldResult;

// NetFixPawn data
var() config string MySuicideMsg;
// Shieldgun data
var() config color ClientChosenColor;
// Material Types
var() config
	bool
	bUseFadeColor,
	bEnhancedMaterials,
	bTranslucent,
	bFadePlayerSkinAlong,
	bPR,
	bPlayDirectionalHits,
	bDisableCustomCrossHairColor;

static function MNAFSavedData FindSavedData()
{
	local MNAFSavedData M;
	local string S;

	if( Default.OldResult!=None )
		Return Default.OldResult;
	S = Class'MutNoAutoFire'.Default.ConfigCroupName;
	M = MNAFSavedData(FindObject("Package."$S, class'MNAFSavedData'));
	if( M==None )
		M = New(None,S) Class'MNAFSavedData';
	Default.OldResult = M;
	Return M;
}

DefaultProperties
{
	ClientChosenColor=(R=50,G=200,B=50,A=255)
	MySuicideMsg="%o had an aneurysm."
}
