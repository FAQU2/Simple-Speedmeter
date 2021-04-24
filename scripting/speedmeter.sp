#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar gc_Mode;
ConVar gc_Keys;
ConVar gc_PosX;
ConVar gc_PosY;
ConVar gc_Colors;
ConVar gc_Alpha;

bool bMode;
bool bKeys;
float fPosX;
float fPosY;
int iRed;
int iGreen;
int iBlue;
int iAlpha;

public Plugin myinfo = 
{
	name = "Simple Speedmeter",
	author = "FAQU",
	description = "HUD text showing player's speed and keys",
	version = "1.0",
	url = "https://github.com/FAQU2"
};

public void OnPluginStart()
{
	gc_Mode = CreateConVar("speedmeter_mode", "0", "Speedmeter mode (0 = horizontal velocity /  1 = horizontal + vertical velocity)", _, true, 0.0, true, 1.0);
	gc_Keys = CreateConVar("speedmeter_showkeys", "1", "Show pressed keys to player/spectator (0 = Disabled / 1 = Enabled)", _, true, 0.0, true, 1.0);
	gc_PosX = CreateConVar("speedmeter_posx", "-1.0", "Speedmeter position X (-1.0 is the center / Valid values go from 0.0 to 1.0)", _, true, -1.0, true, 1.0);
	gc_PosY = CreateConVar("speedmeter_posy", "0.7", "Speedmeter position Y (-1.0 is the center / Valid values go from 0.0 to 1.0)", _, true, -1.0, true, 1.0);
	gc_Colors = CreateConVar("speedmeter_colors", "255 255 255", "Speedmeter RGB color values");
	gc_Alpha = CreateConVar("speedmeter_alpha", "255", "Speedmeter alpha transparency value", _, true, 0.0, true, 255.0);
	
	HookAllConvars();
	
	AutoExecConfig(true, "Speedmeter");
}

public void OnConfigsExecuted()
{
	SaveConvarData();
	CreateTimer(0.10, Timer_Speedmeter, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Speedmeter(Handle timer)
{
	char hudtext[64];
	float vec[3];
	int speed;
	int buttons;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			buttons = GetClientButtons(i);
			
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", vec);
			
			PrepareHudText(hudtext, sizeof(hudtext), vec, speed, buttons);
			ShowHudText(i, -1, hudtext);
		}
		else if (IsClientInGame(i) && IsClientObserver(i) && !IsFakeClient(i))
		{
			int target = GetEntPropEnt(i, Prop_Data, "m_hObserverTarget");
			if (target != -1)
			{
				buttons = GetClientButtons(target);
			
				GetEntPropVector(target, Prop_Data, "m_vecVelocity", vec);
			
				PrepareHudText(hudtext, sizeof(hudtext), vec, speed, buttons);
				ShowHudText(i, -1, hudtext);
			}
		}
	}
}

///////////////////////////////////
// Functions
///////////////////////////////////

void PrepareHudText(char[] string, int maxlength, float vec[3], int speed, int buttons)
{
	if (!bMode)
	{
		speed = RoundFloat(SquareRoot(vec[0] * vec[0] + vec[1] * vec[1]));
	}
	else speed = RoundFloat(SquareRoot(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]));
			
			
	FormatEx(string, maxlength, "Speed: %i u/s", speed);
	
	if (bKeys)
	{
		if (buttons & IN_DUCK)
		{
			Format(string, maxlength, "%s\n\nC", string);
		}
		else Format(string, maxlength, "%s\n\n_", string);
			
		if (buttons & IN_FORWARD)
		{
			Format(string, maxlength, "%s  W", string);
		}
		else Format(string, maxlength, "%s  _", string);
			
		if (buttons & IN_JUMP)
		{
			Format(string, maxlength, "%s  J", string);
		}
		else Format(string, maxlength, "%s  _", string);
			
		if (buttons & IN_MOVELEFT)
		{
			Format(string, maxlength, "%s\nA", string);
		}
		else Format(string, maxlength, "%s\n_", string);
			
		if (buttons & IN_BACK)
		{
			Format(string, maxlength, "%s  S", string);
		}
		else Format(string, maxlength, "%s  _", string);
			
		if (buttons & IN_MOVERIGHT)
		{
			Format(string, maxlength, "%s  D", string);
		}
		else Format(string, maxlength, "%s  _", string);
	}
	
	SetHudTextParams(fPosX, fPosY, 0.12, iRed, iGreen, iBlue, iAlpha, 0, 0.0, 0.0, 0.0);
}

void SaveConvarData()
{
	bMode = gc_Mode.BoolValue;
	bKeys = gc_Keys.BoolValue;
	fPosX = gc_PosX.FloatValue;
	fPosY = gc_PosY.FloatValue;
	iAlpha = gc_Alpha.IntValue;
	
	char buffer[32];
	char colors[3][4];
	
	gc_Colors.GetString(buffer, sizeof(buffer));
	ExplodeString(buffer, " ", colors, sizeof(colors), sizeof(colors[]));
	
	iRed = StringToInt(colors[0]);
	iGreen = StringToInt(colors[1]);
	iBlue = StringToInt(colors[2]);
}

///////////////////////////////////
// Hooks
///////////////////////////////////

void HookAllConvars()
{
	gc_Mode.AddChangeHook(Hook_Mode);
	gc_Keys.AddChangeHook(Hook_Keys);
	gc_PosX.AddChangeHook(Hook_PosX);
	gc_PosY.AddChangeHook(Hook_PosY);
	gc_Colors.AddChangeHook(Hook_Colors);
	gc_Alpha.AddChangeHook(Hook_Alpha);
}

public void Hook_Mode(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bMode = gc_Mode.BoolValue;
}

public void Hook_Keys(ConVar convar, const char[] oldValue, const char[] newValue)
{
	bKeys = gc_Keys.BoolValue;
}

public void Hook_PosX(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fPosX = gc_PosX.FloatValue;
}

public void Hook_PosY(ConVar convar, const char[] oldValue, const char[] newValue)
{
	fPosY = gc_PosY.FloatValue;
}

public void Hook_Colors(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char colors[3][4];
	ExplodeString(newValue, " ", colors, sizeof(colors), sizeof(colors[]));
	
	iRed = StringToInt(colors[0]);
	iGreen = StringToInt(colors[1]);
	iBlue = StringToInt(colors[2]);
}

public void Hook_Alpha(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iAlpha = gc_Alpha.IntValue;
}