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
            <i id="theme-icon" class="fas fa-moon fa-2x" onclick="toggleTheme()"></i>
        </div>
        <div class="logo">
		    <a href="https://makako.xyz/maps">
            <img id="theme-logo" src="images/mapascustomwhite.png" alt="Logo Mapas Custom">
        </div>
        <nav class="navbar">
            <ul>
                <li><a href="https://makako.xyz">Inicio</a></li>
                <li><a href="https://sb.makako.xyz">Sourcebans</a></li>
                <li><a href="https://steamcommunity.com/groups/servidoresmakako">Grupo Steam</a></li>
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
            ["title" => "Haunted Forest", "link" => "https://makako.xyz/resources/hauntedforest_v3.vpk", "image" => "images/hauntedforest.png"],
            ["title" => "Detour Ahead", "link" => "https://makako.xyz/resources/detourahead.vpk", "image" => "images/detourahead.png"],
            ["title" => "Dead Before Dawn", "link" => "https://makako.xyz/resources/deadbeforedawn2_dc.vpk", "image" => "images/deadbeforedawn2_dc.png"],
            ["title" => "Diescraper Redux v3.62", "link" => "https://makako.xyz/resources/l4d2_diescraper_362.vpk", "image" => "images/l4d2_diescraper_362.png"],
            ["title" => "Hard Rain Downpour", "link" => "https://makako.xyz/resources/downpour.vpk", "image" => "images/downpour.png"],
            ["title" => "Suicide Blitz 2", "link" => "https://makako.xyz/resources/suicideblitz2.vpk", "image" => "images/suicideblitz2.png"],
            ["title" => "Urban Flight", "link" => "https://makako.xyz/resources/urbanflight.vpk", "image" => "images/urbanflight.png"],
            ["title" => "No Mercy Rehab", "link" => "https://makako.xyz/resources/nomercyrehab.vpk", "image" => "images/nomercyrehab.png"],
            ["title" => "Dark Carnival Remix", "link" => "https://makako.xyz/resources/dark%20carnival%20remix.vpk", "image" => "images/dark carnival remix.png"],
            ["title" => "Back to School", "link" => "https://makako.xyz/resources/bts_l4d2.vpk", "image" => "images/bts_l4d2.png"],
            ["title" => "Blood Tracks", "link" => "https://makako.xyz/resources/bloodtracks.vpk", "image" => "images/bloodtracks.png"],
            ["title" => "Left Behind", "link" => "https://makako.xyz/resources/behind.vpk", "image" => "images/leftbehind.png"],
            ["title" => "Warcelona", "link" => "https://makako.xyz/resources/warcelona.vpk", "image" => "images/warcelona.png"],
            ["title" => "Heaven Can Wait II", "link" => "https://makako.xyz/resources/heavencanwaitl4d2.vpk", "image" => "images/heavencanwaitl4d2.png"],
            ["title" => "Crash Course: ReRouted", "link" => "https://makako.xyz/resources/ccrerouted.vpk", "image" => "images/ccrerouted.png"],
            ["title" => "City 17 v3.2", "link" => "https://makako.xyz/resources/city17l4d2.vpk", "image" => "images/city17l4d2.png"],
            ["title" => "City Of The Dead", "link" => "https://makako.xyz/resources/city%20of%20the%20dead%20map.vpk", "image" => "images/city of the dead map.png"],
            ["title" => "Day Break", "link" => "https://makako.xyz/resources/daybreak_v3.vpk", "image" => "images/daybreak_v3.png"],
            ["title" => "Deadbeat Escape", "link" => "https://makako.xyz/resources/deadbeatescape.vpk", "image" => "images/deadbeatescape.png"],
            ["title" => "Death Sentence", "link" => "https://makako.xyz/resources/deathsentence.vpk", "image" => "images/deathsentence.png"],
            ["title" => "Energy Crisis", "link" => "https://makako.xyz/resources/energycrisis.vpk", "image" => "images/energycrisis.png"],
            ["title" => "Highway To Hell", "link" => "https://makako.xyz/resources/highwaytohell.vpk", "image" => "images/highwaytohell.png"],
            ["title" => "I Hate Mountains 2 v1.5", "link" => "https://makako.xyz/resources/ihatemountains2.vpk", "image" => "images/ihatemountains2.png"],
            ["title" => "Arena of the Dead 2 v5", "link" => "https://makako.xyz/resources/jsarena2.vpk", "image" => "images/arenaofthedead.png"],
            ["title" => "The Bloody Moors", "link" => "https://makako.xyz/resources/l4d2_thebloodymoors.vpk", "image" => "images/l4d2_thebloodymoors.png"],
            ["title" => "Parish: OverGrowth", "link" => "https://makako.xyz/resources/parish%20overgrowth.vpk", "image" => "images/parish-overgrowth.png"],
            ["title" => "Tour of Terror", "link" => "https://makako.xyz/resources/tourofterror.vpk", "image" => "images/tourofterror.png"],
            ["title" => "The Undead Zone", "link" => "https://makako.xyz/resources/undead_zone.vpk", "image" => "images/undead_zone.png"],
            ["title" => "Big Wat", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=210140990", "image" => "images/bigwat.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Don't Fall", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2208092043", "image" => "images/dontfall.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Unforgivable Night Redux", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=2866007403", "image" => "images/unforgivable-night.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Drop Dead Gorges v2.1", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=3307446423", "image" => "images/dropdeadgorges.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Open Road", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=3308734721", "image" => "images/openroad.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Dark Blood 2", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=3308737726", "image" => "images/darkblood2.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Fatal Freight", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=3306147567", "image" => "images/fatalfreight.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"],
            ["title" => "Carried Off", "link" => "https://steamcommunity.com/sharedfiles/filedetails/?id=3306083995", "image" => "images/carriedoff.png", "buttonClass" => "btn-subscribe", "buttonText" => "Suscribirse"]
        ];

        usort($maps, function($a, $b) {
            return strcmp($a['title'], $b['title']);
        });

        foreach ($maps as $index => $map) {
            $buttonClass = isset($map['buttonClass']) ? $map['buttonClass'] : 'btn-download';
            $buttonText = isset($map['buttonText']) ? $map['buttonText'] : 'Descargar';
            echo "
            <div class='item'>
                <img src='{$map['image']}' alt='{$map['title']}'>
                <span class='item-title'>{$map['title']}</span>
                <button class='$buttonClass' onclick=\"window.open('{$map['link']}', '_blank')\">$buttonText</button>
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
