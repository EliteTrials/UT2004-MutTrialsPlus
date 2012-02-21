//==============================================================================
// MutNoAutoFire (C) 2006-2009 Eliot van uytfanghe, .:..:. All Rights Reserved.
//==============================================================================
Class MNAF_Menu Extends FloatingWindow;

var automated GUIButton b_Save, b_Reset;
var automated GUISlider s_Red, s_Green, s_Blue, s_Alpha;
var automated moCheckBox cb_UseFadeColor, cb_EnhancedMaterials, cb_Translucent, cb_PlayerSkinFade, cb_PinkRings;
var automated GUILabel l_ShieldColor;
var editconst ColorModifier SlideColor[4];
//var automated GUIScrollTextBox st_LeftB;
var automated GUISectionBackground sbg_bg, sbg_render;
var automated GUIImage ShieldGunBounds;
var editconst MNAF_PreviewWep ShieldGun;
var() vector ShieldGun_Offset;

var editconst Shader ShaderMaterial;
var editconst ConstantColor ColorMaterial;
// Used for saving.
var editconst MNAFSavedData UserData;
var editconst bool bSlidersDisabled, bCanSave;

Function Opened( GUIComponent Sender )
{
	if( PlayerOwner().Pawn == None || ShieldGunFix(PlayerOwner().Pawn.Weapon) == None )
		Controller.CloseMenu();

	if( !ShieldGunFix(PlayerOwner().Pawn.Weapon).CanUseUniqueColor() )
		DisableMemberFeatures();

	UserData = Class'MNAFSavedData'.Static.FindSavedData();
	if( UserData != None )
	{
		LoadData();
		if( cb_UseFadeColor.IsChecked() )
			DisableColorSliders( True );
		else EnableColorSliders();
	}
	// Setup color for sliders...
	if( s_Red != None && s_Green != None && s_Blue != None && s_Alpha != None )
	{
		SlideColor[0] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
		SlideColor[0].Material = s_Red.FillImage;
		SlideColor[0].Color.R = 255;
		SlideColor[0].Color.G = 0;
		SlideColor[0].Color.B = 0;
		s_Red.FillImage = SlideColor[0];
		SlideColor[1] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
		SlideColor[1].Material = s_Green.FillImage;
		SlideColor[1].Color.R = 0;
		SlideColor[1].Color.G = 255;
		SlideColor[1].Color.B = 0;
		s_Green.FillImage = SlideColor[1];
		SlideColor[2] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
		SlideColor[2].Material = s_Blue.FillImage;
		SlideColor[2].Color.R = 0;
		SlideColor[2].Color.G = 0;
		SlideColor[2].Color.B = 255;
		s_Blue.FillImage = SlideColor[2];
		SlideColor[3] = ColorModifier(PlayerOwner().Level.ObjectPool.AllocateObject( Class'ColorModifier' ));
		SlideColor[3].Material = s_Alpha.FillImage;
		SlideColor[3].Color.R = 255;
		SlideColor[3].Color.G = 255;
		SlideColor[3].Color.B = 255;
		s_Alpha.FillImage = SlideColor[3];
	}
	Super.Opened(Sender);

	InitializeShieldGun();
	if( ShaderMaterial != None )
	{
		if( cb_Translucent.IsChecked() )
			ShaderMaterial.OutputBlending = OB_Translucent;
		else ShaderMaterial.OutputBlending = OB_Normal;
	}
}

Function Closed( GUIComponent Sender, bool bCancelled )
{
	local int i;

	if( ShieldGun != None )
	{
		ShieldGun.Destroy();
		ShieldGun = None;
	}

	for( i = 0; i < 3; i ++ )
	{
		if( SlideColor[i] != None )
		{
			SlideColor[i].Material = SlideColor[i].Default.Material;
			SlideColor[i].Color = SlideColor[i].Default.Color;
			PlayerOwner().Level.ObjectPool.FreeObject( SlideColor[i] );
			SlideColor[i] = None;
		}
	}

	if( ColorMaterial != None )
		PlayerOwner().Level.ObjectPool.FreeObject( ColorMaterial );

	if( ShaderMaterial != None )
		PlayerOwner().Level.ObjectPool.FreeObject( ShaderMaterial );

	ColorMaterial = None;
	ShaderMaterial = None;
	Super.Closed(Sender,bCancelled);
}

