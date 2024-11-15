public Plugin myinfo =
{
	name = "Automatic FTank",
	author = "BeckanCE",
	description = "A plugin that runs a command and changes a cvar according to the map",
	version = "1.0",
	url = ""
};

// Función que se ejecuta cuando el mapa comienza
public OnMapStart()
{
    // Obtener el nombre del mapa actual
    char mapName[64];  // Arreglo de caracteres, no de enteros
    GetCurrentMap(mapName, sizeof(mapName));
    
    // Comprobamos si el mapa es bwm1_climb
    if (StrEqual(mapName, "bwm1_climb"))
    {
        // Creamos un temporizador de 20 segundos para ejecutar el comando
        CreateTimer(22.0, Timer_ExecuteCommand, _, TIMER_FLAG_NO_MAPCHANGE);
        
        // Creamos otro temporizador de 23 segundos para cambiar el cvar
        CreateTimer(25.0, Timer_ChangeCvar, _, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// Temporizador que ejecuta el comando después de 20 segundos
public Action:Timer_ExecuteCommand(Handle:timer, any:unused)
{
    // Ejecutar el comando sm_ftank 83
    ServerCommand("sm_ftank 83");
    
    // Devolver Plugin_Handled para indicar que el temporizador ha terminado correctamente
    return Plugin_Handled;
}

// Temporizador que cambia el cvar después de 23 segundos
public Action:Timer_ChangeCvar(Handle:timer, any:unused)
{
    // Cambiar el cvar l4d_boss_vote a 0
    SetConVarInt(FindConVar("l4d_boss_vote"), 0);
    
    // Devolver Plugin_Handled para indicar que el temporizador ha terminado correctamente
    return Plugin_Handled;
}
