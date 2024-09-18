class Accordion {
    constructor(elem) {
        this.accordion = elem;
        this.items = Array.from(this.accordion.querySelectorAll(':scope > .accordion-item'));

        // Specify if there's a default opened item.
        this.defaultItem = this.accordion.dataset.default;

        // Specify if the accordion can have multiple items open at a time,
        // by default they don't.
        this.multipleItems = this.accordion.dataset.multiple;

        this.init();
        this.addEventListeners();
    }

    init() {
        // if defaultItem initialize everything closed except for that one item.
        this.items.forEach((item, index) => {
            if (this.defaultItem && parseInt(this.defaultItem) !== index) {
                this.closeItem(index);
            } else {
                this.openItem(index);
            }
        })
    }

    toggleItem (index) {
        const item = this.items.at(index);
        if (item.getAttribute('aria-expanded') === 'true') {
            this.closeItem(index);
        } else {
            this.openItem(index);
        }
    }

    closeItem (index) {
        const item = this.items.at(index);
        item.setAttribute('aria-expanded', 'false');
        item.querySelector('span.fa').classList.remove('rotate-180');

        const panel = item.querySelector('.accordion-panel');
        panel.classList.add('hidden');
        panel.hidden = true;
        panel.setAttribute('aria-hidden', 'true');
    }

    openItem (index) {
        const item = this.items.at(index);
        item.setAttribute('aria-expanded', 'true');
        item.querySelector('span.fa').classList.add('rotate-180');

        const panel = item.querySelector('.accordion-panel');
        panel.classList.remove('hidden');
        panel.hidden = false;
        panel.setAttribute('aria-hidden', 'false');
    }

    addEventListeners() {
        this.accordion.querySelectorAll(':scope > .accordion-item > .accordion-trigger').forEach((trigger) => {
            trigger.addEventListener('click', this.onItemClick.bind(this));
        })
    }

    onItemClick(event) {
        event.preventDefault();
        event.stopPropagation();

        const accordionItem = event.target.closest('.accordion-item');
        const itemIndex = this.items.indexOf(accordionItem);
        this.toggleItem(itemIndex);

        if (!this.multipleItems) {
            this.items.forEach((item, index) => {
                if (index !== itemIndex) {
                    this.closeItem(index);
                }
            })
        }
    }
}

document.addEventListener("DOMContentLoaded", function () {
    document.querySelectorAll('.accordion').forEach((accordion) => {
        new Accordion(accordion);
    })
});