Function MNAFLinkedRep GetMLR()
{
	local LinkedReplicationInfo L;
	for( L = PlayerOwner().PlayerReplicationInfo.CustomReplicationInfo; L != None; L = L.NextReplicationInfo )
	{
		if( MNAFLinkedRep(L) != None )
			return MNAFLinkedRep(L);
	}
}

// Update ini config
Function SaveData()
{
	local color newcol;

	newcol.R = s_Red.Value;
	newcol.G = s_Green.Value;
	newcol.B = s_Blue.Value;
	newcol.A = s_Alpha.Value;
	// Apply Shield color...
	if( UserData != None )
	{
		UserData.bUseFadeColor = cb_UseFadeColor.IsChecked();
		UserData.bEnhancedMaterials = cb_EnhancedMaterials.IsChecked();
		UserData.bTranslucent = cb_Translucent.IsChecked();
		UserData.bFadePlayerSkinAlong = cb_PlayerSkinFade.IsChecked();
		UserData.bPR = cb_PinkRings.IsChecked();
		//GetMLR().ServerUpdateOptions( UserData.bPR );
		UserData.SaveConfig();
		ShieldGunFix(PlayerOwner().Pawn.Weapon).UpdateShieldTypes();

		// Do this after serverupdate incase features got turned off and we dont want to keep its unique color.
		PlayerOwner().ConsoleCommand( "SetShieldColor (R="$newcol.r$",G="$newcol.g$",B="$newcol.b$",A="$newcol.a$")" );
	}
}

// Load ini config
Function LoadData()
{
	UpdateSliderValues( UserData.ClientChosenColor );	// Set color to current client color

	if( ShieldGunFix(PlayerOwner().Pawn.Weapon).CanUseUniqueColor() )
	{
		cb_UseFadeColor.Checked( UserData.bUseFadeColor );
		cb_EnhancedMaterials.Checked( UserData.bEnhancedMaterials );
		cb_Translucent.Checked( UserData.bTranslucent );
		cb_PlayerSkinFade.Checked( UserData.bFadePlayerSkinAlong );
		cb_PinkRings.Checked( UserData.bPR );
	}
}

Function DisableMemberFeatures()
{
	cb_UseFadeColor.Checked( False );
	cb_EnhancedMaterials.Checked( False );
	cb_Translucent.Checked( False );
	cb_PlayerSkinFade.Checked( False );
	cb_PinkRings.Checked( False );

	DisableComponent( cb_Translucent );
	DisableComponent( cb_UseFadeColor );
	DisableComponent( cb_EnhancedMaterials );
	DisableComponent( cb_PlayerSkinFade );
	DisableComponent( cb_PinkRings );
	DisableComponent( sbg_bg );
}

Function UpdateSliderValues( color newvalue )
{
	s_Red.SetValue( newvalue.R );
	s_Green.SetValue( newvalue.G );
	s_Blue.SetValue( newvalue.B );
	s_Alpha.SetValue( newvalue.A );

	if( ColorMaterial != None )
		ColorMaterial.Color = newvalue;
}

Function DisableColorSliders( optional bool bLeaveAlpha )
{
	DisableComponent( s_Red );
	DisableComponent( s_Green );
	DisableComponent( s_Blue );
	if( !bLeaveAlpha )
		DisableComponent( s_Alpha );
	bSlidersDisabled = True;
}
Function EnableColorSliders()
{
	EnableComponent( s_Red );
	EnableComponent( s_Green );
	EnableComponent( s_Blue );
	EnableComponent( s_Alpha );
	bSlidersDisabled = False;
}

Function bool InternalOnClick( GUIComponent Sender )
{
	EnableComponent( b_Save );
	if( Sender == b_Save )
	{
		SaveData();
		DisableComponent( b_Save );
		return True;
	}
	else if( Sender == b_Reset )
	{
		if( UserData != None )
		{
			UpdateSliderValues( UserData.Default.ClientChosenColor );
			cb_UseFadeColor.Checked( UserData.Default.bUseFadeColor );
			cb_EnhancedMaterials.Checked( UserData.Default.bEnhancedMaterials );
			cb_Translucent.Checked( UserData.Default.bTranslucent );
			cb_PlayerSkinFade.Checked( UserData.Default.bFadePlayerSkinAlong );
			cb_PinkRings.Checked( UserData.Default.bPR );
			SaveData();
			return True;
		}
	}
	else if( Sender == s_Alpha )
		SlideColor[3].Color.A = byte( s_Alpha.GetValueString() );
	return False;
}

