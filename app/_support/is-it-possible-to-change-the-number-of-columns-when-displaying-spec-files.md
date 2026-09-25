---
title: Changing the number of columns used to display spec files in the Developer Portal
content_type: support
description: How to change the number of columns used to display spec files in the Developer Portal by editing the `.catalog-list` styles in `site.css`.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Is it possible to change the number of columns when displaying spec files?
  a: |
    The number of spec file columns shown in the Developer Portal catalog is controlled by the `.catalog-list` and `.catalog-item` widths defined in `site.css` (`/themes/base/assets/styles/site.css`). Inside the `@media(min-width: 749px)` block, change the `.catalog-item` `width` percentage (`50%` gives two columns) to `33%` for three columns or `25%` for four columns. You may also need to increase the `min-width` of `.catalog-list` to fit the extra columns.
related_resources: []
---

## Problem

By default, the Developer Portal displays spec files using two columns, leaving unused space on the sides that could be used to display more columns.

## Cause

The display of the spec files is controlled via the `site.css` file.

## Solution

Start the Editor in Kong Manager and open the `/themes/base/assets/styles/site.css` file.

In this CSS file, find the "Component - Catalog List" section and under this is a definition as below:

```css

/*****************************************
 * Component - Catalog List
 *****************************************/

.catalog-list {
  text-align: left;
}

.catalog-list .catalog-item {
  width: 100%;
  min-height: 156px;
  margin: 1rem 0;
}

.catalog-list .catalog-item .catalog-desc {
  display: block;
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
}

@media(min-width: 749px) {
  .catalog-list {
    display: flex;
    flex-wrap: wrap;
  }
  .catalog-list .catalog-item {
    width: calc(50% - 2rem);
    margin: 0 1rem 2rem;
  }
}
```

Within the `@media` style, the `50%` value determines that the catalog will be two rows. Changing this to `33%` or `25%` will change the number of columns to be 3 or 4 respectively.

Note, you may need to increase the width of the spec container by setting the `min-width` value of the `.catalog-list` style. For example, to show 4 columns use a css style like this:

```css

/*****************************************
 * Component - Catalog List
 *****************************************/

.catalog-list {
  text-align: left;
  min-width: 1000px;
}

.catalog-list .catalog-item {
  width: 100%;
  min-height: 156px;
  margin: 1rem 0;
}

.catalog-list .catalog-item .catalog-desc {
  display: block;
  display: -webkit-box;
  overflow: hidden;
  -webkit-line-clamp: 1;
  -webkit-box-orient: vertical;
}

@media(min-width: 749px) {
  .catalog-list {
    display: flex;
    flex-wrap: wrap;
  }
  .catalog-list .catalog-item {
    width: calc(25% - 2rem);
    margin: 0 1rem 2rem;
  }
}
```
