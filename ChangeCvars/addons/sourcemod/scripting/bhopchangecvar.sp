#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "[L4D2] Simple Anti-Bhop Toggle",
    author = "Forgetest & Beckan",
    description = "Change cvar simple_antibhop_enable based on game state.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("[Simple Anti-Bhop Toggle] Plugin loaded.");
}

public void OnReadyUpInitiate()
{
    SetAntiBhop(0); // Desactivar anti-bhop en Ready-Up
}

public void OnRoundIsLive()
{
    SetAntiBhop(1); // Activar anti-bhop en Live
}

void SetAntiBhop(int value)
{
    ConVar cvar = FindConVar("simple_antibhop_enable");
    if (cvar != null)
    {
        cvar.SetInt(value);
        PrintToServer("[Simple Anti-Bhop Toggle] Set simple_antibhop_enable to %d", value);
    }
    else
    {
        PrintToServer("[Simple Anti-Bhop Toggle] Error: ConVar simple_antibhop_enable not found!");
    }
}
