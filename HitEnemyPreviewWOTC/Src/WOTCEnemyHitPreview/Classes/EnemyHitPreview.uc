// EnemyHitPreview - Shows hit chance when previewing movement tiles
// Extends UITacticalHUD_EnemyPreview to display hit percentages on enemy icons
class EnemyHitPreview extends UITacticalHUD_EnemyPreview;

// Store the tile we're previewing movement to
var TTile PreviewTile;
var int PreviewSourceUnitID;

// Array of text labels for hit chance display
var array<UIText> HitChanceLabels;
var bool bLabelsInitialized;

// Cover bonus constants (same as X2AbilityToHitCalc_StandardAim)
const LOW_COVER_BONUS = 20;
const HIGH_COVER_BONUS = 40;

simulated function UITacticalHUD_Enemies InitEnemyTargets()
{
	super.InitEnemyTargets();
	return self;
}

simulated function OnInit()
{
	super.OnInit();

	`log("HitEnemyPreview: OnInit called");

	if (!bLabelsInitialized)
	{
		CreateHitChanceLabels();
		bLabelsInitialized = true;
		`log("HitEnemyPreview: Labels created, count=" $ HitChanceLabels.Length);
	}
}

// Create text labels for each possible enemy icon slot
simulated function CreateHitChanceLabels()
{
	local int i;
	local UIText HitLabel;
	local int MaxEnemies;

	MaxEnemies = 20;

	for (i = 0; i < MaxEnemies; i++)
	{
		HitLabel = Spawn(class'UIText', self);
		HitLabel.InitText(name("HitChanceLabel_" $ i));
		HitLabel.SetSize(50, 20);
		HitLabel.Hide();
		HitChanceLabels.AddItem(HitLabel);
	}
}

