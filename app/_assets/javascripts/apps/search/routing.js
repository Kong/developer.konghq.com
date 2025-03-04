import { history } from "instantsearch.js/es/lib/routers";

function getParamValue(param) {
  return Array.isArray(param) ? param : [param].filter(Boolean);
}

export function routingConfig(indexName) {
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
        if (routeState.content_type) {
          queryParameters.content_type =
            routeState.content_type.map(encodeURIComponent);
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
          tier,
          content_type = [],
          works_on = [],
          tags = [],
        } = qsModule.parse(location.search.slice(1));

        // `qs` does not return an array when there's a single value.
        return {
          query: decodeURIComponent(query),
          page,
          products: getParamValue(products).map(decodeURIComponent),
          tools: getParamValue(tools).map(decodeURIComponent),
          tier: getParamValue(tier).map(decodeURIComponent),
          content_type: getParamValue(content_type).map(decodeURIComponent),
          works_on: getParamValue(works_on).map(decodeURIComponent),
          tags: getParamValue(tags).map(decodeURIComponent),
        };
      },
    }),
    stateMapping: {
      stateToRoute(uiState) {
        const indexUiState = uiState[indexName] || {};

        return {
          query: indexUiState.query,
          page: indexUiState.page,
          products:
            indexUiState.refinementList && indexUiState.refinementList.products,
          tools:
            indexUiState.refinementList && indexUiState.refinementList.tools,
          tier: indexUiState.refinementList && indexUiState.refinementList.tier,
          content_type:
            indexUiState.refinementList &&
            indexUiState.refinementList.content_type,
          works_on:
            indexUiState.refinementList && indexUiState.refinementList.works_on,
          tags: indexUiState.refinementList && indexUiState.refinementList.tags,
        };
      },

      routeToState(routeState) {
        return {
          [indexName]: {
            query: routeState.query,
            page: routeState.page,
            refinementList: {
              products: routeState.products,
              tools: routeState.tools,
              tier: routeState.tier,
              content_type: routeState.content_type,
              works_on: routeState.works_on,
              tags: routeState.tags,
            },
          },
        };
      },
    },
  };
}
