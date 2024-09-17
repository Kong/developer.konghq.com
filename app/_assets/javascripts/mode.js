document.addEventListener("DOMContentLoaded", function () {
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