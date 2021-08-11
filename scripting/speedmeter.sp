#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

Handle g_Sync;
Handle g_Timer;

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
	version = "1.1",
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
	
	g_Sync = CreateHudSynchronizer();
	g_Timer = CreateTimer(0.10, Timer_Speedmeter, _, TIMER_REPEAT);
}

public void OnMapEnd()
{
	delete g_Sync;
	delete g_Timer;
}

public Action Timer_Speedmeter(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		
		static char text[64];
		static float vec[3];
		static int target, speed, buttons;
		
		if (IsPlayerAlive(i))
		{
			buttons = GetClientButtons(i);
			GetEntPropVector(i, Prop_Data, "m_vecVelocity", vec);
		}
		else if (IsClientObserver(i))
		{
			target = GetEntPropEnt(i, Prop_Data, "m_hObserverTarget");
			if (target == -1)
			{
				continue;
			}
			buttons = GetClientButtons(target);
			GetEntPropVector(target, Prop_Data, "m_vecVelocity", vec);
		}
		
		switch (bMode)
		{
			case 0: speed = RoundFloat(SquareRoot(vec[0] * vec[0] + vec[1] * vec[1]));
			case 1: speed = RoundFloat(SquareRoot(vec[0] * vec[0] + vec[1] * vec[1] + vec[2] * vec[2]));
		}
		
		switch (bKeys)
		{
			case 0: FormatEx(text, sizeof(text), "Speed: %i units/s", speed);
			case 1:
			{
				FormatEx(text, sizeof(text), "Speed: %i units/s\n\n%s   %s   %s\n%s   %s   %s", speed,
												(buttons & IN_DUCK == IN_DUCK) ? "C":"_",
												(buttons & IN_FORWARD == IN_FORWARD) ? "W":"_",
												(buttons & IN_JUMP == IN_JUMP) ? "J":"_",
												(buttons & IN_MOVELEFT == IN_MOVELEFT) ? "A":"_", 
												(buttons & IN_BACK == IN_BACK) ? "S":"_", 
												(buttons & IN_MOVERIGHT == IN_MOVERIGHT) ? "D":"_");
			}
		}
										
		SetHudTextParams(fPosX, fPosY, 0.15, iRed, iGreen, iBlue, iAlpha, 0, 0.0, 0.0, 0.0);
		ShowSyncHudText(i, g_Sync, text);
	}
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