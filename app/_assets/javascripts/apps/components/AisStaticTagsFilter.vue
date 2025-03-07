<template>
    <ais-refinement-list class="flex flex-col gap-1" attribute="tags" :transformItems="getStaticValues" >
        <template
            v-slot="{
            items,
            refine,
            createURL,
            }"
        >
            <ul class="ais-RefinementList-list flex max-h-64" :class="dynamicClasses">
                <template v-for="(item, index) in items" :key="item.value">
                <li class="ais-RefinementList-item flex" :class="{ hidden: index >= 5 && !showMore }">
                    <a class="badge" :href="createURL(item.value)" :class="{ 'font-bold': item.isRefined }" @click.prevent="refine(item.value)" >
                        #{{ item.value }}
                    </a>
                </li>
                </template>
            </ul>
            <button class="text-xs text-brand" @click="showMore = !showMore">
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
        getStaticValues(items) {
            return this.tags.map(staticTag => {
                const item = items.find(item => item.label === staticTag);

                return item || {
                    label: staticTag,
                    value: staticTag,
                    count: 0,
                    isRefined: false,
                    highlighted: staticTag,
                };
            }).sort(this.sortTags)
        }
    }
};
</script>
