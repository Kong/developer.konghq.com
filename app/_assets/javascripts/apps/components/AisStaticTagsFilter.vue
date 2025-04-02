<template>
    <ais-refinement-list class="flex flex-col" attribute="tags" :transformItems="getStaticValues" >
        <template
            v-slot="{
            items,
            refine,
            createURL,
            }"
        >
            <ul class="ais-RefinementList-list flex flex-row flex-wrap max-h-64 gap-y-3" :class="dynamicClasses">
                <template v-for="(item, index) in items" :key="item.value">
                <li class="ais-RefinementList-item flex" :class="{ hidden: index >= 10 && !showMore }">
                    <a class="badge h-fit" :href="createURL(item.value)" :class="{ 'font-bold bg-brand': item.isRefined }" @click.prevent="refine(item.value)" >
                        #{{ item.label }}
                    </a>
                </li>
                </template>
            </ul>
            <button class="text-xs text-terciary flex" @click="showMore = !showMore">
                {{ !showMore ? 'Show more' : 'Show less'}}
            </button>
        </template>
    </ais-refinement-list>
</template>

<script>
import { AisRefinementList } from 'vue-instantsearch/vue3/es';

export default {
    data() {
        return {
            tags: window.searchFilters.tags,
            showMore: false
        };
    },
    components: {
        AisRefinementList
    },
    computed: {
        dynamicClasses() {
            if (this.showMore) {
                return ['overflow-auto', 'h-full'];
            } else {
                return ['overflow-hidden', 'h-32'];
            }
        }
    },
    methods: {
        sortTags(a, b) {
            if (a.isRefined !== b.isRefined) {
                return a.isRefined ? -1 : 1;
            }
            return a.label > b.label ? 1 : -1;
        },
        getStaticValues(items, { results }) {
            return this.tags.map(staticTag => {
                const item = items.find(item => item.value === staticTag.value);
                let selected = false;

                if (item) {
                    item.highlighted = staticTag.label;
                }

                const facet = results._state.disjunctiveFacetsRefinements.tags;

                if (facet) {
                    selected = facet.includes(staticTag.value)
                }
                return item || {
                    label: staticTag.label,
                    value: staticTag.value,
                    count: 0,
                    isRefined: selected || staticTag.isRefined,
                    highlighted: staticTag.value,
                };
            }).sort(this.sortTags)
        }
    }
};
</script>