// Override to capture the move-to tile data
simulated function UpdatePreviewTargets(GameplayTileData MoveToTileData, const out array<StateObjectReference> ObjectsVisibleToPlayer, int HistoryIndex = -1)
{
	// Store the preview tile for hit chance calculation
	PreviewTile = MoveToTileData.EventTile;
	PreviewSourceUnitID = MoveToTileData.SourceObjectID;

	`log("HitEnemyPreview: UpdatePreviewTargets called, SourceID=" $ MoveToTileData.SourceObjectID $ " ObjectsVisible=" $ ObjectsVisibleToPlayer.Length);

	// Call parent to do all the normal work
	super.UpdatePreviewTargets(MoveToTileData, ObjectsVisibleToPlayer, HistoryIndex);
}

// Calculate hit chance from the preview tile location using visibility from remote location
simulated function int GetHitChanceFromPreviewTile(StateObjectReference TargetRef)
{
	local XComGameState_Unit ShooterState;
	local XComGameState_Unit TargetState;
	local XComGameState_Item WeaponState;
	local XComGameStateHistory History;
	local GameRulesCache_VisibilityInfo VisInfo;
	local int HitChance;
	local int ShooterAim;
	local int TargetDefense;
	local int CoverBonus;
	local int RangeModifier;
	local int TileDistance;
	local vector ShooterLoc, TargetLoc;
	local float Distance;
	local X2WeaponTemplate WeaponTemplate;

	History = `XCOMHISTORY;
	ShooterState = XComGameState_Unit(History.GetGameStateForObjectID(PreviewSourceUnitID));
	TargetState = XComGameState_Unit(History.GetGameStateForObjectID(TargetRef.ObjectID));

	if (ShooterState == none || TargetState == none)
		return -1;

	// Get visibility info from the preview tile location
	if (!`TACTICALRULES.VisibilityMgr.GetVisibilityInfoFromRemoteLocation(PreviewSourceUnitID, PreviewTile, TargetRef.ObjectID, VisInfo))
		return -1;

	// Get shooter's primary weapon
	WeaponState = ShooterState.GetItemInSlot(eInvSlot_PrimaryWeapon);
	if (WeaponState == none)
		return -1;

	WeaponTemplate = X2WeaponTemplate(WeaponState.GetMyTemplate());

	// Base aim from shooter
	ShooterAim = ShooterState.GetCurrentStat(eStat_Offense);

	// Target defense
	TargetDefense = TargetState.GetCurrentStat(eStat_Defense);

	// Cover bonus based on visibility info from remote location
	CoverBonus = 0;
	if (TargetState.CanTakeCover())
	{
		switch (VisInfo.TargetCover)
		{
			case CT_MidLevel:  // Low cover
				CoverBonus = LOW_COVER_BONUS;
				break;
			case CT_Standing:  // High cover
				CoverBonus = HIGH_COVER_BONUS;
				break;
			case CT_None:      // Flanked or no cover
				CoverBonus = 0;
				break;
		}
	}

	// Calculate distance for range modifier
	ShooterLoc = `XWORLD.GetPositionFromTileCoordinates(PreviewTile);
	TargetLoc = `XWORLD.GetPositionFromTileCoordinates(TargetState.TileLocation);
	Distance = VSize(ShooterLoc - TargetLoc);
	TileDistance = int(Distance / class'XComWorldData'.const.WORLD_StepSize);

	// Get weapon range modifier from weapon template's range table
	if (WeaponTemplate != none && WeaponTemplate.RangeAccuracy.Length > 0)
	{
		if (TileDistance < WeaponTemplate.RangeAccuracy.Length)
			RangeModifier = WeaponTemplate.RangeAccuracy[TileDistance];
		else
			RangeModifier = WeaponTemplate.RangeAccuracy[WeaponTemplate.RangeAccuracy.Length - 1];
	}

	// Calculate final hit chance
	// Hit = Aim - Defense - Cover + WeaponAim + RangeModifier
	HitChance = ShooterAim - TargetDefense - CoverBonus + WeaponState.GetItemAimModifier() + RangeModifier;

	// Flanking bonus (target has no cover from this position)
	if (ShooterState.CanFlank() && TargetState.CanTakeCover() && VisInfo.TargetCover == CT_None)
	{
		HitChance += int(ShooterState.GetCurrentStat(eStat_FlankingAimBonus));
	}

	// Clamp to 0-100
	HitChance = Clamp(HitChance, 0, 100);

	return HitChance;
}

// Update the position of hit chance labels based on icon positions
simulated function UpdateHitChanceLabelPositions()
{
	local int i;
	local int IconSpacing;
	local int StartX;
	local int LabelY;

	IconSpacing = 36;
	StartX = 0;
	LabelY = 0;

	for (i = 0; i < HitChanceLabels.Length; i++)
	{
		if (i < m_arrTargets.Length)
		{
			HitChanceLabels[i].SetPosition(StartX + (i * IconSpacing), LabelY);
		}
	}
}

// Override UpdateVisuals to add hit chance display on enemy icons
public function UpdateVisuals(int HistoryIndex)
{
	local XGUnit kActiveUnit;
	local XComGameState_BaseObject TargetedObject;
	local XComGameState_Unit EnemyUnit;
	local X2VisualizerInterface Visualizer;
	local XComGameStateHistory History;
	local int i;
	local int HitChance;
	local string HitChanceText;
	local string ColorHex;

	// DATA
	History = `XCOMHISTORY;
	kActiveUnit = XComTacticalController(PC).GetActiveUnit();
	if (kActiveUnit == none)
		return;

	// VISUALS
	SetVisibleEnemies(iNumVisibleEnemies);

	// Hide all labels first
	for (i = 0; i < HitChanceLabels.Length; i++)
	{
		HitChanceLabels[i].Hide();
	}

	// Update label positions
	UpdateHitChanceLabelPositions();

	for (i = 0; i < m_arrTargets.Length; i++)
	{
		TargetedObject = History.GetGameStateForObjectID(m_arrTargets[i].ObjectID, , HistoryIndex);
		Visualizer = X2VisualizerInterface(TargetedObject.GetVisualizer());
		EnemyUnit = XComGameState_Unit(TargetedObject);

		SetIcon(i, Visualizer.GetMyHUDIcon());

		if (m_arrCurrentlyAffectable.Find('ObjectID', TargetedObject.ObjectID) > -1)
		{
			SetBGColor(i, Visualizer.GetMyHUDIconColor());
			SetDisabled(i, false);
		}
		else
		{
			SetBGColor(i, eUIState_Disabled);
			SetDisabled(i, true);
		}

		if (m_arrSSEnemies.Find('ObjectID', TargetedObject.ObjectID) > -1)
			SetSquadSight(i, true);
		else
			SetSquadSight(i, false);

		if (EnemyUnit != none && FlankedTargets.Find('ObjectID', EnemyUnit.ObjectID) != INDEX_NONE)
			SetFlanked(i, true);
		else
			SetFlanked(i, false);

		// Calculate and display hit chance from preview tile using UIText labels
		if (EnemyUnit != none && i < HitChanceLabels.Length)
		{
			HitChance = GetHitChanceFromPreviewTile(m_arrTargets[i]);
			`log("HitEnemyPreview: Target " $ i $ " HitChance=" $ HitChance);

			if (HitChance >= 0)
			{
				ColorHex = class'UIUtilities_Colors'.static.GetHexColorFromState(Visualizer.GetMyHUDIconColor());
				ColorHex = Right(ColorHex, Len(ColorHex) - 2);  // Remove "0x" prefix
				HitChanceText = "<font size='18' color='#" $ ColorHex $ "'><b>" $ string(HitChance) $ "%</b></font>";
				`log("HitEnemyPreview: HitChanceText=" $ HitChanceText);
				HitChanceLabels[i].SetHTMLText(HitChanceText);
				HitChanceLabels[i].Show();
			}
		}
	}

	RefreshShine();
	Movie.Pres.m_kTooltipMgr.ForceUpdateByPartialPath(string(MCPath));
}

