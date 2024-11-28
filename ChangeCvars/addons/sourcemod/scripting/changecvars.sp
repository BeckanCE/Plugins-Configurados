#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <readyup>

#define PLUGIN_VERSION "1.2"

public Plugin myinfo = 
{
    name = "[L4D2] Multi-CVar Toggle",
    author = "Forgetest & Beckan",
    description = "Ensures cvars are toggled properly during state transitions.",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    PrintToServer("[Multi-CVar Toggle] Plugin loaded.");
}

public void OnReadyUpInitiate()
{
    ToggleCVarState(0); // Ready-Up: desactivar/activar cvars
}

public void OnRoundIsLive()
{
    ToggleCVarState(1); // Live: activar/desactivar cvars
}

void ToggleCVarState(int state)
{
    // Manejar simple_antibhop_enable
    ConVar antibhop = FindConVar("simple_antibhop_enable");
    if (antibhop != null)
    {
        int currentValue = antibhop.IntValue; // Obtener valor actual
        if (currentValue != state) // Solo cambiar si es necesario
        {
            antibhop.SetInt(state);
            PrintToServer("[Multi-CVar Toggle] Changed simple_antibhop_enable from %d to %d", currentValue, state);
        }
        else
        {
            PrintToServer("[Multi-CVar Toggle] simple_antibhop_enable already set to %d", state);
        }
    }
    else
    {
        PrintToServer("[Multi-CVar Toggle] Error: ConVar simple_antibhop_enable not found!");
    }

    // Manejar l4d_music_mapstart_enable
    ConVar music = FindConVar("l4d_music_mapstart_enable");
    if (music != null)
    {
        int targetValue = (state == 0 ? 1 : 0); // Valor invertido
        int currentValue = music.IntValue; // Obtener valor actual
        if (currentValue != targetValue) // Solo cambiar si es necesario
        {
            music.SetInt(targetValue);
            PrintToServer("[Multi-CVar Toggle] Changed l4d_music_mapstart_enable from %d to %d", currentValue, targetValue);
        }
        else
        {
            PrintToServer("[Multi-CVar Toggle] l4d_music_mapstart_enable already set to %d", targetValue);
        }
    }
    else
    {
        PrintToServer("[Multi-CVar Toggle] Error: ConVar l4d_music_mapstart_enable not found!");
    }
}
