import fs from "fs/promises";
import { existsSync, writeFileSync } from "fs";
import fg from "fast-glob";
import matter from "gray-matter";
import path from "path";
import yaml from "js-yaml";
import semver from "semver";

const PLUGIN_DOCS = "improved plugin documentation";

const file = await fs.readFile("./config/mappings.yaml", "utf8");
const mappings = yaml.load(file);

function findPluginMapping(plugin) {
  return Object.entries(mappings)
    .filter(([, names]) => names.includes(plugin))
    .map(([slug]) => slug);
}

function slugify(str) {
  return str.toLowerCase().trim().replace(/\s+/g, "-");
}

function pluginSlugsFromImprovedDocumentation(message) {
  const matches = [...message.matchAll(/\[(.+?)\]/g)];
  return matches.map((match) => match[1]);
}

function extractPluginIdentifiersInBold(message) {
  const title = message.split(":")[0];
  const matches = [...title.matchAll(/\*\*(.+?)\*\*/g)];
  return matches.map((match) => match[1]);
}

async function findPluginByIdentifier(plugins, identifier) {
  const slugsFromMappings = findPluginMapping(identifier);

  return plugins.find(
    (p) =>
      slugify(p.name.toLowerCase()) === slugify(identifier.toLowerCase()) ||
      p.slug === slugify(identifier.toLowerCase()) ||
      (slugsFromMappings.length > 0 &&
        slugsFromMappings.some((slug) => p.slug === slug))
  );
}

async function extractPluginIdentifiersInSnippets(message, plugins) {
  const title = message.split(":")[1];
  const pluginIdentifiers = [];
  if (title) {
    const matches = [...title.matchAll(/`(.+?)`/g)];
    const pluginCandidates = matches.map((match) => match[1]);
    for (const candidate of pluginCandidates) {
      const found = await findPluginByIdentifier(plugins, candidate);
      if (found) {
        pluginIdentifiers.push(found.slug);
      }
    }
  }

  return pluginIdentifiers;
}

async function getPluginIdentifiers(message, plugins) {
  let pluginIdentifiers = extractPluginIdentifiersInBold(message);
  if (pluginIdentifiers.length === 0) {
    const identifiersInSnippets = await extractPluginIdentifiersInSnippets(
      message,
      plugins
    );
    pluginIdentifiers.push(...identifiersInSnippets);
  }

  if (pluginIdentifiers.length !== 0) {
    if (pluginIdentifiers.some((i) => i.toLowerCase() === PLUGIN_DOCS)) {
      pluginIdentifiers.push(...pluginSlugsFromImprovedDocumentation(message));
      pluginIdentifiers = pluginIdentifiers.filter(
        (i) => i.toLowerCase() !== PLUGIN_DOCS
      );
    }
  }
  return Array.from(new Set(pluginIdentifiers));
}

async function generateChangelogData(plugins, pluginEntriesByVersion) {
  const changelogs = {};
  const noIdentifiers = {};
  const outliers = {};

  for (const [version, entries] of Object.entries(pluginEntriesByVersion)) {
    for (const entry of entries) {
      let pluginIdentifiers = await getPluginIdentifiers(
        entry.message,
        plugins
      );

      if (entry.plugins) {
        for (const slug of entry.plugins) {
          changelogs[slug] ||= {};
          changelogs[slug][version] ||= [];
          changelogs[slug][version].push(entry);
        }
        entry.message = entry.message.replace(
          /\*\*(?!Improved Plugin Documentation\*\*).*?\*\*:(\s|\n)?/,
          ""
        );
        delete entry.plugins;
      } else if (pluginIdentifiers.length === 0) {
        noIdentifiers[version] ||= [];
        noIdentifiers[version].push(entry);
      } else {
        for (const identifier of pluginIdentifiers) {
          const plugin = await findPluginByIdentifier(plugins, identifier);

          if (plugin) {
            entry.message = entry.message.replace(
              /\*\*(?!Improved Plugin Documentation\*\*).*?\*\*:(\s|\n)?/,
              ""
            );
            changelogs[plugin.slug] ||= {};
            changelogs[plugin.slug][version] ||= [];
            changelogs[plugin.slug][version].push(entry);
          } else {
            outliers[version] ||= [];
            outliers[version].push(entry);
          }
        }
      }
    }
  }
  // Outliers: messages that start with **Identifier** but they don't match any plugin name or slug
  console.log(`outliers: ${Object.values(outliers).flat().length}`);
  console.log(outliers);
  console.log(`noIdentifiers: ${Object.values(noIdentifiers).flat().length}`);
  console.log(noIdentifiers);

  return { outliers, noIdentifiers, changelogs };
}

async function kongPlugins() {
  const files = await fg("../../app/_kong_plugins/*/index.md");

  const plugins = [];

  for (const file of files) {
    const content = await fs.readFile(file, "utf-8");
    const { data: frontmatter } = matter(content);

    const slug = path.basename(path.dirname(file));
    const name = frontmatter.name;
    const minVersion = frontmatter.min_version?.gateway;

    if (name) {
      const plugin = { slug, name };
      if (minVersion) {
        plugin.min_version = minVersion;
      }
      plugins.push(plugin);
    }
  }
  return plugins;
}

async function pluginEntries() {
  const filePath = "../../app/_data/changelogs/gateway.json";
  const raw = await fs.readFile(filePath, "utf-8");
  const changelog = JSON.parse(raw);

  const plugins = {};

  for (const [version, products] of Object.entries(changelog)) {
    for (const [product, entries] of Object.entries(products)) {
      plugins[version] ||= [];
      plugins[version].push(...entries.filter((e) => e.scope === "Plugin"));
    }
  }
  return plugins;
}

function sortEntries(changelog) {
  return Object.fromEntries(
    Object.entries(changelog).sort((a, b) =>
      semver.rcompare(semver.coerce(a[0]), semver.coerce(b[0]))
    )
  );
}

async function writeChangelogs(plugins, changelogs) {
  for (const plugin of plugins) {
    const filePath = `../../app/_kong_plugins/${plugin.slug}/changelog.json`;

    let existingChangelog = {};
    if (existsSync(filePath)) {
      const raw = await fs.readFile(filePath, "utf-8");
      existingChangelog = JSON.parse(raw);
    }

    const newChangelog = changelogs[plugin.slug];
    if (!newChangelog) {
      continue;
    }

    const combined = {
      ...existingChangelog,
      ...newChangelog,
    };

    const sortedEntries = sortEntries(combined);
    writeFileSync(filePath, JSON.stringify(sortedEntries, null, 2), "utf8");
  }
}

(async function main() {
  const plugins = await kongPlugins();
  const pluginEntriesByVersion = await pluginEntries();

  const { outliers, noIdentifiers, changelogs } = await generateChangelogData(
    plugins,
    pluginEntriesByVersion
  );

  await writeChangelogs(plugins, changelogs);
})();