// Get tile under mouse cursor
simulated function bool GetCursorTile(out TTile OutTile)
{
	local XComWorldData WorldData;
	local vector CursorLocation;
	local XComTacticalController TacticalController;

	WorldData = `XWORLD;
	TacticalController = XComTacticalController(PC);

	if (TacticalController != none)
	{
		CursorLocation = TacticalController.GetCursorPosition();
		OutTile = WorldData.GetTileCoordinatesFromPosition(CursorLocation);
		return true;
	}
	return false;
}

// Calculate visible enemies from a specific tile location
simulated function CalculateVisibleEnemiesFromTile(TTile FromTile, int SourceUnitID)
{
	local XComGameStateHistory History;
	local StateObjectReference UnitRef;
	local XComGameState_Unit EnemyUnit;
	local GameRulesCache_VisibilityInfo VisInfo;

	History = `XCOMHISTORY;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;

	m_arrTargets.Length = 0;
	m_arrCurrentlyAffectable.Length = 0;
	FlankedTargets.Length = 0;

	// Get all enemy units
	foreach History.IterateByClassType(class'XComGameState_Unit', EnemyUnit)
	{
		if (EnemyUnit.IsAlive() && EnemyUnit.IsEnemyUnit(XComGameState_Unit(History.GetGameStateForObjectID(SourceUnitID))))
		{
			UnitRef.ObjectID = EnemyUnit.ObjectID;

			// Check visibility from the specified tile
			if (VisibilityMgr.GetVisibilityInfoFromRemoteLocation(SourceUnitID, FromTile, EnemyUnit.ObjectID, VisInfo))
			{
				if (VisInfo.bClearLOS && VisInfo.bVisibleGameplay)
				{
					m_arrTargets.AddItem(UnitRef);
					m_arrCurrentlyAffectable.AddItem(UnitRef);

					// Check if flanked
					if (EnemyUnit.CanTakeCover() && VisInfo.TargetCover == CT_None)
					{
						FlankedTargets.AddItem(UnitRef);
					}

					`log("HitEnemyPreview: Found visible enemy " $ EnemyUnit.ObjectID $ " from tile");
				}
			}
		}
	}

	iNumVisibleEnemies = m_arrTargets.Length;
	`log("HitEnemyPreview: CalculateVisibleEnemiesFromTile found " $ iNumVisibleEnemies $ " enemies");
}

// Override Show to always show when Alt is pressed (don't hide based on enemy count)
simulated function Show()
{
	local XGUnit kActiveUnit;
	local XComGameState_Unit UnitState;
	local TTile CursorTile;
	local bool bGotCursorTile;

	// Check if Alt is pressed or always-on setting
	if (XComInputBase(XComPlayerController(Movie.Pres.Owner).PlayerInput).IsTracking(class'UIUtilities_Input'.const.FXS_KEY_LEFT_ALT) || `XPROFILESETTINGS.data.m_bTargetPreviewAlwaysOn)
	{
		// Call grandparent Show() directly to avoid parent's Hide() logic
		super(UIPanel).Show();

		kActiveUnit = XComTacticalController(PC).GetActiveUnit();
		if (kActiveUnit != none)
		{
			UnitState = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(kActiveUnit.ObjectID));
			if (UnitState != none)
			{
				PreviewSourceUnitID = kActiveUnit.ObjectID;

				// Try to get cursor tile, fallback to current unit position
				bGotCursorTile = GetCursorTile(CursorTile);
				if (bGotCursorTile)
				{
					PreviewTile = CursorTile;
					`log("HitEnemyPreview: Show() - using cursor tile");
				}
				else
				{
					PreviewTile = UnitState.TileLocation;
					`log("HitEnemyPreview: Show() - using current position");
				}

				// Calculate visible enemies from the preview tile
				CalculateVisibleEnemiesFromTile(PreviewTile, PreviewSourceUnitID);

				// Update visuals
				UpdateVisuals(-1);
			}
		}
	}
	else
	{
		Hide();
	}
}

// Hide labels when panel is hidden
simulated function Hide()
{
	local int i;

	super.Hide();

	for (i = 0; i < HitChanceLabels.Length; i++)
	{
		HitChanceLabels[i].Hide();
	}
}

defaultproperties
{
	bLabelsInitialized = false
}
