document.addEventListener('DOMContentLoaded', (event) => {
    // Set the theme on initial load
    const theme = localStorage.getItem('theme');
    const icon = document.getElementById('theme-icon');
    const logo = document.getElementById('theme-logo');
    
    if (theme) {
        document.body.classList.add(theme);
    } else {
        document.body.classList.add('dark-mode');
        localStorage.setItem('theme', 'dark-mode');
    }

    // Update icon and logo based on the current theme
    if (document.body.classList.contains('dark-mode')) {
        icon.classList.remove('fa-moon');
        icon.classList.add('fa-sun');
        icon.style.color = 'yellow';
        logo.src = 'images/mapascustomwhite.png';
    } else {
        icon.classList.remove('fa-sun');
        icon.classList.add('fa-moon');
        icon.style.color = 'black';
        logo.src = 'images/mapascustomblack.png';
    }

    const searchInput = document.getElementById('search-input');
    const clearSearchIcon = document.getElementById('clear-search');

    searchInput.addEventListener('input', () => {
        if (searchInput.value.length > 0) {
            clearSearchIcon.style.display = 'inline';
        } else {
            clearSearchIcon.style.display = 'none';
        }
    });
});

function toggleTheme() {
    const body = document.body;
    const icon = document.getElementById('theme-icon');
    const logo = document.getElementById('theme-logo');
    if (body.classList.contains('light-mode')) {
        body.classList.remove('light-mode');
        body.classList.add('dark-mode');
        icon.classList.remove('fa-moon');
        icon.classList.add('fa-sun');
        icon.style.color = 'yellow';
        logo.src = 'images/mapascustomwhite.png';
        localStorage.setItem('theme', 'dark-mode');
    } else {
        body.classList.remove('dark-mode');
        body.classList.add('light-mode');
        icon.classList.remove('fa-sun');
        icon.classList.add('fa-moon');
        icon.style.color = 'black';
        logo.src = 'images/mapascustomblack.png';
        localStorage.setItem('theme', 'light-mode');
    }
}

function clearSearch() {
    const searchInput = document.getElementById('search-input');
    searchInput.value = '';
    searchMaps();
    document.getElementById('clear-search').style.display = 'none';
}

function searchMaps() {
    const input = document.getElementById('search-input').value.toLowerCase();
    const items = document.getElementsByClassName('item');
    let hasResults = false;

    for (let i = 0; i < items.length; i++) {
        const title = items[i].getElementsByClassName('item-title')[0].innerText.toLowerCase();
        if (title.includes(input)) {
            items[i].style.display = '';
            hasResults = true;
        } else {
            items[i].style.display = 'none';
        }
    }

    const noResultsMessage = document.getElementById('no-results-message');
    if (hasResults) {
        noResultsMessage.style.display = 'none';
    } else {
        noResultsMessage.style.display = 'block';
    }
}
