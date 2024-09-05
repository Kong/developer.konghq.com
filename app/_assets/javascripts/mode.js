
document.addEventListener("DOMContentLoaded", function () {
    // On page load or when changing themes, best to add inline in `head` to avoid FOUC
    if (localStorage.mode === 'dark' || (!('mode' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        document.documentElement.classList.add('dark');
    } else {
        document.documentElement.classList.remove('dark');
    }
    const modeSwitch = document.getElementById('mode-switch');

    modeSwitch.addEventListener('click', () => {
        document.documentElement.classList.toggle('dark');
        if (document.documentElement.classList.contains('dark')) {
            localStorage.setItem('mode', 'dark');
        } else {
            localStorage.setItem('mode', '');
        }
    });
});