Function InternalOnChange( GUIComponent Sender )
{
	EnableComponent( b_Save );
	if( Sender == cb_UseFadeColor )
	{
		if( cb_UseFadeColor.IsChecked() )
			DisableColorSliders( True );
		else EnableColorSliders();
	}
	else if( Sender == cb_Translucent )
	{
		if( cb_Translucent.IsChecked() )
			ShaderMaterial.OutputBlending = OB_Translucent;
		else ShaderMaterial.OutputBlending = OB_Normal;
	}
}

Function InitializeShieldGun()
{
	if( ShieldGun == None )
		ShieldGun = PlayerOwner().Spawn( Class'MNAF_PreviewWep' );

	if( ShieldGun != None )
	{
		ShieldGun.bHidden = True;
		ShieldGun.SetDrawType( DT_Mesh );
		ShieldGun.LinkMesh( Class'ShieldGun'.Default.Mesh );
		ShieldGun.SetDrawScale( 2.0 );

		if( ColorMaterial == None )
			ColorMaterial = ConstantColor( PlayerOwner().Level.ObjectPool.AllocateObject( Class'ConstantColor' ) );

		if( ShaderMaterial == None )
			ShaderMaterial = Shader( PlayerOwner().Level.ObjectPool.AllocateObject( Class'Shader' ) );

		ShaderMaterial.Diffuse = Texture'ShieldTexAlpha';
		ShaderMaterial.Specular = ColorMaterial;	// Constant Color.
		ShaderMaterial.SpecularityMask = Texture'ShieldTexAlpha';
		ShaderMaterial.Detail = Class'ShieldGunFix'.Default.Skins[0];
		ShaderMaterial.DetailScale = 1.0;
		ShieldGun.Skins[0] = ShaderMaterial;
		ShieldGun.SpinRate = 4000;
	}
}

Function UpdateShieldGun()
{
	if( ColorMaterial != None )
	{
		ColorMaterial.Color.A = 255;
		if( cb_UseFadeColor.IsChecked() )
		{
			ColorMaterial.Color = Class'ShieldGunFix'.Static.GetFlashColor( PlayerOwner().Level.TimeSeconds/PlayerOwner().Level.TimeDilation );
			return;
		}
		ColorMaterial.Color.R = s_Red.Value;
		ColorMaterial.Color.G = s_Green.Value;
		ColorMaterial.Color.B = s_Blue.Value;
	}
}

Function bool InternalOnDraw( Canvas C )
{
	local vector CamPos, X, Y, Z;
	local rotator CamRot;

	if( ShieldGun == None )
		return False;

	C.GetCameraLocation( CamPos, CamRot );
	GetAxes( CamRot, X, Y, Z );
	ShieldGun.SetLocation( CamPos + (ShieldGun_Offset.X * X) + (ShieldGun_Offset.Y * Y) + (ShieldGun_Offset.Z * Z));
	UpdateShieldGun();
	C.DrawActorClipped( ShieldGun, False, ShieldGunBounds.ActualLeft(), ShieldGunBounds.ActualTop(), ShieldGunBounds.ActualWidth(), ShieldGunBounds.ActualHeight(), True );
	return True;
}


