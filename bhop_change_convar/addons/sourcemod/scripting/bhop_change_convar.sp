#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "[L4D2] Cambiar cvar simple_antibhop_enable en Ready-Up",
    author = "Forgetest & Beckham CE",
    description = "Cambia el cvar simple_antibhop_enable de acuerdo al estado de Ready-Up.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("[Simple Anti-Bhop Toggle] Plugin loaded.");
}

public void OnReadyUpInitiate()
{
    SetAntiBhop(0);
}

public void OnRoundIsLive()
{
    SetAntiBhop(1);
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
