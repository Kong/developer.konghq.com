import { history } from "instantsearch.js/es/lib/routers";

function getParamValue(param) {
  return Array.isArray(param) ? param : [param].filter(Boolean);
}

export function routingConfig(indexName) {
  const sources = window.searchSources;
  return {
    router: history({
      cleanUrlOnDispose: false,
      createURL({ qsModule, routeState, location }) {
        const { origin, pathname } = location;

        const queryParameters = {};

        if (routeState.query) {
          queryParameters.query = encodeURIComponent(routeState.query);
        }
        if (routeState.page !== 1) {
          queryParameters.page = routeState.page;
        }
        if (routeState.products) {
          queryParameters.products =
            routeState.products.map(encodeURIComponent);
        }
        if (routeState.tools) {
          queryParameters.tools = routeState.tools.map(encodeURIComponent);
        }
        if (routeState.content) {
          queryParameters.content = encodeURIComponent(routeState.content);
        } else {
          queryParameters.content = "all";
        }
        if (routeState.works_on) {
          queryParameters.works_on =
            routeState.works_on.map(encodeURIComponent);
        }
        if (routeState.tags) {
          queryParameters.tags = routeState.tags.map(encodeURIComponent);
        }

        const queryString = qsModule.stringify(queryParameters, {
          addQueryPrefix: true,
          arrayFormat: "repeat",
        });

        return `${origin}${pathname}${queryString}`;
      },

      parseURL({ qsModule, location }) {
        const {
          query = "",
          page,
          products = [],
          tools = [],
          content = undefined,
          works_on = [],
          tags = [],
        } = qsModule.parse(location.search.slice(1));

        // `qs` does not return an array when there's a single value.
        const test = {
          query: decodeURIComponent(query),
          page,
          products: getParamValue(products).map(decodeURIComponent),
          tools: getParamValue(tools).map(decodeURIComponent),
          content: content,
          works_on: getParamValue(works_on).map(decodeURIComponent),
          tags: getParamValue(tags).map(decodeURIComponent),
        };

        return test;
      },
    }),
    stateMapping: {
      stateToRoute(uiState) {
        let content = "all";
        const indexUiState = uiState[indexName] || {};

        if (indexUiState.configure) {
          content = Object.entries(sources).find(
            ([, value]) => value.filters === indexUiState.configure.filters
          )[0];
        }

        return {
          query: indexUiState.query,
          page: indexUiState.page,
          products:
            indexUiState.refinementList && indexUiState.refinementList.products,
          tools:
            indexUiState.refinementList && indexUiState.refinementList.tools,
          works_on:
            indexUiState.refinementList && indexUiState.refinementList.works_on,
          tags: indexUiState.refinementList && indexUiState.refinementList.tags,
          content,
        };
      },

      routeToState(routeState) {
        let filters = "";
        if (routeState.content !== undefined) {
          filters = sources[routeState.content].filters;
        }
        return {
          [indexName]: {
            configure: { filters },
            query: routeState.query,
            page: routeState.page,
            refinementList: {
              products: routeState.products,
              tools: routeState.tools,
              works_on: routeState.works_on,
              tags: routeState.tags,
            },
          },
        };
      },
    },
  };
}