DefaultProperties
{
	ShieldGun_Offset=(X=250.0,Y=1.00,Z=-24.00);
	bCanSave=True
	bAllowedAsLast=True
	WinWidth=0.600000
	WinHeight=0.600000
	WinLeft=0.100000
	WinTop=0.100000
	WindowName="MNAF User Configuration"

	Begin Object class=GUIImage name=ShieldGunBoundsImage
		bScaleToParent=True
		bBoundToParent=True
		WinWidth=0.500000
		WinHeight=0.500000
		WinLeft=0.450000
		WinTop=0.040000
		Image=Material'2K4Menus.Controls.buttonSquare_b'
		ImageColor=(R=255,G=255,B=255,A=128)
		ImageRenderStyle=MSTY_Alpha
		ImageStyle=ISTY_Stretched
		RenderWeight=0.52
		DropShadow=Material'2K4Menus.Controls.Shadow'
		DropShadowX=4
		DropShadowY=4
		OnDraw=InternalOnDraw
	End Object
	ShieldGunBounds=ShieldGunBoundsImage

	Begin Object class=GUISectionBackground name=render
		Caption="ShieldGun Preview"
		WinWidth=0.500000
		WinHeight=0.500000
		WinLeft=0.450000
		WinTop=0.040000
		HeaderBase=Material'2K4Menus.NewControls.Display99'
	End Object
	sbg_render=render

	Begin Object class=GUISectionBackground name=border
		Caption="Member Options"
		WinWidth=0.400000
		WinHeight=0.850000
		WinLeft=0.025000
		WinTop=0.040000
		HeaderBase=Material'2K4Menus.NewControls.Display99'
	End Object
	sbg_bg=border

    /*Begin Object class=GUILabel name=VIPS
    	Caption="Member Options"
    	TextColor=(R=255,G=255,B=255,A=255)
		WinTop=0.050000
		WinLeft=0.050000
	End Object
	l_ShieldOptions=VIPS*/

	Begin Object class=moCheckBox name=UseFadeColor
		WinTop=0.125000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="Rainbow"
		Hint="If Checked: ShieldGun color will be fading"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_UseFadeColor=UseFadeColor

	Begin Object class=moCheckBox name=mat
		WinTop=0.200000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="Gold Armor"
		Hint="If Checked: Shield Armor texture will be changed"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_EnhancedMaterials=mat

	Begin Object class=moCheckBox name=AlphaOn
		WinTop=0.275000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="Translucent"
		Hint="If Checked: ShieldGun will be half invisible"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_Translucent=AlphaOn

	Begin Object class=moCheckBox name=NiceSkin
		WinTop=0.350000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="Rainbow Skin"
		Hint="If Checked: Player Skin will be fading along with the ShieldGun"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_PlayerSkinFade=NiceSkin

	Begin Object class=moCheckBox name=PinkRings
		WinTop=0.4250000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="Pink Rings"
		Hint="If Checked: You will have purple rings around you"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_PinkRings=PinkRings

	/*Begin Object class=moCheckBox name=UseRandBlink
		WinTop=0.200000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="Random Color"
		Hint="If Checked: ShieldGun color will blink to random colors"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_UseRandBlink=UseRandBlink

	Begin Object class=moCheckBox name=AlphaBlink
		WinTop=0.275000
		WinLeft=0.050000
		WinWidth=0.312500
		WinHeight=0.078125
		Caption="AlphaBlink"
		Hint="If Checked: ShieldGun alpha color will blink to random values"
		OnChange=InternalOnChange
		bAutoSizeCaption=True
	End Object
	cb_UseAlphaBlink=AlphaBlink*/

	Begin Object class=GUIButton name=ResetButton
		Caption="Reset"
		WinTop=0.900000
		WinLeft=0.050000
		WinWidth=0.130000
		WinHeight=0.050000
		OnClick=InternalOnClick
	End Object
	b_Reset=ResetButton

	Begin Object class=GUIButton name=SaveButton
		Caption="Save"
		WinTop=0.900000
		WinLeft=0.825000
		WinWidth=0.130000
		WinHeight=0.050000
		OnClick=InternalOnClick
	End Object
	b_Save=SaveButton

	// Text for colors...
    Begin Object class=GUILabel name=ColorTitle
    	Caption="ShieldGun Color"
    	TextColor=(R=255,G=255,B=255,A=255)
		WinTop=0.585000
		WinLeft=0.600000
	End Object
	l_ShieldColor=ColorTitle

	Begin Object class=GUISlider name=Red
		Value=50
		WinTop=0.645000
		WinLeft=0.600000
		MinValue=0
		MaxValue=255
		WinWidth=0.350000
		bIntSlider=True
		bShowCaption=True
		OnClick=InternalOnClick
	End Object
	s_Red=Red

	Begin Object class=GUISlider name=Green
		Value=255
		WinTop=0.705000
		WinLeft=0.600000
		MinValue=0
		MaxValue=255
		WinWidth=0.350000
		bIntSlider=True
		bShowCaption=True
		OnClick=InternalOnClick
	End Object
	s_Green=Green

	Begin Object class=GUISlider name=Blue
		Value=50
		WinTop=0.765000
		WinLeft=0.600000
		MinValue=0
		MaxValue=255
		WinWidth=0.350000
		bIntSlider=True
		bShowCaption=True
		bShowValueTooltip=True
		OnClick=InternalOnClick
	End Object
	s_Blue=Blue

	Begin Object class=GUISlider name=Alpha
		Value=255
		WinTop=0.825000
		WinLeft=0.600000
		MinValue=0
		MaxValue=255
		WinWidth=0.350000
		bIntSlider=True
		bShowCaption=True
		bShowValueTooltip=True
		OnClick=InternalOnClick
	End Object
	s_Alpha=Alpha
}
