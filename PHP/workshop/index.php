<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mapas Custom</title>
    <link rel="icon" href="images/mk.ico" type="image/x-icon">
    <link rel="stylesheet" href="style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.4/css/all.min.css">
    <link href="https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&family=Open+Sans:wght@400;600&family=Lobster&display=swap" rel="stylesheet">
</head>
<body class="dark-mode">
    <header class="header">
        <div class="theme-toggle">
            <i id="theme-icon" class="fas fa-sun fa-2x" onclick="toggleTheme()" style="color: yellow;"></i>
        </div>
        <div class="logo">
            <img id="theme-logo" src="images/mapascustomwhite.png" alt="Logo Mapas Custom">
        </div>
        <nav class="navbar">
            <ul>
                <li><a href="https://makako.xyz">Inicio</a></li>
                <li><a href="https://sb.makako.xyz">SourceBans</a></li>
                <li><a href="https://makako.xyz/mapsvpk">Mapas VPK</a></li>
            </ul>
        </nav>
        <div class="search-container">
            <div class="search-box">
                <input type="text" id="search-input" placeholder="Search maps..." onkeyup="searchMaps()">
                <i id="clear-search" class="fas fa-times" onclick="clearSearch()"></i>
            </div>
        </div>
    </header>
    <div class="container" id="map-container">
        <?php
        $maps = [
            ["title" => "Carried Off", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=381431565", "image" => "images/carriedoff.png"],
            ["title" => "Haunted Forest", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2325347179", "image" => "images/hauntedforest.png"],
            ["title" => "Detour Ahead", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=121275675", "image" => "images/detourahead.png"],
            ["title" => "Diescraper Redux v3.62", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=121116980", "image" => "images/l4d2_diescraper_362.png"],
            ["title" => "Hard Rain Downpour", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=306243689", "image" => "images/downpour.png"],
            ["title" => "Suicide Blitz 2", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=1910161083", "image" => "images/suicideblitz2.png"],
            ["title" => "Open Road", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=123734884", "image" => "images/openroad.png"],
            ["title" => "Unforgivable Night Redux", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2866007403", "image" => "images/unforgivable-night.png"],
            ["title" => "Urban Flight", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=121086524", "image" => "images/urbanflight.png"],
            ["title" => "No Mercy Rehab", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2892224388", "image" => "images/nomercyrehab.png"],
            ["title" => "Dark Carnival Remix", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=1575673903", "image" => "images/dark carnival remix.png"],
            ["title" => "Dark Blood 2", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=121175467", "image" => "images/darkblood2_v3.png"],
            ["title" => "Warcelona", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=1910147798", "image" => "images/warcelona.png"],
            ["title" => "Heaven Can Wait II", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=629476830", "image" => "images/heavencanwaitl4d2.png"],
            ["title" => "City 17 v3.2", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=141632373", "image" => "images/city17l4d2.png"],
            ["title" => "City of the Dead", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=673687239", "image" => "images/city of the dead map.png"],
            ["title" => "Day Break", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=180925247", "image" => "images/daybreak_v3.png"],
            ["title" => "Drop Dead Gorges v2.1", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2209749185", "image" => "images/dropdeadgorges.png"],
            ["title" => "Deadbeat Escape", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2249227977", "image" => "images/deadbeatescape.png"],
            ["title" => "I Hate Mountains 2 v1.5", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2249963776", "image" => "images/ihatemountains2.png"],
            ["title" => "Arena of the Dead 2 v5", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2812331044", "image" => "images/arenaofthedead.png"],
            ["title" => "Tour of Terror", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=1702647775", "image" => "images/tourofterror.png"],
            ["title" => "Big Wat", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=210140990", "image" => "images/bigwat.png"],
            ["title" => "Don't Fall", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2208092043", "image" => "images/dontfall.png"],
            ["title" => "The Undead Zone", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2896677838", "image" => "images/undead_zone.png"]
        ];

        usort($maps, function($a, $b) {
            return strcmp($a['title'], $b['title']);
        });

        foreach ($maps as $index => $map) {
            $buttonClass = 'btn-download';
            echo "
            <div class='item'>
                <img src='{$map['image']}' alt='{$map['title']}'>
                <span class='item-title'>{$map['title']}</span>
                <a href='{$map['link']}' target='_blank' class='$buttonClass'>Suscribirse</a>
            </div>
            ";
        }
        ?>
    </div>
    <div id="no-results-message" style="display:none; text-align: center; margin-top: 20px;">
        <img src="images/nofind.gif" alt="No results found" style="max-width: 300px; width: 100%; height: auto;">
        <p>No se encontraron mapas. Pruebe con un término de búsqueda diferente.</p>
    </div>
    <script src="script.js"></script>
</body>
</html>
