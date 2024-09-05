class CollapsibleSection {
    constructor(elem) {
        this.elem = elem;
        this.link = elem.querySelector('a');

        this.addEventListeners();
    }

    addEventListeners() {
        this.link.addEventListener('click', this.toggleSection.bind(this));
    }

    toggleSection(event) {
        event.preventDefault();
        this.elem.querySelector('span.fa').classList.toggle('rotate-180');
        this.elem.querySelector('.content').classList.toggle('hidden');
    }
}

document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll('.how-to .collapsible').forEach((elem) => {
        new CollapsibleSection(elem);
    });
});